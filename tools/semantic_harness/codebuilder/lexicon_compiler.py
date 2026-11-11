"""Compile reviewed WordNet lemmas and verb morphology into compact Lua data.

Only base lemmas become aliases for existing Hoomans concepts. Inflected
forms stay in a separate morphology index so tense/aspect information does not
turn statements into executable commands.
"""

from __future__ import annotations

import hashlib
import json
import math
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from tools.semantic_harness.codebuilder.errors import CompileError

CANONICAL_SOURCE_ROOT = (
    Path(__file__).resolve().parents[3]
    / "tools"
    / "semantic_harness"
    / "codebuilder"
    / "sources"
)
DEFAULT_ALLOWLIST = CANONICAL_SOURCE_ROOT / "wordnet_concepts.json"
REQUIRED_FILES = ("index.verb", "data.verb", "verb.exc")
VOWELS = frozenset("aeiou")
CONCEPT_ID = re.compile(r"^[A-Z][A-Z0-9_]*$")
WORDNET_OFFSET = re.compile(r"^\d{8}$")

@dataclass(frozen=True)
class Synset:
    offset: str
    pos: str
    lemmas: tuple[str, ...]


@dataclass(frozen=True)
class CompiledLexicon:
    aliases_by_concept: dict[str, tuple[str, ...]]
    verb_forms_by_surface: dict[str, tuple[str, str, str]]
    source_version: str
    source_url: str
    source_license: str
    source_hashes: dict[str, str]
    license_text: str


def load_allowlist(path: Path = DEFAULT_ALLOWLIST) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CompileError(f"cannot read allowlist {path}: {error}") from error
    if not isinstance(document, dict):
        raise CompileError("allowlist root must be an object")
    return document


def _read_index(path: Path) -> dict[str, tuple[str, ...]]:
    index: dict[str, tuple[str, ...]] = {}
    for line_number, line in enumerate(path.read_text(encoding="ascii").splitlines(), 1):
        if not line or line[0].isspace():
            continue
        fields = line.split()
        if len(fields) < 6 or fields[1] != "v":
            raise CompileError(f"invalid verb index row at {path}:{line_number}")
        try:
            synset_count = int(fields[2])
            pointer_count = int(fields[3])
        except ValueError as error:
            raise CompileError(f"invalid verb index counts at {path}:{line_number}") from error
        offset_start = 6 + pointer_count
        offsets = fields[offset_start:offset_start + synset_count]
        if len(offsets) != synset_count:
            raise CompileError(f"truncated verb index row at {path}:{line_number}")
        index[fields[0].lower()] = tuple(offsets)
    return index


def _read_synsets(path: Path) -> dict[str, Synset]:
    synsets: dict[str, Synset] = {}
    for line_number, line in enumerate(path.read_text(encoding="ascii").splitlines(), 1):
        if not line or line[0].isspace():
            continue
        entry = line.split("|", 1)[0].split()
        if len(entry) < 4:
            raise CompileError(f"invalid verb synset row at {path}:{line_number}")
        offset, _lex_file, pos = entry[:3]
        try:
            word_count = int(entry[3], 16)
        except ValueError as error:
            raise CompileError(f"invalid synset word count at {path}:{line_number}") from error
        word_end = 4 + word_count * 2
        if len(entry) < word_end:
            raise CompileError(f"truncated verb synset row at {path}:{line_number}")
        lemmas = tuple(entry[4 + index * 2].lower() for index in range(word_count))
        if offset in synsets:
            raise CompileError(f"duplicate WordNet synset offset {offset}")
        synsets[offset] = Synset(offset=offset, pos=pos, lemmas=lemmas)
    return synsets


def _read_exceptions(path: Path) -> dict[str, tuple[str, ...]]:
    forms_by_lemma: dict[str, set[str]] = {}
    for line_number, line in enumerate(path.read_text(encoding="ascii").splitlines(), 1):
        fields = line.split()
        if not fields:
            continue
        if len(fields) < 2:
            raise CompileError(f"invalid verb exception row at {path}:{line_number}")
        surface = fields[0].lower()
        for lemma in fields[1:]:
            forms_by_lemma.setdefault(lemma.lower(), set()).add(surface)
    return {lemma: tuple(sorted(forms)) for lemma, forms in forms_by_lemma.items()}


