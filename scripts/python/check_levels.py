import csv
import sys

def check_csv(filename):
    print(f"\n--- Checking {filename} ---")
    try:
        with open(filename, newline='', encoding='utf-8', errors='replace') as csvfile:
            reader = csv.reader(csvfile)
            try:
                header = next(reader)
                print(f"Header: {header}")
            except StopIteration:
                print("Empty file")
                return

            rows_to_show = 2
            count = 0
            levels = {}
            for row in reader:
                if count < rows_to_show:
                    short_row = [str(c)[:30] + '...' if len(str(c)) > 30 else c for c in row]
                    print(f"Row {count+1}: {short_row}")
                
                if len(row) > 7:
                    lvl = str(row[7]).strip()
                    levels[lvl] = levels.get(lvl, 0) + 1
                elif len(row) > 0:
                    levels['MISSING_LEVEL'] = levels.get('MISSING_LEVEL', 0) + 1
                count += 1
            
            print(f"Total data rows: {count}")
            print(f"Levels found: {levels}")
    except Exception as e:
        print(f"Error: {e}")

filenames = [
    r'e:\Apps\gravity_app\assets\reading_exercises.csv',
    r'e:\Apps\gravity_app\assets\writing_exercises.csv',
    r'e:\Apps\gravity_app\assets\speaking_exercises.csv',
    r'e:\Apps\gravity_app\assets\listening_exercises.csv'
]

for f in filenames:
    check_csv(f)
