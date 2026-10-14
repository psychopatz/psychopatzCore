#!/usr/bin/env python3
"""Import original generated radio concept PNGs from the chat bundle into Core.

Never downscale, requantize or overwrite an existing mismatching art source.
Use --commit --push only in a regular local git checkout with Git credentials.
"""
import argparse
import hashlib
import json
import os
import subprocess
import tempfile
from pathlib import Path
from zipfile import ZipFile, BadZipFile

REPO = Path(__file__).resolve().parents[2]
CATALOG = REPO / "art_source/radio/device_concepts/catalog.json"

def cmd(*argv, check=True):
    return subprocess.run(list(argv), cwd=REPO, text=True, capture_output=True, check=check)

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("bundle", type=Path, help="Original concept-sheet .zip from the conversation")
    p.add_argument("--commit", action="store_true", help="Stage and commit imported source sheets only")
    p.add_argument("--push", action="store_true", help="Fast-forward-safe git push; requires --commit")
    a = p.parse_args()
    if a.push and not a.commit:
        p.error("--push requires --commit")
    rows = json.loads(CATALOG.read_text(encoding="utf-8"))["assets"]
    assert len(rows) == 11
    if not (REPO / ".git").exists():
        raise SystemExit("Run from a local psychopatzCore Git checkout")
    if a.commit:
        staged = cmd("git", "diff", "--cached", "--name-only").stdout.strip()
        if staged:
            raise SystemExit("Index is not empty; commit or unstage unrelated work first. No files changed.")
    with ZipFile(a.bundle) as z:
        expected = {row["target_path"] for row in rows}
        archive = {n for n in z.namelist() if n.startswith("art_source/radio/device_concepts/")}
        if archive != expected:
            raise SystemExit("Bundle contains missing or unknown image paths; stopping")
        validated = []
        for row in rows:
            rel = row["target_path"]
            if Path(rel).is_absolute() or ".." in Path(rel).parts:
                raise SystemExit(f"Unsafe target path: {rel}")
            info = z.getinfo(rel)
            if info.file_size > 12_000_000:
                raise SystemExit(f"Asset exceeds source size cap: {rel}")
            data = z.read(rel)
            if hashlib.sha256(data).hexdigest() != row["sha256"]:
                raise SystemExit(f"SHA-256 mismatch: {rel}")
            if data[:8] != b"\x89PNG\r\n\x1a\n":
                raise SystemExit(f"Not a PNG: {rel}")
            if int.from_bytes(data[16:20],"big") != 1254 or int.from_bytes(data[20:24],"big") != 1254:
                raise SystemExit(f"Unexpected dimensions: {rel}")
            if data[25] not in (4,6):   # gray+alpha or RGBA; current sources are RGBA
                raise SystemExit(f"Missing explicit alpha channel: {rel}")
            target = REPO / rel
            if target.exists() and target.read_bytes() != data:
                raise SystemExit(f"Existing different art would be overwritten: {target}")
            validated.append((rel,target,data))
    created = []
    for rel,target,data in validated:
        if target.exists():
            print("UNCHANGED", rel)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        fd,tmp=tempfile.mkstemp(prefix=".radio_import_",suffix=".png",dir=target.parent)
        try:
            with os.fdopen(fd,"wb") as fh:fh.write(data)
            os.replace(tmp,target)
        finally:
            if os.path.exists(tmp):os.unlink(tmp)
        created.append(rel)
        print("IMPORTED",rel)
    if a.commit and created:
        cmd("git","add","--",*created)
        r=cmd("git","commit","-m","art(radio): add verified generated device-family concept sources")
        print(r.stdout)
    if a.push and created:
        r=cmd("git","push")
        print(r.stdout or r.stderr)
    print(f"Validated {len(validated)} original full-resolution files, added {len(created)}.")
    if not a.commit:
        print("To publish: git add art_source/radio/device_concepts && git commit -m 'art(radio): add labeled concept sources' && git push")
if __name__ == "__main__":
    main()