def _is_consonant_y(lemma: str) -> bool:
    return (len(lemma) > 1 and lemma.endswith("y")
            and lemma[-2] not in VOWELS)


def _is_cvc(lemma: str) -> bool:
    """Return whether the last letters support a bounded CVC doubling rule."""
    return (len(lemma) >= 3
            and lemma[-3] not in VOWELS
            and lemma[-2] in VOWELS
            and lemma[-1] not in VOWELS
            and lemma[-1] not in "wxy")


def _form_kind(surface: str) -> str:
    if surface.endswith("ing"):
        return "PROGRESSIVE"
    if surface.endswith("s"):
        return "THIRD_PERSON"
    return "PAST"


def _regular_verb_forms(lemma: str, *, allow_past: bool) -> dict[str, str]:
    """Generate common inflections as morphology, never as action aliases."""
    forms: dict[str, str] = {}
    if _is_consonant_y(lemma):
        forms[lemma[:-1] + "ies"] = "THIRD_PERSON"
    elif lemma.endswith(("s", "x", "z", "ch", "sh", "o")):
        forms[lemma + "es"] = "THIRD_PERSON"
    else:
        forms[lemma + "s"] = "THIRD_PERSON"

    if allow_past:
        if lemma.endswith("e"):
            forms[lemma + "d"] = "PAST"
        elif _is_consonant_y(lemma):
            forms[lemma[:-1] + "ied"] = "PAST"
        elif _is_cvc(lemma):
            forms[lemma + lemma[-1] + "ed"] = "PAST"
        else:
            forms[lemma + "ed"] = "PAST"

    if lemma.endswith("ie"):
        forms[lemma[:-2] + "ying"] = "PROGRESSIVE"
    elif lemma.endswith("e") and not lemma.endswith("ee"):
        forms[lemma[:-1] + "ing"] = "PROGRESSIVE"
    elif _is_cvc(lemma):
        forms[lemma + lemma[-1] + "ing"] = "PROGRESSIVE"
    else:
        forms[lemma + "ing"] = "PROGRESSIVE"
    return forms


def _lemma_surfaces(
    lemma: str,
    exception_forms: dict[str, tuple[str, ...]],
) -> tuple[str, dict[str, str]]:
    """Return a normalized lemma and constrained forms of its verb head.

    WordNet's exception lists provide irregular/doubled forms. The regular
    rules apply only to the first token of a selected verb lemma. The returned
    forms are tagged separately, so ``pick up`` may normalize to ``pick up``
    while ``picked up`` retains its past-tense tag.
    """
    pieces = lemma.split("_")
    head = pieces[0]
    tail = " ".join(pieces[1:])
    irregular = set(exception_forms.get(head, ()))
    forms = _regular_verb_forms(head, allow_past=not irregular)
    for surface in irregular:
        forms.setdefault(surface, _form_kind(surface))
    if tail:
        forms = {f"{form} {tail}": kind for form, kind in forms.items()}
    return " ".join(pieces), forms


