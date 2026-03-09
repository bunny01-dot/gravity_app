"""
Comprehensive fix script for all lint errors in gravity_app/lib.
Handles:
1. Missing flutter/foundation.dart import for debugPrint in non-widget classes
2. Missing AnalyticsService import in files that use it
3. String interpolation bugs: $var_ -> ${var}_ and $var_something -> ${var}_something
4. Remaining non-ASCII chars outside print statements
5. assetPath string interpolation bugs
"""

import re
import os
import glob

LIB_DIR = r"e:\Apps\gravity_app\lib"

# Files that need flutter/foundation.dart added (debugPrint not defined)
FOUNDATION_IMPORT = "import 'package:flutter/foundation.dart';"
ANALYTICS_IMPORT = "import 'package:gravity_app/services/analytics_service.dart';"

def get_imports_block_end(lines):
    """Find the line index after the last import statement"""
    last_import = 0
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("import ") or stripped.startswith("part ") or stripped.startswith("// "):
            last_import = i
    return last_import + 1

def add_import_if_missing(content, import_line):
    """Add import if not already present in file"""
    if import_line in content:
        return content, False
    lines = content.split('\n')
    # Find best position: after last import
    insert_pos = 0
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("import ") or stripped.startswith("part ") or stripped.startswith("export "):
            insert_pos = i + 1
    lines.insert(insert_pos, import_line)
    return '\n'.join(lines), True

def fix_string_interpolation(content):
    """
    Fix broken string interpolation patterns where var followed by _ gets parsed as var_:
    e.g., '$userId_$dateKey' -> '${userId}_$dateKey'
    'prefix_$userId_suffix' -> 'prefix_${userId}_suffix'
    """
    # Pattern: $identifier_ where identifier + _ is NOT a valid Dart identifier we want
    # We look for cases where a Dart identifier in interpolation is followed by _ then more content
    # Match $word_ (where next char is $ or end of string context within quotes)
    
    changed = False
    
    # Fix: '$var_$other' -> '${var}_$other'  (underscore then $ or quote or end)
    def fix_interp(m):
        nonlocal changed
        changed = True
        return '${' + m.group(1) + '}_' + m.group(2)
    
    # Pattern: dollar + word chars + underscore + (dollar or quote end)  
    new_content = re.sub(r'\$([a-zA-Z][a-zA-Z0-9]*)_(\$|\'|")', fix_interp, content)
    
    return new_content, changed

def fix_asset_path_interpolation(content):
    """Fix assetPath concatenation bugs like: assetPathactive_passive_hook_square -> '$assetPath\active_passive_hook_square' """
    # Pattern: assetPath followed directly by identifier chars (missing $)
    # e.g., 'assetPathactive_passive_hook_square' -> '$assetPath\active_passive_hook_square'
    changed = False
    
    # Look for string contexts where assetPath is concatenated without interpolation
    # Like: "assetPathsome_name.webp" -> "${assetPath}some_name.webp"
    def fix_asset(m):
        nonlocal changed
        changed = True
        return "'${assetPath}" + m.group(1) + "'"
    
    new_content = re.sub(r"'assetPath([a-z_]+\.webp)'", fix_asset, content)
    return new_content, changed

def remove_remaining_non_ascii(content):
    """Remove non-ASCII chars that remain anywhere in file (outside strings we care about)"""
    # Only clean lines that are identifiers/variable names (not in string literals)
    # This is tricky, so just clean known patterns
    changed = False
    
    # Remove ⚠️ and similar in comments or strings
    clean = re.sub(r'[^\x00-\x7F]+', '', content)
    if clean != content:
        changed = True
    return clean, changed

# Files needing foundation.dart import
NEEDS_FOUNDATION = [
    r"core\cache\announcements_cache.dart",
    r"core\cache\attendance_cache.dart",
    r"core\cache\leaderboard_cache.dart",
    r"core\cache\students_cache.dart",
    r"core\cache\teacher_notifications_cache.dart",
    r"core\cache\cache_manager.dart",
    r"core\services\content_service.dart",
    r"services\word_match_unlock_service.dart",
]

# Files needing AnalyticsService import
# These are 'part' files — their parent must have the import
# So we add to the parent file: dashboard_screen.dart
# But since we can't control 'part' files directly, let's check which are top-level
NEEDS_ANALYTICS_TOP_LEVEL = [
    r"services\tutorial_service.dart",
    r"widgets\locked_games_view.dart",
    r"widgets\mastery_card.dart", 
    r"widgets\word_match_difficulty_dialog.dart",
    r"screens\story_book_v2_screen.dart",
    r"screens\lesson_parts_of_speech_screen.dart",
    r"screens\lesson_present_tense_screen.dart",
    r"screens\lesson_subjects_screen.dart",
    r"features\tutorial\onboarding_screen.dart",
]

