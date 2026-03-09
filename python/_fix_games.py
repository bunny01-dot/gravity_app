import os
import re
import glob

games_dir = r"e:\Apps\gravity_app\lib\screens\games"
files = glob.glob(games_dir + "\**\*.dart", recursive=True)

updated_files = []

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'OfflineXpService' in content or 'addXp' in content:
        continue
        
    if '_showCompletionDialog' not in content:
        continue

    import_stmt = "import 'package:gravity_app/services/offline_xp_service.dart';\n"
    match = re.search(r'class \w+ extends', content)
    if match:
        idx = match.start()
        content = content[:idx] + import_stmt + content[idx:]
        
    def repl(m):
        return m.group(1) + "\n    OfflineXpService().addXp(10);"
        
    new_content = re.sub(r'(void _showCompletionDialog\(\)(?: async)? \{)', repl, content)
    
    if new_content != content:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(new_content)
        updated_files.append(os.path.basename(file))
        
print(f'Updated {len(updated_files)} files to award XP.')
for f in updated_files:
    print(' -', f)
