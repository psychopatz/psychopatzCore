#!/usr/bin/env python3
"""Ingest saved local Semantic Telemetry JSON/JSONL reports into an intent dataset JSON.
Deduplicates labeled sentences and appends them to matching intent entries.
"""
import argparse
import json
from pathlib import Path


def load_reports(path: Path):
    text = path.read_text(encoding="utf-8").strip()
    if not text:
        return []
    if text.startswith("["):
        return json.loads(text)
    if text.startswith("{"):
        try:
            obj = json.loads(text)
            return [obj]
        except json.JSONDecodeError:
            pass
    out = []
    for line in text.splitlines():
        line = line.strip()
        if line:
            out.append(json.loads(line))
    return out


def main():
    ap = argparse.ArgumentParser(description="Ingest semantic telemetry reports into intent dataset.")
    ap.add_argument("--telemetry", required=True, help="Path to telemetry .json or .jsonl file")
    ap.add_argument("--dataset", required=True, help="Path to intent dataset JSON file")
    args = ap.parse_args()

    t_path = Path(args.telemetry)
    d_path = Path(args.dataset)
    dataset = json.loads(d_path.read_text(encoding="utf-8"))
    by_id = {str(e["id"]).upper(): e for e in dataset.get("intents", [])}
    by_action = {str(e.get("action") or "").upper(): e for e in dataset.get("intents", []) if e.get("action")}

    added = 0
    for rep in load_reports(t_path):
        sentence = str(rep.get("sentence") or rep.get("rawText") or rep.get("text") or "").strip()
        label = str(rep.get("selectedSemantic") or rep.get("expectedAction") or rep.get("intentId") or "").strip().upper()
        if not sentence or not label:
            continue
        target = by_id.get(label) or by_action.get(label)
        if not target:
            continue
        existing = {s.lower().strip() for s in target.get("examples", [])}
        if sentence.lower() not in existing:
            target.setdefault("examples", []).append(sentence)
            added += 1

    if added > 0:
        d_path.write_text(json.dumps(dataset, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[ingest_telemetry] Added {added} new example(s) to {d_path}")


if __name__ == "__main__":
    main()
