#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import re
from pathlib import Path
from typing import Optional

BASE_STYLE_PROMPT = (
    "High-quality 3D Pixar/Disney-style animation, vibrant colors, "
    "soft lighting, 8k resolution. "
    "Cinematic depth of field, rounded shapes, child-friendly, "
    "clean composition, no photorealism, no watermarks, no text artifacts."
)


def _slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def _hash_seed(value: str) -> int:
    digest = hashlib.sha1(value.encode("utf-8")).hexdigest()
    return int(digest[:8], 16)


def _short_hash(value: str) -> str:
    return hashlib.sha1(value.encode("utf-8")).hexdigest()[:10]


def parse_mapping(mapping_path: Path):
    mapping = {}
    if not mapping_path.exists():
        return mapping
    lines = mapping_path.read_text(encoding="utf-8").splitlines()
    for line in lines:
        if "|" not in line:
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 5:
            continue
        if cells[0].lower() in {"#", "---"}:
            continue
        if cells[1].lower().startswith("lesson folder"):
            continue
        lesson_folder = cells[1]
        lesson_id = cells[2].strip("`")
        prompt_file = cells[3]
        if lesson_id and lesson_id != "-":
            mapping[lesson_id] = {
                "folder": lesson_folder if lesson_folder != "-" else None,
                "prompt_file": prompt_file,
            }
    return mapping


def parse_prompt_table(prompt_path: Path):
    rows = []
    lines = prompt_path.read_text(encoding="utf-8").splitlines()
    for line in lines:
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 3:
            continue
        if "image file" in cells[0].lower() or cells[0].startswith(":"):
            continue
        image_file = cells[0].strip("`")
        prompt = cells[1]
        description = cells[2]
        if not image_file or image_file == "-":
            continue
        rows.append({
            "image_file": image_file,
            "prompt": prompt,
            "description": description,
        })
    return rows


def build_prompt(entry, lesson_id: str, seed_salt: Optional[str]):
    base_text = f"{lesson_id}|{entry['image_file']}|{entry['prompt']}|{entry['description']}"
    if seed_salt:
        base_text += f"|{seed_salt}"
    seed = _hash_seed(base_text)
    scene_id = _short_hash(base_text)
    scene_desc = entry["description"].strip()
    if not scene_desc:
        scene_desc = entry["prompt"].strip()
    if len(scene_desc) > 220:
        scene_desc = scene_desc[:217].rstrip() + "..."

    full_prompt = (
        f"{BASE_STYLE_PROMPT} "
        f"{entry['prompt']} "
        f"Scene description: {scene_desc}. "
        f"Unique seed: {seed}. Scene ID: {scene_id}."
    )

    return {
        "prompt": full_prompt,
        "seed": seed,
        "scene_id": scene_id,
    }


def main():
    parser = argparse.ArgumentParser(
        description="Generate unique image prompts per lesson slide."
    )
    parser.add_argument(
        "--lesson-id",
        help="Lesson ID from prompts/MAPPING_GUIDE.md (e.g., subjects)",
    )
    parser.add_argument(
        "--prompt-file",
        help="Path to a prompts markdown file (overrides --lesson-id)",
    )
    parser.add_argument(
        "--assets-root",
        default="assets/Lessons",
        help="Root folder for lesson assets",
    )
    parser.add_argument(
        "--lesson-dir",
        help="Explicit lesson folder path (overrides mapping)",
    )
    parser.add_argument(
        "--out",
        help="Write JSONL prompts to this file",
    )
    parser.add_argument(
        "--seed-salt",
        help="Optional salt to diversify seeds across runs",
    )
    parser.add_argument(
        "--skip-existing",
        action="store_true",
        default=True,
        help="Skip prompts for images that already exist (default)",
    )
    parser.add_argument(
        "--no-skip-existing",
        dest="skip_existing",
        action="store_false",
        help="Do not skip existing images",
    )
    parser.add_argument(
        "--print",
        dest="print_prompts",
        action="store_true",
        help="Print prompts to stdout",
    )

    args = parser.parse_args()

    mapping = parse_mapping(Path("prompts/MAPPING_GUIDE.md"))
    prompt_path = None
    lesson_id = args.lesson_id

    if args.prompt_file:
        prompt_path = Path(args.prompt_file)
        if not prompt_path.exists():
            raise SystemExit(f"Prompt file not found: {prompt_path}")
        if not lesson_id:
            lesson_id = _slug(prompt_path.stem.replace("_prompts", ""))
    else:
        if not lesson_id:
            raise SystemExit("Provide --lesson-id or --prompt-file")
        entry = mapping.get(lesson_id)
        if not entry:
            raise SystemExit(f"Lesson ID not found in mapping: {lesson_id}")
        prompt_path = Path("prompts") / entry["prompt_file"]

    rows = parse_prompt_table(prompt_path)
    if not rows:
        raise SystemExit(f"No prompt rows found in {prompt_path}")

    lesson_dir = args.lesson_dir
    if not lesson_dir:
        entry = mapping.get(lesson_id)
        if entry and entry.get("folder"):
            lesson_dir = str(Path(args.assets_root) / entry["folder"])
    lesson_dir_path = Path(lesson_dir) if lesson_dir else None

    output_entries = []
    skipped = 0
    for row in rows:
        target_path = (
            lesson_dir_path / row["image_file"]
            if lesson_dir_path
            else None
        )
        if args.skip_existing and target_path and target_path.exists():
            skipped += 1
            continue
        prompt_payload = build_prompt(row, lesson_id, args.seed_salt)
        output_entries.append({
            "lesson_id": lesson_id,
            "image_file": row["image_file"],
            "prompt": prompt_payload["prompt"],
            "seed": prompt_payload["seed"],
            "scene_id": prompt_payload["scene_id"],
            "output_path": str(target_path) if target_path else None,
        })

    if args.print_prompts:
        for entry in output_entries:
            print(f"\n# {entry['image_file']}\n{entry['prompt']}\n")

    if args.out:
        out_path = Path(args.out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with out_path.open("w", encoding="utf-8") as handle:
            for entry in output_entries:
                handle.write(json.dumps(entry, ensure_ascii=False) + "\n")

    total = len(rows)
    print(
        f"Prepared {len(output_entries)} prompts for lesson '{lesson_id}'. "
        f"Skipped {skipped} existing images. Total slides: {total}."
    )


if __name__ == "__main__":
    main()
