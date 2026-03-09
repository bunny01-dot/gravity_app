# Quick Reference: Using TeacherNotificationService

## ✅ Valid Usage Examples

### Example 1: Daily Tasks Completed
```dart
import 'package:gravity_app/services/teacher_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Get current user info
final user = FirebaseAuth.instance.currentUser;
final studentId = user?.uid ?? '';
final studentName = user?.displayName ?? prefs.getString('user_name') ?? '';

// Send notification
await TeacherNotificationService().sendStudentActivityNotification(
  studentId: studentId,
  studentName: studentName,
  activityType: 'daily_tasks_completed',
  details: 'Completed all daily tasks',
);
```

---

### Example 2: Level Completed
```dart
await TeacherNotificationService().sendStudentActivityNotification(
  studentId: userId,
  studentName: userName,
  activityType: 'level_complete',
  details: 'Completed Level 5',
);
```

---

### Example 3: Streak Milestone
```dart
await TeacherNotificationService().sendStudentActivityNotification(
  studentId: userId,
  studentName: userName,
  activityType: 'streak_milestone',
  details: 'reached a 10-day streak!',
);
```

---

### Example 4: Student Needs Help
```dart
await TeacherNotificationService().sendStudentActivityNotification(
  studentId: userId,
  studentName: userName,
  activityType: 'needs_help',
  details: 'Struggling with present tense exercises',
);
```

---

## ❌ Invalid Usage (Will be Rejected)

### ❌ Empty Student Name
```dart
// This will be REJECTED
await TeacherNotificationService().sendStudentActivityNotification(
  studentId: 'user_123',
  studentName: '', // INVALID!
  activityType: 'daily_tasks_completed',
  details: 'Completed tasks',
);

// Console output:
// ❌ INVALID_NOTIFICATION_PAYLOAD: studentName is empty
// Notification NOT sent
```

---

### ❌ Empty Activity Type
```dart
// This will be REJECTED
await TeacherNotificationService().sendStudentActivityNotification(
  studentId: 'user_123',
  studentName: 'Ravi',
  activityType: '', // INVALID!
  details: 'Completed tasks',
);

// Console output:
// ❌ INVALID_NOTIFICATION_PAYLOAD: activityType is empty
// Notification NOT sent
```

---

### ❌ Empty Details
```dart
// This will be REJECTED
await TeacherNotificationService().sendStudentActivityNotification(
  studentId: 'user_123',
  studentName: 'Ravi',
  activityType: 'daily_tasks_completed',
  details: '', // INVALID!
);

// Console output:
// ❌ INVALID_NOTIFICATION_PAYLOAD: details is empty
// Notification NOT sent
```

---

## 📋 Supported Activity Types

| Activity Type | Title | Importance | Example Details |
|--------------|-------|------------|-----------------|
| `daily_tasks_completed` | "✅ Daily Tasks Completed" | Normal | "Completed all daily tasks" |
| `level_complete` | "🎉 Level Completed" | Important | "Completed Level 3" |
| `needs_help` | "🆘 Student Needs Help" | Important | "Struggling with past tense" |
| `streak_milestone` | "🔥 Streak Milestone" | Important | "reached a 7-day streak!" |
| `feedback_submitted` | "💬 New Feedback" | Normal | "Submitted app feedback" |
| `new_student_signup` | "👋 New Student Joined" | Important | "just signed up!" |
| `app_error` | "⚠️ App Issue Detected" | Varies | "Error Category\|severity" |

---

## 🔍 How to Debug Invalid Payloads

### 1. Check Console Logs
```
❌ INVALID_NOTIFICATION_PAYLOAD: studentName is empty
```

### 2. Check Firestore Collection
```
Firestore → notification_errors

Fields:
- error_type: "INVALID_NOTIFICATION_PAYLOAD"
- missing_field: "studentName"
- attempted_student_name: ""
- attempted_activity_type: "daily_tasks_completed"
- timestamp: [current time]
- severity: "medium"
```

