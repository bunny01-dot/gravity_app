import os
import re
import glob

LIB_DIR = r"e:\Apps\gravity_app\lib"

# Map of emoji → ASCII replacement used in log context
EMOJI_MAP = {
    "✅": "[OK]",
    "❌": "[FAIL]",
    "⚠️": "[WARN]",
    "⚠": "[WARN]",
    "🔥": "[HOT]",
    "💡": "[INFO]",
    "📱": "[APP]",
    "🎯": "[TARGET]",
    "✓": "[OK]",
    "✔️": "[OK]",
    "✔": "[OK]",
    "⏰": "[TIMER]",
    "🚀": "[LAUNCH]",
    "📡": "[FCM]",
    "🔔": "[NOTIF]",
    "💾": "[SAVE]",
    "🗑️": "[DELETE]",
    "🗑": "[DELETE]",
    "🧹": "[CLEAN]",
    "🔐": "[AUTH]",
    "🔑": "[KEY]",
    "📊": "[DATA]",
    "📈": "[UP]",
    "📉": "[DOWN]",
    "🎉": "[SUCCESS]",
    "🏆": "[WIN]",
    "⭐": "[STAR]",
    "🌟": "[STAR]",
    "💰": "[COINS]",
    "🔄": "[REFRESH]",
    "🔃": "[REFRESH]",
    "📌": "[PIN]",
    "📍": "[LOC]",
    "🎮": "[GAME]",
    "🎲": "[DICE]",
    "🃏": "[CARD]",
    "🧩": "[PUZZLE]",
    "❤️": "[HEART]",
    "❤": "[HEART]",
    "💙": "[HEART]",
    "💚": "[HEART]",
    "💛": "[HEART]",
    "🎵": "[MUSIC]",
    "🎶": "[MUSIC]",
    "🔊": "[SOUND]",
    "🔇": "[MUTE]",
    "💬": "[MSG]",
    "🗨️": "[MSG]",
    "📬": "[MAIL]",
    "📫": "[MAIL]",
    "📮": "[MAIL]",
    "✉️": "[MAIL]",
    "✉": "[MAIL]",
    "📧": "[EMAIL]",
    "🌐": "[WEB]",
    "🌍": "[WORLD]",
    "🌎": "[WORLD]",
    "🌏": "[WORLD]",
    "👨": "[USER]",
    "👩": "[USER]",
    "👦": "[USER]",
    "👧": "[USER]",
    "👶": "[USER]",
    "🧑": "[USER]",
    "💻": "[PC]",
    "🖥️": "[PC]",
    "🖥": "[PC]",
    "⌨️": "[KEYBOARD]",
    "⌨": "[KEYBOARD]",
    "🖱️": "[MOUSE]",
    "🖱": "[MOUSE]",
    "▶️": "[PLAY]",
    "▶": "[PLAY]",
    "⏸️": "[PAUSE]",
    "⏸": "[PAUSE]",
    "⏹️": "[STOP]",
    "⏹": "[STOP]",
    "⬅️": "[LEFT]",
    "⬅": "[LEFT]",
    "➡️": "[RIGHT]",
    "➡": "[RIGHT]",
    "⬆️": "[UP]",
    "⬆": "[UP]",
    "⬇️": "[DOWN]",
    "⬇": "[DOWN]",
    "↩️": "[BACK]",
    "↩": "[BACK]",
    "↪️": "[FWD]",
    "↪": "[FWD]",
    "🔁": "[REPEAT]",
    "🔂": "[REPEAT]",
    "🔼": "[UP]",
    "🔽": "[DOWN]",
    "◀️": "[PREV]",
    "◀": "[PREV]",
    "⏮️": "[FIRST]",
    "⏮": "[FIRST]",
    "⏭️": "[LAST]",
    "⏭": "[LAST]",
    "📋": "[COPY]",
    "📝": "[EDIT]",
    "🏠": "[HOME]",
    "🌙": "[NIGHT]",
    "☀️": "[DAY]",
    "☀": "[DAY]",
    "…": "...",
    "\u2026": "...",
    "→": "->",
    "←": "<-",
    "⟶": "->",
    "⟵": "<-",
}

# Build a regex that only matches inside print/debugPrint calls
# We'll use a line-by-line approach: if the line has print or debugPrint, replace emoji

dart_files = glob.glob(os.path.join(LIB_DIR, "**", "*.dart"), recursive=True)

total_files_changed = 0
total_replacements = 0

for filepath in dart_files:
    with open(filepath, "r", encoding="utf-8") as f:
        try:
            content = f.read()
        except Exception as e:
            print(f"[SKIP] {filepath}: {e}")
            continue

    lines = content.split("\n")
    new_lines = []
    file_changed = False

    for line in lines:
        # Only process lines with print or debugPrint
        if re.search(r'\b(debugPrint|print)\s*\(', line):
            original = line
            for emoji, replacement in EMOJI_MAP.items():
                if emoji in line:
                    line = line.replace(emoji, replacement)
            if line != original:
                file_changed = True
                total_replacements += 1
        new_lines.append(line)

    if file_changed:
        total_files_changed += 1
        new_content = "\n".join(new_lines)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(new_content)
        rel = os.path.relpath(filepath, LIB_DIR)
        print(f"[FIXED] {rel}")

print(f"\nDone: {total_files_changed} files changed, {total_replacements} lines fixed.")
