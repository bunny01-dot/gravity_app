# CRITICAL BUG: Games Word Count Not Refreshing

## 🚨 **Problem**

User completed daily vocabulary task (learned 5 words), but games still show "Learn 4 more words" - the SAME message as before completing the task!

## 🔍 **Root Cause Analysis**

### **The Flow**:

```
1. User opens Games Hub
   └─> _GamesGridSheetState.initState() called
       └─> _loadLearnedWordsCount() loads count ONCE
           └─> Reads: learned_vocab_ids.length = 0
           └─> Sets: _learnedWordsCount = 0

2. User closes Games Hub, completes Daily Vocab Task
   └─> 5 words learned
   └─> learned_vocab_ids = [word1, word2, word3, word4, word5]
   └─> saved to SharedPreferences ✅

3. User re-opens Games Hub
   └─> _GamesGridSheetState.initState() called AGAIN
       └─> _loadLearnedWordsCount() should reload...
           └─> Reads: learned_vocab_ids.length SHOULD be 5
           └─> BUT... showing OLD value!
```

### **Synchronization Issue**:

The Games Hub Sheet (`GamesGridSheet`) loads the word count in `initState()` which runs **once when the sheet opens**. BUT:

1. **If user CLOSES the sheet** (doesn't navigate away, just dismisses modal)
2. **Completes daily tasks**
3. **Re-opens the sheet**
4. The count SHOULD refresh, but there might be SharedPreferences caching

### **Most Likely Cause**:

**SharedPreferences caching** - The `await prefs.reload()` is MISSING!

**Location**: `lib/widgets/games_hub_card.dart` Line 397

```dart
Future<void> _loadLearnedWordsCount() async {
  final prefs = await SharedPreferences.getInstance();
  
  // ❌ BUG: No prefs.reload()!
  // If SharedPreferences instance is cached, it won't see new values
  
  final List<String> learnedVocabIds =
      prefs.getStringList('learned_vocab_ids') ?? [];
  final List<String> learnedVerbIds =
      prefs.getStringList('learned_verbs_ids') ?? [];
      
  int count = learnedVocabIds.length + learnedVerbIds.length;
  
  if (mounted) {
    setState(() {
      _learnedWordsCount = count;
    });
  }
}
```

## ✅ **Solution**

### **Add `prefs.reload()` before reading**:

```dart
Future<void> _loadLearnedWordsCount() async {
  final prefs = await SharedPreferences.getInstance();
  
  // ✅ FIX: Force reload from disk to get latest values
  await prefs.reload();
  
  final List<String> learnedVocabIds =
      prefs.getStringList('learned_vocab_ids') ?? [];
  final List<String> learnedVerbIds =
      prefs.getStringList('learned_verbs_ids') ?? [];
      
  int count = learnedVocabIds.length + learnedVerbIds.length;
  
  if (mounted) {
    setState(() {
      _learnedWordsCount = count;
    });
  }
}
```

### **Why `reload()` is Needed**:

SharedPreferences caches values in memory. When:
1. Games Hub reads: `learned_vocab_ids = []` (cached empty list)
2. User completes task: Writes `learned_vocab_ids = [5 words]` to disk
3. Games Hub re-opens: Still has cached EMPTY list in memory!

**`prefs.reload()`** forces it to re-read from disk, getting the updated values.

## 🔧 **Additional Improvements**

### **Option A: Listen to Changes (Better UX)**

Instead of only loading on init, listen for changes and auto-refresh:

```dart
class _GamesGridSheetState extends State<GamesGridSheet> {
  StreamSubscription? _prefsSubscription;
  
  @override
  void initState() {
    super.initState();
    _checkDailyUnlock();
    _loadLearnedWordsCount();
    
    // Listen for learned words changes
    _startListeningForChanges();
  }
  
  void _startListeningForChanges() {
    // Poll every 2 seconds while sheet is open
    _prefsSubscription = Stream.periodic(Duration(seconds: 2)).listen((_) {
      if (mounted && _isDailyUnlocked) {
        _loadLearnedWordsCount();
      }
    });
  }
  
  @override
  void dispose() {
    _prefsSubscription?.cancel();
    super.dispose();
  }
}
```

### **Option B: Manual Refresh Button**

Add a refresh icon to let users manually reload:

```dart
IconButton(
  icon: Icon(Icons.refresh),
  onPressed: () {
    _loadLearnedWordsCount();
  },
)
```

## 📊 **Testing**

### **Test Scenario**:

```
1. New user (0 words learned)
2. Open Games Hub
   → Should show: "Learn 4 more words" on Word Match
3. Close Games Hub
4. Complete Daily Vocabulary (5 words)
5. Re-open Games Hub
   → Should show: "✅ Ready" on Word Match (has 5, needs 4)
   → Should show: "Learn 5 more words" on Word Builder (has 5, needs 10)
```

### **Verify Fix**:

```
Before Fix:
- Step 5 shows: "Learn 4 more words" ❌ (WRONG - using cached 0)

After Fix:
- Step 5 shows: "✅ Ready" ✅ (CORRECT - reloaded and found 5)
```

## 🎯 **Files to Modify**

### **Primary Fix**:
- `lib/widgets/games_hub_card.dart` (Line 396-413)
  - Add `await prefs.reload();` at line 397

### **Recommended Additional Fix**:
- Same file, add auto-refresh mechanism for better UX

## 📝 **Code Change**

**File**: `lib/widgets/games_hub_card.dart`

**Before** (Lines 396-413):
```dart
Future<void> _loadLearnedWordsCount() async {
  final prefs = await SharedPreferences.getInstance();

  // Use the EXACT same list that games check (learned_vocab_ids)
  final List<String> learnedVocabIds =
      prefs.getStringList('learned_vocab_ids') ?? [];
  final List<String> learnedVerbIds =
      prefs.getStringList('learned_verbs_ids') ?? [];

  // Count: Each vocab/verb ID = 1 learned word
  int count = learnedVocabIds.length + learnedVerbIds.length;

  if (mounted) {
    setState(() {
      _learnedWordsCount = count;
    });
  }
}
```

**After**:
```dart
Future<void> _loadLearnedWordsCount() async {
  final prefs = await SharedPreferences.getInstance();
  
  // ✅ CRITICAL FIX: Force reload from disk to get latest learned words
  // Without this, SharedPreferences returns cached (stale) values
  await prefs.reload();

  // Use the EXACT same list that games check (learned_vocab_ids)
  final List<String> learnedVocabIds =
      prefs.getStringList('learned_vocab_ids') ?? [];
  final List<String> learnedVerbIds =
      prefs.getStringList('learned_verbs_ids') ?? [];

  // Count: Each vocab/verb ID = 1 learned word
  int count = learnedVocabIds.length + learnedVerbIds.length;
  
  // 🐛 DEBUG LOG (remove after testing)
  debugPrint('📊 Games Hub: Loaded $count learned words (vocab: ${learnedVocabIds.length}, verbs: ${learnedVerbIds.length})');

  if (mounted) {
    setState(() {
      _learnedWordsCount = count;
    });
  }
}
```

## 🎓 **Learning**

**Key Lesson**: Always use `prefs.reload()` when:
- Reading values that might have been updated by other parts of the app
- Reopening a screen/dialog after user activity elsewhere
- Checking for changes made in background/other widgets

**SharedPreferences behavior**:
- **First call** (`getInstance()`): Loads from disk into memory cache
- **Subsequent calls**: Returns cached instance with cached values
- **`reload()`**: Forces re-read from disk, updating cache

## 🚀 **Impact**

**Before Fix**:
- Games show stale word counts
- Users confused: "I learned words but games still locked!"
- Poor UX, feels broken

**After Fix**:
- Games immediately reflect learned words
- Badge updates correctly ("Learn 4 more" → "✅ Ready")
- Users can play unlocked games right away
- Smooth, responsive experience

---

**CRITICAL**: This bug affects ALL game unlock logic! Must fix ASAP!
