# Agent Command Rules

- Never touch a file that is not explicitly asked to touch.
- You do not have permission to delete a file unless the user explicitly commands it.

## Project Structure Rules (Keep the App Clean)

- **Python scripts** → Always place in `e:\Apps\gravity_app\python\`. Never create `.py` files in the project root or any other directory.
- **Temporary / scratch files** → Use the system `/tmp/` directory (e.g., `C:\Users\HAPPY\` or system temp). Never leave temp files in the project root.
- **Conversion scripts** (image convert, data processing, etc.) → Always place in `e:\Apps\gravity_app\python\`.
- **The project root** (`e:\Apps\gravity_app\`) must only contain standard Flutter project files: `pubspec.yaml`, `README.md`, `AGENTS.md`, `analysis_options.yaml`, and standard Flutter top-level directories (`lib/`, `assets/`, `android/`, `ios/`, `test/`, `guide/`, etc.).
- **Do not create** ad-hoc `.py`, `.js`, `.ts`, `.sh`, `.bat`, or other script files in the project root.

## Log / Debug Print Rules

- **Never use Unicode emoji or symbols** in `print()` or `debugPrint()` calls (e.g. ✅, ❌, ⚠️, 🔥). These cause mojibake on Windows consoles.
- Use plain ASCII labels instead: `[OK]`, `[FAIL]`, `[WARN]`, `[INFO]`, `[ERROR]`, `[FCM]`, `[AUTH]`, etc.


