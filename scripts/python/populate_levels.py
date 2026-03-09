import csv
import os

def populate_levels(input_file, output_file, level_column_index):
    """
    Populate the level column with Beginner/Intermediate/Advanced
    Split: First 40% = Beginner, Next 40% = Intermediate, Last 20% = Advanced
    """
    print(f"\n--- Processing {input_file} ---")
    
    try:
        with open(input_file, 'r', encoding='utf-8', newline='') as f:
            reader = csv.reader(f)
            rows = list(reader)
        
        if len(rows) < 2:
            print("File has no data rows, skipping.")
            return
        
        header = rows[0]
        data_rows = rows[1:]
        total = len(data_rows)
        
        print(f"Total exercises: {total}")
        
        # Calculate splits
        beginner_count = int(total * 0.4)
        intermediate_count = int(total * 0.4)
        
        # Assign levels
        for i, row in enumerate(data_rows):
            # Ensure row has enough columns
            while len(row) <= level_column_index:
                row.append('')
            
            if i < beginner_count:
                row[level_column_index] = 'Beginner (A1)'
            elif i < beginner_count + intermediate_count:
                row[level_column_index] = 'Intermediate (B1)'
            else:
                row[level_column_index] = 'Advanced (C1)'
        
        # Write back
        with open(output_file, 'w', encoding='utf-8', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(header)
            writer.writerows(data_rows)
        
        # Count by level
        levels = {}
        for row in data_rows:
            if len(row) > level_column_index:
                lvl = row[level_column_index]
                levels[lvl] = levels.get(lvl, 0) + 1
        
        print(f"✅ Updated! Distribution: {levels}")
        
    except Exception as e:
        print(f"❌ Error: {e}")

# Process each file
# Reading: level is column 7 (index 7)
populate_levels(
    r'e:\Apps\gravity_app\assets\reading_exercises.csv',
    r'e:\Apps\gravity_app\assets\reading_exercises.csv',
    7
)

# Writing: level is column 2 (index 2)
populate_levels(
    r'e:\Apps\gravity_app\assets\writing_exercises.csv',
    r'e:\Apps\gravity_app\assets\writing_exercises.csv',
    2
)

# Listening: level column index (need to check header)
# Based on earlier output, listening has 7 columns but all empty
# Let me check the structure
print("\n--- Checking Listening Structure ---")
with open(r'e:\Apps\gravity_app\assets\listening_exercises.csv', 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    header = next(reader)
    print(f"Listening Header: {header}")
    print(f"Looking for 'level' or 'Level' column...")
    
    # Find level column
    level_idx = -1
    for i, h in enumerate(header):
        if 'level' in h.lower():
            level_idx = i
            print(f"Found at index {i}: {h}")
            break
    
    if level_idx == -1:
        print("⚠️ No 'level' column found in header! Will add a new column.")
        # We need to add a level column
        # For now, let's append it as the last column
        level_idx = len(header)
        header.append('Level')
        
        # Reopen and add column
        with open(r'e:\Apps\gravity_app\assets\listening_exercises.csv', 'r', encoding='utf-8', newline='') as f2:
            reader2 = csv.reader(f2)
            next(reader2)  # skip old header
            data_rows = list(reader2)
        
        total = len(data_rows)
        beginner_count = int(total * 0.4)
        intermediate_count = int(total * 0.4)
        
        for i, row in enumerate(data_rows):
            if i < beginner_count:
                row.append('Beginner (A1)')
            elif i < beginner_count + intermediate_count:
                row.append('Intermediate (B1)')
            else:
                row.append('Advanced (C1)')
        
        with open(r'e:\Apps\gravity_app\assets\listening_exercises.csv', 'w', encoding='utf-8', newline='') as f3:
            writer = csv.writer(f3)
            writer.writerow(header)
            writer.writerows(data_rows)
        
        print(f"✅ Added Level column and populated {total} rows!")

print("\n🎉 All mastery CSV files updated with level data!")