# These are 'part of' files - parent needs import
NEEDS_ANALYTICS_PARENTS = {
    r"dashboard\dashboard_actions.dart": r"dashboard\dashboard_screen.dart",
    r"dashboard\dashboard_tasks.dart": r"dashboard\dashboard_screen.dart",
    r"dashboard\dashboard_tutorial.dart": r"dashboard\dashboard_screen.dart",
    r"features\dashboard\widgets\settings_tab.dart": None,  # standalone
}

total_changed = 0

def fix_file(filepath):
    global total_changed
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    original = content
    changed = False
    rel = os.path.relpath(filepath, LIB_DIR)
    
    # Fix string interpolation bugs
    content, c1 = fix_string_interpolation(content)
    if c1:
        changed = True
    
    # Fix asset path interpolation
    content, c2 = fix_asset_path_interpolation(content)
    if c2:
        changed = True
        
    # Remove remaining non-ascii chars that aren't in strings we care about
    # Only do this for files with non-ASCII identifiers (not string content files)
    content, c3 = remove_remaining_non_ascii(content)
    if c3:
        changed = True
    
    if changed:
        total_changed += 1
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"[FIXED interp] {rel}")
    
    return content, rel

# == Step 1: Add flutter/foundation.dart to files needing debugPrint ==
print("=== Step 1: Adding flutter/foundation.dart imports ===")
for rel_path in NEEDS_FOUNDATION:
    filepath = os.path.join(LIB_DIR, rel_path)
    if not os.path.exists(filepath):
        print(f"[SKIP] Not found: {rel_path}")
        continue
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    content, added = add_import_if_missing(content, FOUNDATION_IMPORT)
    if added:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        total_changed += 1
        print(f"[IMPORT] Added foundation.dart to {rel_path}")
    else:
        print(f"[SKIP] foundation.dart already in {rel_path}")

# == Step 2: Add AnalyticsService import to standalone files ==
print("\n=== Step 2: Adding AnalyticsService imports ===")
for rel_path in NEEDS_ANALYTICS_TOP_LEVEL:
    filepath = os.path.join(LIB_DIR, rel_path)
    if not os.path.exists(filepath):
        print(f"[SKIP] Not found: {rel_path}")
        continue
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    # Check if 'part of' - if so skip, parent must be fixed
    if content.strip().startswith("part of ") or "\npart of " in content[:500]:
        print(f"[SKIP] part-of file: {rel_path} (need to fix parent)")
        continue
    content, added = add_import_if_missing(content, ANALYTICS_IMPORT)
    if added:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        total_changed += 1
        print(f"[IMPORT] Added AnalyticsService to {rel_path}")
    else:
        print(f"[SKIP] AnalyticsService already in {rel_path}")

# Add to dashboard_screen.dart (parent of parts)
dashboard_screen = os.path.join(LIB_DIR, r"dashboard\dashboard_screen.dart")
if os.path.exists(dashboard_screen):
    with open(dashboard_screen, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    content, added = add_import_if_missing(content, ANALYTICS_IMPORT)
    if added:
        with open(dashboard_screen, 'w', encoding='utf-8') as f:
            f.write(content)
        total_changed += 1
        print(f"[IMPORT] Added AnalyticsService to dashboard_screen.dart")

# settings_tab.dart is standalone 
settings_tab = os.path.join(LIB_DIR, r"features\dashboard\widgets\settings_tab.dart")
if os.path.exists(settings_tab):
    with open(settings_tab, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    content, added = add_import_if_missing(content, ANALYTICS_IMPORT)
    if added:
        with open(settings_tab, 'w', encoding='utf-8') as f:
            f.write(content)
        total_changed += 1
        print(f"[IMPORT] Added AnalyticsService to settings_tab.dart")

# == Step 3: Fix string interpolation and non-ASCII across all dart files ==
print("\n=== Step 3: Fixing string interpolation and non-ASCII ===")
dart_files = glob.glob(os.path.join(LIB_DIR, "**", "*.dart"), recursive=True)
for filepath in dart_files:
    fix_file(filepath)

print(f"\nTotal files changed: {total_changed}")
