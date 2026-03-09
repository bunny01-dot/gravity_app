# Daily Verb Deduplication & Mastery Tracking

## Issues to Fix
1. ❌ Duplicate verbs appearing in daily tasks (e.g., "Forgo, Forewent, Foregone")
2. ❌ No exclusion of mastered words from daily assignments
3. ❌ Same words assigned to all users (not truly random per user)
4. ⏸️ Need "Mega Quiz" placeholder for future implementation

## Root Cause
The current `getVerbsForDate()` method:
- Uses Set for picking indices but doesn't prevent semantically duplicate words
- Doesn't check quiz history to exclude mastered words
- Seed is date-based, so same date = same words for all users

## Solution Design

### 1. Prevent Duplicate Verbs
**Problem:** Verbs CSV has related forms as separate rows:
- Row 45: Forgo, Forwent, Forgone
- Row 46: Forgo, Forwent, Forgone (duplicate)

**Fix:**
```dart
// In _loadVerbData(), deduplicate by checking first column (base verb)
Set<String> seenBaseVerbs = {};
List<List<dynamic>> uniqueVerbs = [];
for (var row in csvData) {
  String baseVerb = row.length > 1 ? row[1].toString().split(',')[0].trim() : '';
  if (!seenBaseVerbs.contains(baseVerb)) {
    seenBaseVerbs.add(baseVerb);
    uniqueVerbs.add(row);
  }
}
_cachedVerbData = uniqueVerbs;
```

### 2. Exclude Mastered Words
**Tracking:** Store correctly-answered words in SharedPreferences
```dart
// After quiz completion
await prefs.setStringList('mastered_vocab', masteredWords);
await prefs.setStringList('mastered_verbs', masteredVerbs);
```

**Filter during daily selection:**
```dart
Future<List<int>> _getAvailableIndices(String type) async {
  final prefs = await SharedPreferences.getInstance();
  final mastered = prefs.getStringList('mastered_$type') ?? [];
  
  List<int> available = [];
  for (int i = 0; i < data.length; i++) {
    String word = data[i][1].toString();
    if (!mastered.contains(word)) {
      available.add(i);
    }
  }
  return available;
}
```

### 3. True Per-User Randomization
**Current:** `Random(date.millisecondsSinceEpoch)` - same for all users
**Fix:** Add user UID to seed
```dart
final user = FirebaseAuth.instance.currentUser;
final seed = date.millisecondsSinceEpoch + (user?.uid.hashCode ?? 0);
final random = Random(seed);
```

### 4. Mega Quiz Card (Quick Win)
Add placeholder card to teacher dashboard showing:
- Title: "Mega Quiz"
- Subtitle: "Coming Soon - Comprehensive Assessment"
- Icon: quiz_rounded
- Status: "Planned Feature"

## Implementation Priority
1. ✅ **NOW:** Add Mega Quiz placeholder card (5 min)
2. 🔧 **NEXT:** Deduplicate verbs in _loadVerbData (15 min)
3. 🔧 **LATER:** Implement mastery tracking system (1 hour)
4. 🔧 **LATER:** Per-user randomization (10 min)

## Files to Modify
- `lib/services/data_service.dart` - add deduplication, mastery filtering
- `lib/features/dashboard/widgets/home_tab.dart` - add Mega Quiz card for teachers
- `lib/screens/daily_review_screen.dart` - track mastered words after quiz
