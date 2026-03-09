# Fixed: Words Not Saving on Task Completion

## 🐛 **The Bug**
When completing "Daily Vocabulary" or "Daily Verb Forms", the app marked the **task** as done (blue checkmark ✅) but **failed to save** the learned words to the database/storage.

**Result**:
1. Dashboard says "Completed" ✅
2. But "Learned Words" count remained at 0 ❌
3. Games Hub saw 0 words and stayed LOCKED 🔒

## 🛠️ **The Fix**
Modified `dashboard.dart` inside `_showTaskContentSheet`.

**Code Change**:
Added logic to the "Mark as Done" button to properly save each word before marking the task complete.

```dart
// ✅ CRITICAL FIX: Save learned items to storage!
String type = 'unknown';
if (title.contains('Vocabulary')) type = 'vocab';
else if (title.contains('Verb')) type = 'verb';

if (type != 'unknown') {
  for (var item in items) {
    // Calls DataService to add word to learned_vocab_ids
    await _dataService.markItemAsLearned(type, item['word']);
  }
}
```

## 🔄 **Verification**
1. **Tomorrow onwards**: Completing the task will automatically unlock games.
2. **For Today**: Since the task is already "Done" (so the button is disabled), you must rename the `task_vocab_2026-01-20` key or manually add words using the debug tool I provided to unlock games immediately.

## 📝 **Technical Details**
- File: `lib/dashboard.dart`
- Method: `_showTaskContentSheet` > `FilledButton` > `onPressed`
- Services Used: `DataService.markItemAsLearned`