def compile_wordnet(
    wordnet_home: Path,
    allowlist: dict[str, Any] | None = None,
) -> CompiledLexicon:
    """Compile the configured WordNet 3.0 synsets into Hoomans aliases."""
    document = allowlist if allowlist is not None else load_allowlist()
    source = document.get("source")
    concepts = document.get("concepts")
    if not isinstance(source, dict) or not isinstance(concepts, dict) or not concepts:
        raise CompileError("allowlist requires source metadata and concept mappings")
    version = str(source.get("version", ""))
    if version != "3.0":
        raise CompileError(f"unsupported WordNet version {version!r}; expected 3.0")

    license_path = wordnet_home / "LICENSE"
    try:
        license_text = license_path.read_text(encoding="utf-8")
    except OSError as error:
        raise CompileError(f"WordNet LICENSE not found under {wordnet_home}") from error
    if "WordNet Release 3.0" not in license_text:
        raise CompileError("WordNet LICENSE does not identify release 3.0")

    dictionary = wordnet_home / "dict"
    paths = {name: dictionary / name for name in REQUIRED_FILES}
    missing = [str(path) for path in paths.values() if not path.is_file()]
    if missing:
        raise CompileError("WordNet dictionary is missing: " + ", ".join(missing))

    source_hashes = {
        name: hashlib.sha256(path.read_bytes()).hexdigest()
        for name, path in paths.items()
    }
    source_hashes["LICENSE"] = hashlib.sha256(license_path.read_bytes()).hexdigest()
    expected_hashes = source.get("expected_sha256")
    if not isinstance(expected_hashes, dict):
        raise CompileError("allowlist must pin the WordNet 3.0 source file hashes")
    for name in (*REQUIRED_FILES, "LICENSE"):
        expected = expected_hashes.get(name)
        if not isinstance(expected, str) or source_hashes[name] != expected.lower():
            raise CompileError(f"WordNet source hash mismatch for {name}")
    verb_index = _read_index(paths["index.verb"])
    synsets = _read_synsets(paths["data.verb"])
    exception_forms = _read_exceptions(paths["verb.exc"])

    excluded_by_concept = document.get("excluded_forms", {})
    if not isinstance(excluded_by_concept, dict):
        raise CompileError("excluded_forms must be an object")

    aliases_by_concept: dict[str, set[str]] = {}
    verb_forms_by_surface: dict[str, tuple[str, str, str]] = {}
    surface_owners: dict[str, str] = {}
    for concept_id in sorted(concepts):
        if not isinstance(concept_id, str) or not CONCEPT_ID.fullmatch(concept_id):
            raise CompileError(f"invalid Hoomans concept id: {concept_id!r}")
        definition = concepts[concept_id]
        mappings = definition.get("synsets") if isinstance(definition, dict) else None
        if not isinstance(mappings, list) or not mappings:
            raise CompileError(f"{concept_id} must have at least one synset mapping")
        excluded = {
            phrase.strip().lower().replace("_", " ")
            for phrase in excluded_by_concept.get(concept_id, [])
            if isinstance(phrase, str)
        }
        aliases = aliases_by_concept.setdefault(concept_id, set())
        seen_mappings: set[tuple[str, str]] = set()
        for mapping in mappings:
            if not isinstance(mapping, dict):
                raise CompileError(f"invalid synset mapping for {concept_id}")
            pos = mapping.get("pos")
            offset = str(mapping.get("offset", ""))
            if pos != "v":
                raise CompileError(f"{concept_id} currently supports WordNet verbs only")
            if not WORDNET_OFFSET.fullmatch(offset):
                raise CompileError(f"invalid WordNet verb offset {offset!r}")
            if (pos, offset) in seen_mappings:
                raise CompileError(f"duplicate WordNet mapping {pos}:{offset} for {concept_id}")
            seen_mappings.add((pos, offset))
            synset = synsets.get(offset)
            if synset is None or synset.pos != "v":
                raise CompileError(f"WordNet verb synset {offset} was not found")
            lemmas = mapping.get("lemmas")
            if not isinstance(lemmas, list) or not lemmas:
                raise CompileError(f"{concept_id} synset {offset} needs explicit lemmas")
            for lemma in lemmas:
                if not isinstance(lemma, str) or not lemma:
                    raise CompileError(f"invalid selected lemma in {concept_id}:{offset}")
                lemma = lemma.lower()
                if lemma not in synset.lemmas:
                    raise CompileError(
                        f"{lemma!r} is not a member of WordNet verb synset {offset}")
                if offset not in verb_index.get(lemma, ()):
                    raise CompileError(
                        f"WordNet index does not map {lemma!r} to synset {offset}")
                head = lemma.split("_", 1)[0]
                if "_" in lemma and head not in verb_index:
                    raise CompileError(
                        f"WordNet verb head {head!r} for {lemma!r} is not indexed")
                lemma_surface, inflected_forms = _lemma_surfaces(
                    lemma, exception_forms)
                normalized_lemma = lemma_surface.lower().strip()
                if normalized_lemma and normalized_lemma not in excluded:
                    existing_owner = surface_owners.get(normalized_lemma)
                    if existing_owner and existing_owner != concept_id:
                        raise CompileError(
                            f"generated surface {normalized_lemma!r} maps to both "
                            f"{existing_owner} and {concept_id}")
                    surface_owners[normalized_lemma] = concept_id
                    aliases.add(normalized_lemma)

                for phrase, form_kind in inflected_forms.items():
                    normalized = phrase.lower().replace("_", " ").strip()
                    if not normalized or normalized in excluded:
                        continue
                    existing_owner = surface_owners.get(normalized)
                    if existing_owner and existing_owner != concept_id:
                        raise CompileError(
                            f"generated surface {normalized!r} maps to both "
                            f"{existing_owner} and {concept_id}")
                    surface_owners[normalized] = concept_id
                    form = (concept_id, normalized_lemma, form_kind)
                    existing_form = verb_forms_by_surface.get(normalized)
                    if existing_form is not None and existing_form != form:
                        raise CompileError(
                            f"generated verb form {normalized!r} maps to multiple lemmas")
                    verb_forms_by_surface[normalized] = form

    return CompiledLexicon(
        aliases_by_concept={
            concept: tuple(sorted(aliases))
            for concept, aliases in sorted(aliases_by_concept.items())
        },
        verb_forms_by_surface={
            surface: form
            for surface, form in sorted(verb_forms_by_surface.items())
        },
        source_version=version,
        source_url=str(source.get("url", "")),
        source_license=str(source.get("license", "")),
        source_hashes=source_hashes,
        license_text=license_text.rstrip(),
    )


