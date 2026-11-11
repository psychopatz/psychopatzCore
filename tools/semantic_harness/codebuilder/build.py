#!/usr/bin/env python3
"""Build owner-routed semantic Conversation and lexical artifacts."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

if __package__ in {None, ""}:
    from tools.semantic_harness.codebuilder.lexicon_compiler import (  # noqa: E402
        CompileError,
        DEFAULT_ALLOWLIST,
        compile_wordnet,
        load_allowlist,
        render_lua_shards,
    )
    from tools.semantic_harness.codebuilder.translation_support import (
        normalize_language,
        pretty_json,
    )
    from tools.semantic_harness.codebuilder.generation_ownership import (
        CORE_OWNER,
        DT_COMMON_OWNER,
        HOOMANS_OWNER,
        generated_conversation_root,
        module_owner,
        module_target,
        normalize_owner,
        package_descriptor,
        resolve_core_repository,
        translation_root,
    )
    from tools.semantic_harness.codebuilder.conversation_compiler import (
        CONVERSATION_MANIFEST_RELATIVE,
        CONVERSATION_UI_RUNTIME_RELATIVE,
        compile_conversation_sources,
        conversation_context_health,
        conversation_translation_bundles_by_owner,
        render_conversation_registry,
        render_conversation_manifest_lua,
        render_conversation_runtime_plan,
        render_conversation_ui_module,
    )
else:
    from .lexicon_compiler import (  # noqa: E402
        CompileError,
        DEFAULT_ALLOWLIST,
        compile_wordnet,
        load_allowlist,
        render_lua_shards,
    )
    from tools.semantic_harness.codebuilder.translation_support import normalize_language, pretty_json
    from .generation_ownership import (
        CORE_OWNER,
        DT_COMMON_OWNER,
        HOOMANS_OWNER,
        generated_conversation_root,
        module_owner,
        module_target,
        normalize_owner,
        package_descriptor,
        resolve_core_repository,
        translation_root,
    )
    from .conversation_compiler import (
        CONVERSATION_MANIFEST_RELATIVE,
        CONVERSATION_UI_RUNTIME_RELATIVE,
        compile_conversation_sources,
        conversation_context_health,
        conversation_translation_bundles_by_owner,
        render_conversation_registry,
        render_conversation_manifest_lua,
        render_conversation_runtime_plan,
        render_conversation_ui_module,
    )


def default_lexicon_output(core_repository: Path | None = None) -> Path:
    core = resolve_core_repository(ROOT, explicit=core_repository)
    return (
        core
        / "Contents/mods/PsychopatzCore/common/media/lua/shared/"
        / "PsychopatzCore/Semantics/Generated/Lexicon/Catalog.lua"
    )


DEFAULT_CORE_REPOSITORY = resolve_core_repository(ROOT)
DEFAULT_OUTPUT = default_lexicon_output()
CONVERSATION_SOURCE_ROOT = (
    ROOT / "tools" / "semantic_harness" / "codebuilder" / "sources"
    / "conversation"
)
DEFAULT_CONVERSATION_MANIFEST = CONVERSATION_SOURCE_ROOT / "manifest.json"


# Suggestions.json remains a source for contextual UI keys merged into the
# generated Conversation/UI.json bundle. Runtime loads only the generated bundle.
_CONVERSATION_SOURCE_ONLY_TRANSLATIONS = frozenset({
    "Conversation/Semantic/Suggestions.json",
})

def write_lexicon_output(output: Path, compiled) -> list[Path]:
    """Write the stable lexicon hub and bounded generated data shards."""
    output.parent.mkdir(parents=True, exist_ok=True)
    shared_root = _shared_lua_root(output)
    module_prefix = output.relative_to(shared_root).with_suffix("").as_posix()
    rendered = render_lua_shards(compiled, module_prefix)
    # Keep the catalog's hub sibling directory clean while preserving any
    # future generated catalogs beside it.
    _clean_generated_tree(output.with_suffix(""))
    return _write_modules(shared_root, rendered)


def _conversation_locale_directories(translation_root: Path) -> list[tuple[str, Path]]:
    """Discover locale directories from actual Conversation translation trees."""
    discovered: list[tuple[str, Path]] = []
    if not translation_root.is_dir():
        return discovered
    for directory in translation_root.iterdir():
        if not directory.is_dir() or not (directory / "Conversation").is_dir():
            continue
        try:
            language = normalize_language(directory.name, "translation directory")
        except CompileError:
            continue
        discovered.append((language, directory))
    return sorted(discovered, key=lambda item: item[0])


def _write_conversation_translation_manifest(
    translation_root: Path,
    manifest_relative: Path = Path("manifests/Conversation.json"),
    bundles: dict[str, dict[str, dict[str, str]]] | None = None,
) -> Path:
    """Generate a package manifest from canonical bundles or locale files."""
    if bundles is None:
        languages: dict[str, list[str]] = {}
        for language, directory in _conversation_locale_directories(translation_root):
            entries: list[str] = []
            for path in sorted((directory / "Conversation").rglob("*.json")):
                relative_from_language = path.relative_to(directory).as_posix()
                if relative_from_language in _CONVERSATION_SOURCE_ONLY_TRANSLATIONS:
                    continue
                entries.append(path.relative_to(translation_root).as_posix())
            if entries:
                languages[language] = entries
    else:
        languages = {
            language: [
                f"{language}/Conversation/{domain}.json"
                for domain in sorted(domains)
            ]
            for language, domains in sorted(bundles.items())
            if domains
        }
    manifest_path = translation_root / manifest_relative
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        pretty_json({"version": 1, "languages": languages}),
        encoding="utf-8",
        newline="\n",
    )
    return manifest_path

def _shared_lua_root(path: Path) -> Path:
    parts = path.parts
    for index in range(len(parts) - 2):
        if parts[index:index + 3] == ("media", "lua", "shared"):
            return Path(*parts[:index + 3])
    raise ValueError("generated output must be under a media/lua/shared tree")


def _clean_generated_tree(root: Path) -> None:
    """Remove only Lua artifacts owned by one generated catalog directory."""
    if root.exists():
        for path in sorted(root.rglob("*.lua"), reverse=True):
            path.unlink()
        for directory in sorted(
            (path for path in root.rglob("*") if path.is_dir()),
            key=lambda path: len(path.parts),
            reverse=True,
        ):
            try:
                directory.rmdir()
            except OSError:
                pass
    root.mkdir(parents=True, exist_ok=True)


def _write_modules(shared_root: Path, rendered: list[tuple[str, str]]) -> list[Path]:
    paths: list[Path] = []
    for module, source in rendered:
        path = shared_root / (module + ".lua")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(source, encoding="utf-8", newline="\n")
        paths.append(path)
    return paths


def _write_routed_modules(
    project_repository: Path,
    core_repository: Path | None,
    dynamic_trading_repository: Path | None,
    rendered: list[tuple[str, str]],
) -> list[Path]:
    """Write each generated module into its owning package repository."""
    paths: list[Path] = []
    for module, source in rendered:
        _owner_repository, path = module_target(
            project_repository,
            module,
            core_repository=core_repository,
            dynamic_trading_repository=dynamic_trading_repository,
            runtime_root=project_repository,
        )
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(source, encoding="utf-8", newline="\n")
        paths.append(path)
    return paths


def write_conversation_output(
    repository: Path,
    model: dict | None = None,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
) -> list[Path]:
    """Write the manifest-backed Conversation runtime and audit artifacts."""
    repository = repository.expanduser().resolve()
    core_repository = resolve_core_repository(
        repository,
        explicit=core_repository,
    )
    package_repositories = {
        HOOMANS_OWNER: repository,
        CORE_OWNER: core_repository,
    }
    if dynamic_trading_repository is not None:
        package_repositories[DT_COMMON_OWNER] = (
            dynamic_trading_repository.expanduser().resolve()
        )
    model = model or compile_conversation_sources(
        repository,
        package_repositories=package_repositories,
    )
    manifest = model.get("manifest") if isinstance(model, dict) else None
    registry_owner = normalize_owner(
        manifest.get("registryOwner") if isinstance(manifest, dict) else None,
    )
    registry_root = generated_conversation_root(
        repository,
        registry_owner,
        core_repository=core_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        runtime_root=repository,
    )

    # Validate the complete plan before deleting or writing any generated
    # artifact. Hard context-health violations are compiler errors, not
    # advisory cleanup work after generation.
    rendered, reports = render_conversation_runtime_plan(model)
    health = conversation_context_health(model, reports)
    if health.get("status") != "pass":
        errors = health.get("errors") or []
        summary = "; ".join(
            str(item.get("type") or "context_health_error")
            + ":"
            + str(item.get("path") or item.get("module") or "")
            for item in errors[:8]
        )
        raise CompileError(
            "Conversation context-health hard violations"
            + (": " + summary if summary else "")
        )

    enabled_owners = {HOOMANS_OWNER, CORE_OWNER}
    if dynamic_trading_repository is not None:
        enabled_owners.add(DT_COMMON_OWNER)
    writable_rendered = [
        (module, source)
        for module, source in rendered
        if module_owner(module) in enabled_owners
    ]
    owners_to_clean = {registry_owner} & enabled_owners
    for module, _source in writable_rendered:
        owners_to_clean.add(module_owner(module))
    for owner in sorted(owners_to_clean):
        _clean_generated_tree(
            generated_conversation_root(
                repository,
                owner,
                core_repository=core_repository,
                dynamic_trading_repository=dynamic_trading_repository,
                runtime_root=repository,
            )
        )

    registry_root.mkdir(parents=True, exist_ok=True)
    primary_registry_owners = None
    if registry_owner == HOOMANS_OWNER:
        primary_registry_owners = (CORE_OWNER, HOOMANS_OWNER)
    else:
        primary_registry_owners = (registry_owner,)
    paths = _write_routed_modules(
        repository,
        core_repository,
        dynamic_trading_repository,
        writable_rendered,
    )
    registry_path = registry_root / "Registry.lua"
    registry_path.write_text(
        render_conversation_registry(
            model,
            reports,
            include_owners=primary_registry_owners,
        ),
        encoding="utf-8",
        newline="\n",
    )
    paths.append(registry_path)

    # Core receives a standalone foundation registry containing only
    # Core-owned records.  The adopter registry above remains intentionally
    # combined for Project Hoomans compatibility, but Core and standalone
    # adopters must never need to import that Hoomans-owned registry.
    if core_repository is not None:
        core_registry_root = generated_conversation_root(
            repository,
            CORE_OWNER,
            core_repository=core_repository,
            dynamic_trading_repository=dynamic_trading_repository,
            runtime_root=repository,
        )
        core_registry_path = core_registry_root / "FoundationRegistry.lua"
        core_registry_path.write_text(
            render_conversation_registry(
                model,
                reports,
                registry_owner=CORE_OWNER,
                include_owner=CORE_OWNER,
                registry_module=(
                    "PsychopatzCore/Semantics/Generated/Conversation/"
                    "FoundationRegistry"
                ),
            ),
            encoding="utf-8",
            newline="\n",
        )
        paths.append(core_registry_path)

    if (
        dynamic_trading_repository is not None
        and registry_owner != DT_COMMON_OWNER
    ):
        dt_registry_root = generated_conversation_root(
            repository,
            DT_COMMON_OWNER,
            core_repository=core_repository,
            dynamic_trading_repository=dynamic_trading_repository,
            runtime_root=repository,
        )
        dt_registry_root.mkdir(parents=True, exist_ok=True)
        dt_registry_path = dt_registry_root / "Registry.lua"
        dt_registry_path.write_text(
            render_conversation_registry(
                model,
                reports,
                registry_owner=DT_COMMON_OWNER,
                include_owner=DT_COMMON_OWNER,
                registry_module=(
                    "DTCommon/Semantics/Generated/Conversation/Registry"
                ),
            ),
            encoding="utf-8",
            newline="\n",
        )
        paths.append(dt_registry_path)
    manifest_path = registry_root / "Manifest.lua"
    primary_report_owners = set(primary_registry_owners or (registry_owner,))
    manifest_reports = [
        report
        for report in reports
        if report.get("owner") in primary_report_owners
    ]
    manifest_path.write_text(
        render_conversation_manifest_lua(model, manifest_reports),
        encoding="utf-8",
        newline="\n",
    )
    paths.append(manifest_path)

    ui_runtime_path = repository / CONVERSATION_UI_RUNTIME_RELATIVE
    ui_runtime_path.parent.mkdir(parents=True, exist_ok=True)
    ui_runtime_path.write_text(
        render_conversation_ui_module(model),
        encoding="utf-8",
        newline="\n",
    )
    paths.append(ui_runtime_path)

    bundles_by_owner = conversation_translation_bundles_by_owner(
        model,
        package_repositories=package_repositories,
    )
    for owner, bundles in sorted(bundles_by_owner.items()):
        if owner not in enabled_owners:
            continue
        package_translation_root = translation_root(
            repository,
            owner,
            core_repository=core_repository,
            dynamic_trading_repository=dynamic_trading_repository,
            runtime_root=repository,
        )
        for language in sorted(bundles):
            for domain, values in sorted(bundles[language].items()):
                relative = f"{language}/Conversation/{domain}.json"
                path = package_translation_root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(
                    pretty_json(values),
                    encoding="utf-8",
                    newline="\n",
                )
                paths.append(path)
        paths.append(
            _write_conversation_translation_manifest(
                package_translation_root,
                package_descriptor(owner).translation_manifest_relative,
            )
        )

    return paths


def main(arguments: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--wordnet-home",
        type=Path,
        default=None,
        help="extracted Princeton WordNet 3.0 package root (contains LICENSE and dict/)",
    )
    parser.add_argument(
        "--allowlist",
        type=Path,
        default=DEFAULT_ALLOWLIST,
        help="reviewed WordNet synset-to-Hoomans concept mapping",
    )
    parser.add_argument("--output", type=Path, default=None)
    parser.add_argument(
        "--conversation-manifest",
        type=Path,
        default=None,
        help="manifest-backed Conversation source tree to compile and generate",
    )
    parser.add_argument(
        "--conversation-output-root",
        type=Path,
        default=ROOT,
        help="Project Hoomans repository receiving adopter-owned Conversation artifacts",
    )
    parser.add_argument(
        "--core-repository",
        type=Path,
        default=None,
        help="PsychopatzCore repository receiving Core-owned generated artifacts",
    )
    parser.add_argument(
        "--dynamic-trading-repository",
        type=Path,
        default=None,
        help="DynamicTrading repository receiving DTCommon-owned generated artifacts",
    )
    options = parser.parse_args(arguments)

    if options.wordnet_home is None and options.conversation_manifest is None:
        parser.error("provide --wordnet-home and/or --conversation-manifest")

    compiled_lexicon = None
    compiled_conversation = None
    try:
        if options.wordnet_home is not None:
            compiled_lexicon = compile_wordnet(
                options.wordnet_home,
                load_allowlist(options.allowlist),
            )
        if options.conversation_manifest is not None:
            output_root = options.conversation_output_root.expanduser().resolve()
            manifest_path = options.conversation_manifest.expanduser().resolve()
            compiled_conversation = compile_conversation_sources(
                output_root,
                manifest_path=manifest_path,
                runtime_root=output_root,
                package_repositories={
                    HOOMANS_OWNER: output_root,
                    CORE_OWNER: resolve_core_repository(
                        output_root,
                        explicit=options.core_repository,
                        runtime_root=output_root,
                    ),
                    **(
                        {
                            DT_COMMON_OWNER: options.dynamic_trading_repository
                        }
                        if options.dynamic_trading_repository is not None
                        else {}
                    ),
                },
            )
    except CompileError as error:
        print(f"semantic compiler error: {error}", file=sys.stderr)
        return 2

    if compiled_lexicon is not None:
        output = (
            options.output.expanduser().resolve()
            if options.output is not None
            else default_lexicon_output(options.core_repository)
        )
        paths = write_lexicon_output(output, compiled_lexicon)
        alias_count = sum(
            len(aliases)
            for aliases in compiled_lexicon.aliases_by_concept.values()
        )
        form_count = len(compiled_lexicon.verb_forms_by_surface)
        print(
            f"wrote {output} plus {len(paths) - 1} data shards "
            f"({alias_count} aliases, {form_count} inflected forms "
            f"across {len(compiled_lexicon.aliases_by_concept)} concepts)"
        )

    if compiled_conversation is not None:
        output_root = options.conversation_output_root.expanduser().resolve()
        paths = write_conversation_output(
            output_root,
            compiled_conversation,
            core_repository=options.core_repository,
            dynamic_trading_repository=options.dynamic_trading_repository,
        )
        print(
            "wrote manifest-backed Conversation output and "
            f"{len(paths) - 1} generated files "
            f"({len(compiled_conversation['content']['phraseFamilies'])} "
            "phrase families, "
            f"{len(compiled_conversation['dialogue']['patterns'])} patterns, "
            f"{len(compiled_conversation['ui'])} UI definitions)"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
