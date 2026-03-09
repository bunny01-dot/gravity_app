---
description: Process the beginner level vocabulary, sentences, and verb forms from CSV sheets into a structured JSON file.
---

This workflow processes the raw CSV files located in `assets/Master Sheets` and generates a consolidated JSON file in `assets/beginner_data.json`.

1. Run the processing script
   - This script reads `Vocabulary Beginner - Sheet.csv`, `Daily Sentences - Beginner - Sheet.csv`, and `Verb Forms Beginner - Sheet.csv`.
   - It parses the CSV data, handles special characters, and structures the data by Day.
   - The output is saved to `assets/beginner_data.json`.

// turbo
```bash
node scripts/process_beginner_data.js
```
