# Fix: "Unknown Student" in Teacher Notifications

## Problem
Teachers were receiving notifications showing "unknown student" or "Student" instead of actual student names.

## Root Cause
The code was using `user.displayName` from Firebase Auth, which is often `null` because:
1. Firebase Auth's `displayName` is not automatically set during account creation
2. Students sign up with email/password (not Google/Facebook), so `displayName` remains null
3. Student names are stored in SharedPreferences (`user_name` key) and Firestore, not in Firebase Auth

## Solution
Updated all places where `sendStudentActivityNotification()` is called to retrieve the student name using this priority order:

1. **SharedPreferences** (`user_name`) - Most reliable, set during signup
2. **Firebase Auth displayName** - Fallback if available
3. **Email prefix** - Extract name before @ symbol
4. **"Student"** - Last resort fallback

### Code Pattern
```dart
final prefs = await SharedPreferences.getInstance();
final studentName = prefs.getString('user_name') ?? 
                   user.displayName ?? 
                   user.email?.split('@')[0] ?? 
                   'Student';
```

## Files Modified

### 1. `lib/dashboard.dart` (Lines 1348-1351)
**Location**: Daily tasks completion notification

**Before**:
```dart
studentName: user.displayName ?? 'Student',
```

**After**:
```dart
studentName: prefs.getString('user_name') ?? 
             user.displayName ?? 
             user.email?.split('@')[0] ?? 
             'Student',
```

### 2. `lib/main.dart` (Lines 104-120)
**Location**: Global error reporting

**Before**:
```dart
void _reportErrorToTeacher(dynamic error, StackTrace? stack) {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    TeacherNotificationService().sendStudentActivityNotification(
      studentId: user.uid,
      studentName: user.displayName ?? 'Student',
      activityType: 'app_error',
      details: 'Error: $error',
    );
  }
}
```

**After**:
```dart
void _reportErrorToTeacher(dynamic error, StackTrace? stack) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Get student name from SharedPreferences (more reliable)
    final prefs = await SharedPreferences.getInstance();
    final studentName = prefs.getString('user_name') ?? 
                       user.displayName ?? 
                       user.email?.split('@')[0] ?? 
                       'Student';
    
    TeacherNotificationService().sendStudentActivityNotification(
      studentId: user.uid,
      studentName: studentName,
      activityType: 'app_error',
      details: 'Error: $error',
    );
  }
}
```

**Note**: Made function `async` to allow `await` for SharedPreferences

### 3. `lib/auth/signup_screen.dart` (Line 77)
**Status**: ✅ Already correct!

This file already passes the name correctly from the signup form:
```dart
studentName: _nameController.text.trim(),
```

## Other Locations Checked

All other uses of `sendStudentActivityNotification()` were verified:
- `lib/screens/lesson_subjects_screen.dart` - Uses proper student name
- `lib/mastery/speaking_screen.dart` - Uses proper student name
- `lib/features/dashboard/widgets/settings_tab.dart` - Uses proper student name

## Why SharedPreferences is More Reliable

1. **Set During Signup**: When students sign up, their name is immediately saved:
   ```dart
   await prefs.setString('user_name', _nameController.text.trim());
   ```

2. **Synced from Firestore**: Dashboard loads name from Firestore and saves to SharedPreferences:
   ```dart
   final dbName = data['name'];
   prefs.setString('user_name', dbName);
   ```

3. **Always Available**: Persists locally, doesn't depend on network or auth state

4. **Firebase Auth displayName**: Only set if you explicitly call `updateProfile()`, which we don't do

## Testing

After this fix, teacher notifications will show:
- ✅ "Ravi completed all daily tasks!" (instead of "Student completed...")
- ✅ "Priya completed a new level!" (instead of "unknown student...")
- ✅ "Arjun: Error occurred" (instead of "Student: Error...")

## Deployment

No Cloud Function changes needed - this is purely client-side fix.

```bash
# Just rebuild and run the app
flutter clean
flutter pub get
flutter run
```

## Summary

**Before**: Teachers saw "Student" or "unknown student" in notifications  
**After**: Teachers see actual student names (Ravi, Priya, Arjun, etc.)  
**Fix**: Retrieve name from SharedPreferences with multiple fallbacks  
**Impact**: Better teacher experience, easier to identify which student did what  
