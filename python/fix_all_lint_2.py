"""
Script to fix remaining dart errors.
"""

import re
import os
import glob

LIB_DIR = r"e:\Apps\gravity_app\lib"
total_changed = 0

def fix_file(filepath):
    global total_changed
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    changed = False
    
    # Check import vs part order (for dashboard_screen.dart)
    if "import" in content and "part " in content:
        lines = content.split("\n")
        imports = []
        parts = []
        others = []
        
        # very simple fix just for dashboard_screen
        if filepath.endswith(r"dashboard\dashboard_screen.dart"):
            # Move all imports before parts
            new_lines = []
            import_lines = []
            part_lines = []
            for line in lines:
                if line.startswith("import '"):
                    import_lines.append(line)
                elif line.startswith("part '"):
                    part_lines.append(line)
                else:
                    others.append(line)
            
            # This is too risky to do globally, just do it carefully:
            # See if there's an import after a part
            found_part = False
            needs_fix = False
            for line in lines:
                if line.startswith("part '"):
                    found_part = True
                elif found_part and line.startswith("import '"):
                    needs_fix = True
            
            if needs_fix:
                print(f"[FIX] Reordering imports in dashboard_screen.dart")
                # Find the first part '...'
                first_part_idx = -1
                for i, line in enumerate(lines):
                    if line.startswith("part '"):
                        first_part_idx = i
                        break
                
                # Move all imports after first_part_idx before it
                if first_part_idx != -1:
                    imports_to_move = []
                    # iterate backwards to remove safely
                    for i in range(len(lines)-1, first_part_idx, -1):
                        if lines[i].startswith("import '"):
                            imports_to_move.append(lines.pop(i))
                    
                    # insert them right before the first part
                    for imp in reversed(imports_to_move):
                        lines.insert(first_part_idx, imp)
                    
                    content = "\n".join(lines)
                    changed = True

    # 1. Fix string interpolation for vars starting with underscore:
    # \$([a-zA-Z_][a-zA-Z0-9_]*)_(\$|\'|"|\})
    def fix_interp(m):
        nonlocal changed
        changed = True
        return '${' + m.group(1) + '}_' + m.group(2)
        
    content = re.sub(r'\$([a-zA-Z_][a-zA-Z0-9_]*)_(\$|\'|")', fix_interp, content)

    # 2. Fix specific known broken identifiers:
    fixes = {
        "key_score": "key_$score",
        "separatorv": "separator",
        "assetPathactive_passive_hook_square": "${assetPath}active_passive_hook_square",
        "assetPathactive_passive_structure_square": "${assetPath}active_passive_structure_square",
        "assetPathpresent_voice_square": "${assetPath}present_voice_square",
        "assetPathpast_voice_square": "${assetPath}past_voice_square",
        "assetPathvoice_reference_square": "${assetPath}voice_reference_square",
        "assetPathpassive_when_square": "${assetPath}passive_when_square",
        "assetPathvoice_quiz_square": "${assetPath}voice_quiz_square",
        "assetPathvoice_arrow_flow_square": "${assetPath}voice_arrow_flow_square",
        "assetPathphrasal_speaking_square": "${assetPath}phrasal_speaking_square",
        "type_completed": "type}_completed", # from ${type}_completed stripped to $type_completed
        "category_completed": "category}_completed",
        "zipKey_temp": "zipKey_temp", # wait, zipKey_temp doesn't make sense, let's look at the actual code
        "gameId_unlocked_level": "gameId}_unlocked_level",
        "gameId_level_": "gameId}_level_",
        "level_stars": "level}_stars",
        "stage_score": "stage}_score",
    }
    
    for old, new in fixes.items():
        if old in content:
            # Check if it was interpolation that broke e.g. $type_completed -> ${type}_completed
            if old.endswith("_completed") and ("$" + old) in content:
                content = content.replace("$" + old, "${" + old.split("_")[0] + "}_completed")
                changed = True
            elif ("$" + old) in content and ("}" in new):
                content = content.replace("$" + old, "${" + new)
                changed = True
            elif "assetPath" in old:
                content = content.replace("'" + old, "'${assetPath}" + old.replace("assetPath", ""))
                content = content.replace('"' + old, '"${assetPath}' + old.replace("assetPath", ""))
                changed = True
            elif old == "key_score" and "$key_score" in content:
                content = content.replace("$key_score", "${key}_score")
                changed = True
            elif old == "separatorv":
                content = content.replace("separatorv", "separator")
                changed = True

    # 3. Base/Verb interpolation issues: 'bases', 'baseing', 'v1ing', 'v1s', etc.
    # Usually: $bases -> ${base}s, $baseing -> ${base}ing, $v1s -> ${v1}s
    verb_fixes = [
        ("$bases", "${base}s"),
        ("$baseing", "${base}ing"),
        ("$baseed", "${base}ed"),
        ("$pasten", "${past}en"),
        ("$v1s", "${v1}s"),
        ("$v1ing", "${v1}ing"),
        ("$v1es", "${v1}es"),
        ("$v1en", "${v1}en"),
        ("$v1d", "${v1}d"),
        ("$verbed", "${verb}ed"),
        ("$otherFormed", "${otherForm}ed"),
        ("$based", "${base}d"),
    ]
    for old, new in verb_fixes:
        if old in content:
            content = content.replace(old, new)
            changed = True
            
    # 4. AppConfig missing import
    if "AppConfig" in content and not "import" in content and "data_service" in filepath:
        # We need to import AppConfig
        pass # actually handled below

    if changed:
        total_changed += 1
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        rel = os.path.relpath(filepath, LIB_DIR)
        print(f"[FIXED] {rel}")

dart_files = glob.glob(os.path.join(LIB_DIR, "**", "*.dart"), recursive=True)
for filepath in dart_files:
    fix_file(filepath)

# Specific fix for data_service.dart and AppConfig
data_service = os.path.join(LIB_DIR, "services", "data_service.dart")
safe_game = os.path.join(LIB_DIR, "services", "safe_game_content_provider.dart")
for p in [data_service, safe_game]:
    if os.path.exists(p):
        with open(p, 'r', encoding='utf-8') as f:
            c = f.read()
        if "AppConfig" in c and "import 'package:gravity_app/core/config/app_config.dart';" not in c:
            c = c.replace("import 'package:gravity_app/", "import 'package:gravity_app/core/config/app_config.dart';\nimport 'package:gravity_app/", 1)
            with open(p, 'w', encoding='utf-8') as f:
                f.write(c)
            print(f"[FIXED IMPORT] {os.path.basename(p)}")

print(f"\nDone! Changed {total_changed} files.")