def _lua_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def _render_provenance_header(compiled: CompiledLexicon) -> list[str]:
    """Render the shared provenance block for generated lexicon modules."""
    lines = [
        "-- Generated by tools/semantic_harness/codebuilder/build.py; do not edit by hand.",
        "-- Selected lexical data is derived from Princeton WordNet.",
        "-- WordNet source: " + compiled.source_url,
        "-- WordNet license: " + compiled.source_license,
        "-- Morphology: WordNet verb.exc plus allowlist-scoped regular forms, kept separate from action aliases.",
    ]
    for name, digest in sorted(compiled.source_hashes.items()):
        lines.append(f"-- SHA256 {name}: {digest}")
    lines.append("-- Begin WordNet 3.0 license notice.")
    lines.extend(
        "-- " + cleaned if cleaned else "--"
        for line in compiled.license_text.splitlines()
        for cleaned in (line.rstrip(),)
    )
    lines.append("-- End WordNet 3.0 license notice.")
    return lines


def _render_source_metadata(compiled: CompiledLexicon, indent: str) -> list[str]:
    return [
        f"{indent}source = {{",
        f"{indent}    name = \"Princeton WordNet\",",
        f"{indent}    version = {_lua_string(compiled.source_version)},",
        f"{indent}    license = {_lua_string(compiled.source_license)},",
        f"{indent}}},",
    ]


def _render_alias_entries(compiled: CompiledLexicon, indent: str) -> list[str]:
    lines: list[str] = []
    for concept_id, aliases in compiled.aliases_by_concept.items():
        lines.append(f"{indent}[{_lua_string(concept_id)}] = {{")
        for alias in aliases:
            lines.append(f"{indent}    {_lua_string(alias)},")
        lines.append(f"{indent}}},")
    return lines


