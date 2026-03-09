---
description: Process all levels (Beginner, Intermediate, Advanced) of vocabulary, sentences, and verb forms from CSV sheets into structured JSON files.
---

This workflow processes the raw CSV files for all difficulty levels and generates consolidated JSON files in the `assets/` directory.

1.  Run the processing script for **Beginner** level.
// turbo
```bash
node scripts/process_level_data.js beginner
```

2.  Run the processing script for **Intermediate** level.
// turbo
```bash
node scripts/process_level_data.js intermediate
```

3.  Run the processing script for **Advanced** level.
// turbo
```bash
node scripts/process_level_data.js advanced
```