### 3. Check Cloud Function Logs
```bash
firebase functions:log --only notifyTeachersOnStudentActivity

# Filter for errors
firebase functions:log --only notifyTeachersOnStudentActivity | grep "INVALID"
```

---

## ✅ Best Practices

### 1. Always Get User Info from Reliable Source
```dart
// ✅ GOOD: Get from SharedPreferences or Firebase Auth
final prefs = await SharedPreferences.getInstance();
final studentName = prefs.getString('user_name') ?? 
                    user?.displayName ?? 
                    user?.email?.split('@')[0] ?? '';

// ❌ BAD: Hardcoded or empty
final studentName = '';
```

---

### 2. Provide Meaningful Details
```dart
// ✅ GOOD: Specific and actionable
details: 'Completed all 3 daily tasks: Vocabulary, Verbs, and Speaking'

// ❌ BAD: Vague
details: 'Task done'
```

---

### 3. Use Correct Activity Types
```dart
// ✅ GOOD: Use supported activity type
activityType: 'daily_tasks_completed'

// ❌ BAD: Made-up activity type
activityType: 'some_random_thing'
// (Will show generic "Student Activity" notification)
```

---

### 4. Validate Before Sending
```dart
// ✅ GOOD: Check before sending
if (studentId.isNotEmpty && studentName.isNotEmpty) {
  await TeacherNotificationService().sendStudentActivityNotification(
    studentId: studentId,
    studentName: studentName,
    activityType: 'level_complete',
    details: 'Completed Level $levelNumber',
  );
}

// ❌ BAD: Send blindly
await TeacherNotificationService().sendStudentActivityNotification(
  studentId: studentId, // Might be empty!
  studentName: studentName, // Might be empty!
  activityType: activityType,
  details: details,
);
```

---

## 🚨 Common Mistakes

### Mistake 1: Using Firebase User Display Name Directly
```dart
// ❌ PROBLEM: user.displayName might be null
final studentName = user?.displayName ?? '';

// ✅ SOLUTION: Multiple fallbacks
final studentName = user?.displayName ?? 
                    prefs.getString('user_name') ?? 
                    user?.email?.split('@')[0] ?? 
                    'Student';
```

---

### Mistake 2: Not Trimming Whitespace
```dart
// ❌ PROBLEM: "  " (spaces) will be rejected
final studentName = '  ';

// ✅ SOLUTION: Service trims automatically, but don't pass whitespace
final studentName = prefs.getString('user_name')?.trim() ?? '';
```

---

### Mistake 3: Assuming Notification Was Sent
```dart
// ❌ BAD: No feedback if rejected
await TeacherNotificationService().sendStudentActivityNotification(...);
// (Might have been rejected silently)

// ✅ GOOD: Check console logs or notification_errors collection
debugPrint("Attempting to send notification for $studentName");
await TeacherNotificationService().sendStudentActivityNotification(...);
// Check console for "✅ Teacher Notification Sent" or "❌ INVALID_NOTIFICATION_PAYLOAD"
```

---

## 📊 Expected Results

### When Valid:
- ✅ Console: `"✅ Teacher Notification Sent: [activityType] for [studentName]"`
- ✅ Firestore: Document created in `teacher_notifications` collection
- ✅ Cloud Function: Triggers and sends push notification
- ✅ Teacher: Receives notification on device

### When Invalid:
- ❌ Console: `"❌ INVALID_NOTIFICATION_PAYLOAD: [field] is empty"`
- ❌ Firestore: Document created in `notification_errors` collection
- ❌ Cloud Function: Does NOT trigger
- ❌ Teacher: Does NOT receive notification

---

## 🔗 Related Files

- Service implementation: `lib/services/teacher_notification_service.dart`
- Cloud Function: `functions/index.js` (line 443+)
- Documentation: `guide/fix_unknown_student_activity.md`
- Summary: `guide/fix_unknown_student_activity_summary.md`
