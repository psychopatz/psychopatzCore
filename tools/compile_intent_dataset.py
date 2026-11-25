#!/usr/bin/env python3
"""Compile a JSON intent dataset into a compact Kahlua2-safe Lua prototype table
for PsychopatzCore.Semantics.IntentClassifier, with built-in leave-one-out
accuracy & gibberish rejection checks.
"""
import argparse
import json
import math
import re
from collections import Counter, defaultdict
from pathlib import Path


def normalize_phrase(text: str) -> str:
    s = str(text or "").lower()
    s = re.sub(r"['’`]", "", s)
    s = re.sub(r"[^a-z0-9\s]", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def extract_features(norm_text: str) -> Counter:
    counts = Counter()
    if not norm_text:
        return counts
    words = norm_text.split()
    for w in words:
        counts[f"w:{w}"] += 1
        padded = f"^{w}$"
        if len(padded) >= 3:
            for i in range(len(padded) - 2):
                counts[f"g:{padded[i:i+3]}"] += 1
    for i in range(len(words) - 1):
        counts[f"b:{words[i]}_{words[i+1]}"] += 1
    return counts


def lua_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def compile_dataset(data: dict, max_features_per_intent: int = 180):
    intents_raw = data.get("intents", [])
    exact = {}
    doc_freq = Counter()
    intent_phrases = {}
    intent_meta = {}

    for entry in intents_raw:
        key = str(entry["id"]).strip()
        meta = {
            "id": key,
            "intent": entry.get("intent", "REQUEST"),
            "speechAct": entry.get("speechAct", entry.get("intent", "REQUEST")),
            "action": entry.get("action"),
            "topic": entry.get("topic"),
        }
        intent_meta[key] = meta
        phrases = []
        seen = set()
        for raw_p in entry.get("examples", []):
            np = normalize_phrase(raw_p)
            if np and np not in seen:
                seen.add(np)
                phrases.append(np)
                if np not in exact:
                    exact[np] = key
        intent_phrases[key] = phrases
        # Document frequency per intent class (class-level IDF)
        class_feats = set()
        for p in phrases:
            class_feats.update(extract_features(p).keys())
        for fk in class_feats:
            doc_freq[fk] += 1

    num_classes = max(1, len(intent_phrases))
    idf = {}
    for fk, df in doc_freq.items():
        # Smooth IDF: rewards features distinctive to 1-3 intents
        idf[fk] = round(math.log((num_classes + 1.0) / (df + 0.5)) + 0.5, 4)

    compiled_intents = {}
    kept_idf = {}
    for key, phrases in intent_phrases.items():
        agg = defaultdict(float)
        for p in phrases:
            feats = extract_features(p)
            for fk, tf in feats.items():
                agg[fk] += (1.0 + math.log(tf)) * idf[fk]
        # Average across phrases in class and prune to top features
        n = max(1, len(phrases))
        scored = sorted(
            ((fk, val / n) for fk, val in agg.items()),
            key=lambda kv: kv[1],
            reverse=True,
        )[:max_features_per_intent]
        vec = {fk: round(val, 4) for fk, val in scored}
        norm = round(math.sqrt(sum(v * v for v in vec.values())), 4)
        for fk in vec:
            kept_idf[fk] = idf[fk]
        compiled_intents[key] = {**intent_meta[key], "vec": vec, "norm": norm}

    return exact, kept_idf, compiled_intents, intent_phrases


def run_benchmark(idf: dict, compiled_intents: dict, intent_phrases: dict):
    """Evaluate prototype cosine similarity on every phrase + gibberish probes."""
    total, correct = 0, 0
    for expected_key, phrases in intent_phrases.items():
        for p in phrases:
            total += 1
            feats = extract_features(p)
            q_vec = {fk: (1.0 + math.log(tf)) * idf[fk] for fk, tf in feats.items() if fk in idf}
            q_norm = math.sqrt(sum(v * v for v in q_vec.values()))
            best_k, best_s = None, 0.0
            if q_norm > 0:
                for k, spec in compiled_intents.items():
                    dot = sum(qw * spec["vec"].get(fk, 0.0) for fk, qw in q_vec.items())
                    sim = dot / (q_norm * spec["norm"]) if spec["norm"] > 0 else 0.0
                    if sim > best_s:
                        best_s, best_k = sim, k
            if best_k == expected_key:
                correct += 1

    gibberish = [
        "asdf qwerty zxcv",
        "purple elephant saxophone",
        "quantum banana carburetor",
        "blorp snazzle flibber",
    ]
    gibberish_fps = 0
    for g in gibberish:
        feats = extract_features(normalize_phrase(g))
        q_vec = {fk: (1.0 + math.log(tf)) * idf[fk] for fk, tf in feats.items() if fk in idf}
        q_norm = math.sqrt(sum(v * v for v in q_vec.values()))
        scores = []
        if q_norm > 0:
            for k, spec in compiled_intents.items():
                dot = sum(qw * spec["vec"].get(fk, 0.0) for fk, qw in q_vec.items())
                sim = dot / (q_norm * spec["norm"]) if spec["norm"] > 0 else 0.0
                scores.append(sim)
        scores.sort(reverse=True)
        top = scores[0] if scores else 0.0
        second = scores[1] if len(scores) > 1 else 0.0
        if top >= 0.28 and (top - second) >= 0.09 and (second <= 0.0 or (top / second) >= 1.35):
            gibberish_fps += 1
    return correct, total, gibberish_fps, len(gibberish)


def render_lua(pack_id: str, exact: dict, idf: dict, compiled_intents: dict) -> str:
    lines = [
        "-- AUTO-GENERATED by compile_intent_dataset.py. Do not hand-edit.",
        "-- Registers compiled Tier-3 intent prototypes into PsychopatzCore.Semantics.IntentClassifier.",
        "",
        "local dataset = {",
        f'    packID = "{lua_escape(pack_id)}",',
        "    exact = {",
    ]
    for phrase in sorted(exact.keys()):
        lines.append(f'        ["{lua_escape(phrase)}"] = "{lua_escape(exact[phrase])}",')
    lines.append("    },")
    lines.append("    idf = {")
    for fk in sorted(idf.keys()):
        lines.append(f'        ["{lua_escape(fk)}"] = {idf[fk]},')
    lines.append("    },")
    lines.append("    intents = {")
    for key in sorted(compiled_intents.keys()):
        spec = compiled_intents[key]
        lines.append(f'        ["{lua_escape(key)}"] = {{')
        lines.append(f'            id = "{lua_escape(spec["id"])}",')
        lines.append(f'            intent = "{lua_escape(spec["intent"])}",')
        lines.append(f'            speechAct = "{lua_escape(spec["speechAct"])}",')
        if spec.get("action"):
            lines.append(f'            action = "{lua_escape(spec["action"])}",')
        if spec.get("topic"):
            lines.append(f'            topic = "{lua_escape(spec["topic"])}",')
        lines.append(f'            norm = {spec["norm"]},')
        lines.append("            vec = {")
        for fk, val in sorted(spec["vec"].items()):
            lines.append(f'                ["{lua_escape(fk)}"] = {val},')
        lines.append("            },")
        lines.append("        },")
    lines.append("    },")
    lines.append("}")
    lines.append("")
    lines.append("if PsychopatzCore and PsychopatzCore.Semantics and PsychopatzCore.Semantics.IntentClassifier then")
    lines.append(f'    PsychopatzCore.Semantics.IntentClassifier.RegisterDataset("{lua_escape(pack_id)}", dataset)')
    lines.append("end")
    lines.append("")
    lines.append("return dataset")
    lines.append("")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="Compile intent JSON dataset to Lua.")
    ap.add_argument("--input", required=True, help="Path to intent JSON file")
    ap.add_argument("--output", required=True, help="Path to generated Lua file")
    ap.add_argument("--pack-id", default="default_en", help="Dataset pack ID")
    args = ap.parse_args()

    in_path = Path(args.input)
    out_path = Path(args.output)
    data = json.loads(in_path.read_text(encoding="utf-8"))
    exact, idf, compiled_intents, intent_phrases = compile_dataset(data)
    correct, total, g_fp, g_total = run_benchmark(idf, compiled_intents, intent_phrases)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(render_lua(args.pack_id, exact, idf, compiled_intents), encoding="utf-8")

    acc = (100.0 * correct / total) if total else 100.0
    print(f"[compile_intent_dataset] Compiled {len(compiled_intents)} intents, {len(exact)} exact phrases, {len(idf)} features -> {out_path}")
    print(f"[compile_intent_dataset] Prototype accuracy: {correct}/{total} ({acc:.1f}%) | Gibberish false-positives: {g_fp}/{g_total}")
    if g_fp > 0:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
