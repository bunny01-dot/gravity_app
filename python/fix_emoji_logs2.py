import re

# Fix all remaining non-ASCII characters in print/debugPrint lines using bytes
# This handles the case where the file has literal corrupted byte sequences

LIB_DIR = r"e:\Apps\gravity_app\lib"

import os
import glob

dart_files = glob.glob(os.path.join(LIB_DIR, "**", "*.dart"), recursive=True)

total_files_changed = 0
total_replacements = 0

for filepath in dart_files:
    # Read as bytes, then decode replacing errors
    with open(filepath, "rb") as f:
        raw = f.read()

    # Try to decode as UTF-8 strict to see if file is clean
    try:
        content = raw.decode("utf-8")
        # Check if any print lines still have non-ASCII
        lines = content.split("\n")
        has_issue = False
        new_lines = []
        for line in lines:
            if re.search(r'\b(debugPrint|print)\s*\(', line):
                cleaned = line.encode("ascii", errors="replace").decode("ascii")
                cleaned = cleaned.replace("?", "?")  # keep ? as is
                # More specific: replace runs of ? with nothing or describe them
                if cleaned != line:
                    has_issue = True
                    # Use regex to find non-ASCII runs and replace with nothing
                    fixed = re.sub(r'[^\x00-\x7F]+', '', line)
                    new_lines.append(fixed)
                    total_replacements += 1
                    continue
            new_lines.append(line)

        if has_issue:
            total_files_changed += 1
            rel = os.path.relpath(filepath, LIB_DIR)
            with open(filepath, "w", encoding="utf-8") as f:
                f.write("\n".join(new_lines))
            print(f"[FIXED] {rel}")

    except UnicodeDecodeError:
        # File has invalid bytes — decode with errors ignored
        content = raw.decode("utf-8", errors="ignore")
        lines = content.split("\n")
        new_lines = []
        has_issue = True
        for line in lines:
            if re.search(r'\b(debugPrint|print)\s*\(', line):
                fixed = re.sub(r'[^\x00-\x7F]+', '', line)
                if fixed != line:
                    total_replacements += 1
                new_lines.append(fixed)
            else:
                new_lines.append(line)
        total_files_changed += 1
        rel = os.path.relpath(filepath, LIB_DIR)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write("\n".join(new_lines))
        print(f"[FIXED bytes] {rel}")

print(f"\nDone: {total_files_changed} files changed, {total_replacements} lines fixed.")