def _render_verb_form_entries(
    forms_by_surface: dict[str, tuple[str, str, str]],
    indent: str,
) -> list[str]:
    lines: list[str] = []
    for surface, (concept_id, lemma, form_kind) in forms_by_surface.items():
        lines.extend([
            f"{indent}[{_lua_string(surface)}] = {{",
            f"{indent}    concept = {_lua_string(concept_id)},",
            f"{indent}    lemma = {_lua_string(lemma)},",
            f"{indent}    form = {_lua_string(form_kind)},",
            f"{indent}}},",
        ])
    return lines


def render_lua(compiled: CompiledLexicon) -> str:
    """Render the legacy single-file form for callers that need one module."""
    lines = _render_provenance_header(compiled)
    lines.extend(["", "return {"])
    lines.extend(_render_source_metadata(compiled, "    "))
    lines.append("    aliasesByConcept = {")
    lines.extend(_render_alias_entries(compiled, "        "))
    lines.append("    },")
    lines.append("    verbFormsBySurface = {")
    lines.extend(_render_verb_form_entries(
        compiled.verb_forms_by_surface,
        "        ",
    ))
    lines.extend(["    },", "}", ""])
    return "\n".join(lines)


def _render_data_shard_header(label: str) -> list[str]:
    return [
        "-- Generated by tools/semantic_harness/codebuilder/build.py; do not edit by hand.",
        f"-- Generated semantic lexicon {label} data shard.",
        "-- Provenance and the WordNet license notice are carried by the hub module.",
        "",
    ]


def render_lua_shards(
    compiled: CompiledLexicon,
    module_prefix: str,
) -> list[tuple[str, str]]:
    """Render a readable hub plus bounded lexicon data modules."""
    from tools.semantic_harness.codebuilder.catalog_naming import ModuleNameRegistry, module_path

    parent = module_prefix.rsplit("/", 1)[0]
    registry = ModuleNameRegistry()
    aliases_module = module_path(parent, ["Aliases"], "lexicon.aliases", registry)
    forms_module = module_path(parent, ["VerbForms"], "lexicon.verb_forms", registry)

    hub = _render_provenance_header(compiled)
    hub.extend([
        "",
        f'local aliasesByConcept = require "{aliases_module}"',
        f'local verbFormsBySurface = require "{forms_module}"',
        "",
        "return {",
    ])
    hub.extend(_render_source_metadata(compiled, "    "))
    hub.extend([
        "    aliasesByConcept = aliasesByConcept,",
        "    verbFormsBySurface = verbFormsBySurface,",
        "}",
        "",
    ])

    aliases = _render_data_shard_header("alias")
    aliases.extend(["return {"])
    aliases.extend(_render_alias_entries(compiled, "    "))
    aliases.extend(["}", ""])

    forms_by_concept: dict[str, dict[str, tuple[str, str, str]]] = {}
    for surface, form in compiled.verb_forms_by_surface.items():
        forms_by_concept.setdefault(form[0], {})[surface] = form

    form_modules = [
        (
            module_path(
                parent + "/VerbForms",
                [concept_id],
                "lexicon.verb_forms." + concept_id,
                registry,
            ),
            forms,
        )
        for concept_id, forms in sorted(forms_by_concept.items())
    ]
    forms = _render_data_shard_header("verb morphology aggregator")
    forms.extend([
        "local verbForms = {}",
        "local function merge(source)",
        "    for surface, form in pairs(source) do",
        "        verbForms[surface] = form",
        "    end",
        "end",
        "",
    ])
    for module, _forms in form_modules:
        forms.append(f'merge(require "{module}")')
    forms.extend(["", "return verbForms", ""])

    rendered = [
        (module_prefix, "\n".join(hub)),
        (aliases_module, "\n".join(aliases)),
        (forms_module, "\n".join(forms)),
    ]
    for module, concept_forms in form_modules:
        shard = _render_data_shard_header(
            "verb morphology for " + module.rsplit("/", 1)[-1]
        )
        shard.extend(["return {"])
        shard.extend(_render_verb_form_entries(concept_forms, "    "))
        shard.extend(["}", ""])
        rendered.append((module, "\n".join(shard)))
    return rendered
