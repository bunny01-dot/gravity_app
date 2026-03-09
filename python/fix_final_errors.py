import re

# 1. Dashboard Screen (move imports before parts)
with open(r'e:\\Apps\\gravity_app\\lib\\dashboard\\dashboard_screen.dart', 'r', encoding='utf-8') as f:
    c = f.read()
lines = c.split('\n')
first_part_idx = -1
for i, line in enumerate(lines):
    if line.startswith('part '):
        first_part_idx = i
        break
if first_part_idx != -1:
    to_move = []
    # iterate backwards to pop safely
    for i in range(len(lines)-1, first_part_idx, -1):
        if lines[i].startswith('import '):
            to_move.append(lines.pop(i))
    for imp in reversed(to_move):
        lines.insert(first_part_idx, imp)
with open(r'e:\\Apps\\gravity_app\\lib\\dashboard\\dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
print('Fixed dashboard_screen.dart')


# 2. Lesson Active Passive String Interpolation
with open(r'e:\\Apps\\gravity_app\\lib\\screens\\lesson_active_passive_screen.dart', 'r', encoding='utf-8') as f:
    c = f.read()

fixes = [
    "active_passive_hook_square",
    "active_passive_structure_square",
    "present_voice_square",
    "past_voice_square",
    "voice_reference_square",
    "passive_when_square",
    "voice_quiz_square",
    "voice_arrow_flow_square",
    "phrasal_speaking_square"
]
for fix in fixes:
    # Need to change assetPathname -> '${assetPath}name.webp'
    # And handle any weird quote wrapping if my previous script did "'${assetPath}name'"
    old1 = f"assetPath{fix}"
    old2 = f"'${{assetPath}}{fix}'"
    new = f"'${{assetPath}}{fix}.webp'"
    
    if old1 in c:
        c = c.replace(old1, new)
    elif old2 in c:
        c = c.replace(old2, new)

# And fix line 408 missing arguments:
# It's LessonSummarySlide(...) missing prompts and summaryPoints
summary_slide_pattern = r'LessonSummarySlide\(\s*lessonType:\s*[\'"].*?[\'"],\s*\)'
new_summary = '''LessonSummarySlide(
  lessonType: "Active & Passive Voice",
  prompts: [
    "I understand the difference between Active & Passive Voice.",
    "I can choose when to use Passive Voice.",
  ],
  summaryPoints: [
    "Active Voice focuses on WHO does the action.",
    "Passive Voice focuses on the ACTION itself.",
  ],
)'''
c = re.sub(summary_slide_pattern, new_summary, c)

with open(r'e:\\Apps\\gravity_app\\lib\\screens\\lesson_active_passive_screen.dart', 'w', encoding='utf-8') as f:
    f.write(c)
print('Fixed lesson_active_passive_screen.dart')


# 3. Data Service missing AppConfig
with open(r'e:\\Apps\\gravity_app\\lib\\services\\data_service.dart', 'r', encoding='utf-8') as f:
    c = f.read()
if "import 'package:gravity_app/core/config/app_config.dart';" not in c:
    c = c.replace("import 'package:gravity_app/features/daily_sentences/", "import 'package:gravity_app/core/config/app_config.dart';\nimport 'package:gravity_app/features/daily_sentences/")
with open(r'e:\\Apps\\gravity_app\\lib\\services\\data_service.dart', 'w', encoding='utf-8') as f:
    f.write(c)
print('Fixed data_service.dart')

# 4. Safe Game Content Provider missing AppConfig
with open(r'e:\\Apps\\gravity_app\\lib\\services\\safe_game_content_provider.dart', 'r', encoding='utf-8') as f:
    c = f.read()
if "import 'package:gravity_app/core/config/app_config.dart';" not in c:
    c = f"import 'package:gravity_app/core/config/app_config.dart';\n{c}"
with open(r'e:\\Apps\\gravity_app\\lib\\services\\safe_game_content_provider.dart', 'w', encoding='utf-8') as f:
    f.write(c)
print('Fixed safe_game_content_provider.dart')

# 5. Level Manager variable name
with open(r'e:\\Apps\\gravity_app\\lib\\services\\level_manager.dart', 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace('${gameId}_level_', '${gameId}_level')
with open(r'e:\\Apps\\gravity_app\\lib\\services\\level_manager.dart', 'w', encoding='utf-8') as f:
    f.write(c)
print('Fixed level_manager.dart')

