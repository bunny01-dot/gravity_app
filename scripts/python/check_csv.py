import csv
import sys
import collections

def check_csv(filename):
    print(f"Checking {filename}...")
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            rows = list(reader)
    except Exception as e:
        print(f"Failed to read file: {e}")
        return

    # Skip header
    data_rows = rows[1:]
    
    day_counts = collections.defaultdict(int)
    
    for i, row in enumerate(data_rows):
        if not row: continue
        # Expect Day at index 1
        if len(row) < 2: continue
        
        day_str = row[1].strip()
        # Parse "Day X"
        day_num = 0
        try:
            if 'Day' in day_str:
                day_num = int(day_str.lower().replace('day', '').strip())
            else:
                 day_num = int(day_str)
        except:
            continue
            
        if 1 <= day_num <= 90:
            day_counts[day_num] += 1

    errors = []
    for d in range(1, 91):
        if day_counts[d] != 5:
            errors.append(f"Day {d}: count = {day_counts[d]}")
            
    if errors:
        print(f"Validation FAILED. Found {len(errors)} days with incorrect counts:")
        for e in errors[:10]:
            print(e)
    else:
        print("Validation PASSED. All days 1-90 have 5 items.")

check_csv('e:/Apps/gravity_app/assets/Master Sheets/Verb Forms Beginner - Sheet.csv')
