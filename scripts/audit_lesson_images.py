#!/usr/bin/env python3
import argparse
from pathlib import Path

PLACEHOLDER_TOKENS = ["placeholder", "temp", "sample"]
SUSPICIOUS_TOKENS = ["photo", "real", "stock", "unsplash", "pexels", "pixabay"]
IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}


def audit_lessons(assets_root: Path):
    report = []
    for lesson_dir in sorted(assets_root.glob("Lesson_*")):
        if not lesson_dir.is_dir():
            continue
        all_files = [p for p in lesson_dir.rglob("*") if p.is_file()]
        images = [p for p in all_files if p.suffix.lower() in IMAGE_EXTS]
        placeholder = [
            p for p in all_files
            if any(tok in p.name.lower() for tok in PLACEHOLDER_TOKENS)
        ]
        non_webp = [p for p in images if p.suffix.lower() != ".webp"]
        suspicious = [
            p for p in images
            if any(tok in p.name.lower() for tok in SUSPICIOUS_TOKENS)
        ]

        if placeholder or non_webp or suspicious:
            report.append({
                "lesson": lesson_dir.name,
                "placeholder": placeholder,
                "non_webp": non_webp,
                "suspicious": suspicious,
            })

    return report


def print_report(report):
    if not report:
        print("All lesson folders look clean (no placeholders or non-webp images found).")
        return

    for entry in report:
        print(f"\n{entry['lesson']}")
        if entry["placeholder"]:
            print("  placeholders:")
            for item in entry["placeholder"]:
                print(f"    - {item}")
        if entry["non_webp"]:
            print("  non-webp images:")
            for item in entry["non_webp"]:
                print(f"    - {item}")
        if entry["suspicious"]:
            print("  suspicious names:")
            for item in entry["suspicious"]:
                print(f"    - {item}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Audit lesson image folders for placeholders or non-webp files."
    )
    parser.add_argument(
        "--assets-root",
        default="assets/Lessons",
        help="Root folder for lesson assets",
    )
    args = parser.parse_args()
    report = audit_lessons(Path(args.assets_root))
    print_report(report)
