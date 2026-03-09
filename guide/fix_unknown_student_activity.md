# Fix: "Unknown Student Activity" Teacher Notifications

## Problem Statement

Teachers receive vague notifications like:
```
📚 Student Activity
Unknown Student performed activity (unknown): No details provided.
```

This creates confusion and provides no actionable insight.

## Root Cause Analysis

### Issue 1: Missing Payload Validation
The `TeacherNotificationService` requires fields to be passed but **doesn't validate** if they're empty/null before sending to Firestore.

**Current Code** (`lib/services/teacher_notification_service.dart`):
```dart
Future<void> sendStudentActivityNotification({
  required String studentId,
  required String studentName,
  required String activityType,
  required String details,
}) async {
  try {
    await _firestore.collection('teacher_notifications').add({
      'studentId': studentId,
      'studentName': studentName,
      'activityType': activityType,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  } catch (e) {
    debugPrint("Error sending teacher notification: $e");
  }
}
```

**Problem**: Even if `studentName = ""` or `activityType = ""`, the notification is sent.

### Issue 2: Cloud Function Falls Back Silently
**Cloud Function** (`functions/index.js`, line 473-475):
```javascript
const studentName = data.studentName && data.studentName.trim() 
    ? data.studentName.trim() 
    : 'Unknown Student';

const activityType = data.activityType || 'unknown';
const details = data.details && data.details.trim() 
    ? data.details.trim() 
    : 'No details provided';
```

**Problem**: Instead of rejecting invalid payloads, it substitutes with fallback text.

### Issue 3: No Centralized Validation
Different parts of the app create `teacher_notifications` documents:
- `TeacherNotificationService` (designed for student activities)
- `dashboard.dart` line 2242 (task completions)
- `data_service.dart` line 1724 (quiz results)

Each has different field names and no validation.

---

## Solution: Enforce Mandatory Payload Validation

### ✅ Step 1: Update `TeacherNotificationService` with Validation

**File**: `lib/services/teacher_notification_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TeacherNotificationService {
  static final TeacherNotificationService _instance =
      TeacherNotificationService._internal();
  factory TeacherNotificationService() => _instance;
  TeacherNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends a notification to the teacher dashboard about a student's activity.
  ///
  /// ✅ VALIDATION ENFORCED:
  /// - All required fields must be non-empty
  /// - Invalid payloads are logged but NOT sent
  ///
  /// [studentId]: The UID of the student (required, non-empty)
  /// [studentName]: The display name of the student (required, non-empty)
  /// [activityType]: Category of event (required, non-empty)
  /// [details]: Specific message or data about the event (required, non-empty)
  Future<void> sendStudentActivityNotification({
    required String studentId,
    required String studentName,
    required String activityType,
    required String details,
  }) async {
    // ✅ VALIDATION: Check if all required fields are non-empty
    if (studentId.trim().isEmpty) {
      debugPrint("❌ INVALID_NOTIFICATION_PAYLOAD: studentId is empty");
      _logInvalidPayload('studentId', studentId, activityType);
      return; // Do NOT send notification
    }

    if (studentName.trim().isEmpty) {
      debugPrint("❌ INVALID_NOTIFICATION_PAYLOAD: studentName is empty");
      _logInvalidPayload('studentName', studentName, activityType);
      return; // Do NOT send notification
    }

    if (activityType.trim().isEmpty) {
      debugPrint("❌ INVALID_NOTIFICATION_PAYLOAD: activityType is empty");
      _logInvalidPayload('activityType', studentName, activityType);
      return; // Do NOT send notification
    }

    if (details.trim().isEmpty) {
      debugPrint("❌ INVALID_NOTIFICATION_PAYLOAD: details is empty");
      _logInvalidPayload('details', studentName, activityType);
      return; // Do NOT send notification
    }

    // ✅ All validations passed - send notification
    try {
      await _firestore.collection('teacher_notifications').add({
        'studentId': studentId.trim(),
        'studentName': studentName.trim(),
        'activityType': activityType.trim(),
        'details': details.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      debugPrint("✅ Teacher Notification Sent: $activityType for $studentName");
    } catch (e) {
      debugPrint("❌ Error sending teacher notification: $e");
    }
  }

  /// Logs invalid notification attempts to Firestore for debugging
  Future<void> _logInvalidPayload(
    String missingField,
    String studentName,
    String activityType,
  ) async {
    try {
      await _firestore.collection('notification_errors').add({
        'error_type': 'INVALID_NOTIFICATION_PAYLOAD',
        'missing_field': missingField,
        'attempted_student_name': studentName,
        'attempted_activity_type': activityType,
        'timestamp': FieldValue.serverTimestamp(),
        'severity': 'medium',
      });
    } catch (e) {
      // Don't let logging errors break the app
      debugPrint("Failed to log invalid payload: $e");
    }
  }
}
```

---

### ✅ Step 2: Update Cloud Function to Reject Invalid Payloads

**File**: `functions/index.js` (Line 455-602)

**Before**: Accepts and processes incomplete data with fallbacks.

**After**:
```javascript
exports.notifyTeachersOnStudentActivity = onDocumentCreated("teacher_notifications/{docId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        console.log("No data associated with teacher notification event");
        return;
    }

    const data = snapshot.data();

    // ✅ VALIDATION: Reject if critical fields are missing
    const studentId = data.studentId?.trim();
    const studentName = data.studentName?.trim();
    const activityType = data.activityType?.trim();
    const details = data.details?.trim();

    if (!studentId) {
        console.error("❌ INVALID_NOTIFICATION_PAYLOAD: studentId missing");
        await logInvalidNotification("studentId", data);
        return; // Do NOT send notification
    }

    if (!studentName) {
        console.error("❌ INVALID_NOTIFICATION_PAYLOAD: studentName missing");
        await logInvalidNotification("studentName", data);
        return; // Do NOT send notification
    }

    if (!activityType) {
        console.error("❌ INVALID_NOTIFICATION_PAYLOAD: activityType missing");
        await logInvalidNotification("activityType", data);
        return; // Do NOT send notification
    }

    if (!details) {
        console.error("❌ INVALID_NOTIFICATION_PAYLOAD: details missing");
        await logInvalidNotification("details", data);
        return; // Do NOT send notification
    }

    // ✅ Enhanced logging for valid data
    console.log("📬 Valid teacher notification triggered:");
    console.log("  Student ID:", studentId);
    console.log("  Student Name:", studentName);
    console.log("  Activity Type:", activityType);
    console.log("  Details:", details);

    // ... rest of the function (formatting and sending notification)
});

/**
 * Logs invalid notification attempts
 */
async function logInvalidNotification(missingField, data) {
    try {
        await admin.firestore().collection('notification_errors').add({
            error_type: 'INVALID_NOTIFICATION_PAYLOAD',
            missing_field: missingField,
            received_data: data,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            severity: 'medium',
        });
    } catch (error) {
        console.error('Error logging invalid notification:', error);
    }
}
```

---

### ✅ Step 3: Update Fallback Text (Only for Profile Fetch Failures)

**Current**: `"Unknown Student"` is used when data is missing.

**After**: Use `"Unknown Student"` ONLY if:
- `studentId` exists (valid)
- `studentName` is missing or empty (profile fetch failed)

**Cloud Function Update**:
```javascript
// If studentId exists but name is missing, it means profile fetch failed
if (studentId && !studentName) {
    studentName = "Student profile unavailable";
    console.warn(`⚠️ Profile unavailable for studentId: ${studentId}`);
}
```

---

## Implementation Checklist

- [ ] Update `lib/services/teacher_notification_service.dart` with validation
- [ ] Update `functions/index.js` to reject invalid payloads
- [ ] Add `logInvalidNotification` helper function
- [ ] Deploy Cloud Functions
- [ ] Test with empty fields to verify rejection
- [ ] Verify Firestore `notification_errors` collection logs invalid attempts

---

## Testing Plan

### Test 1: Valid Payload
```dart
TeacherNotificationService().sendStudentActivityNotification(
  studentId: 'user_123',
  studentName: 'Ravi Kumar',
  activityType: 'daily_tasks_completed',
  details: 'Completed all daily tasks',
);
```

**Expected**:
- ✅ Notification sent to Firestore
- ✅ Cloud Function triggers and sends push notification
- ✅ Teacher receives: "✅ Daily Tasks Completed - Ravi Kumar completed all daily tasks!"

---

### Test 2: Missing `studentName`
```dart
TeacherNotificationService().sendStudentActivityNotification(
  studentId: 'user_123',
  studentName: '', // Empty!
  activityType: 'daily_tasks_completed',
  details: 'Completed all daily tasks',
);
```

**Expected**:
- ❌ Notification NOT sent to Firestore
- ✅ Log: `"❌ INVALID_NOTIFICATION_PAYLOAD: studentName is empty"`
- ✅ Error logged to `notification_errors` collection

---

### Test 3: Missing `activityType`
```dart
TeacherNotificationService().sendStudentActivityNotification(
  studentId: 'user_123',
  studentName: 'Ravi Kumar',
  activityType: '', // Empty!
  details: 'Completed all daily tasks',
);
```

**Expected**:
- ❌ Notification NOT sent to Firestore
- ✅ Log: `"❌ INVALID_NOTIFICATION_PAYLOAD: activityType is empty"`

---

### Test 4: Profile Fetch Failure (Mock)
Simulate a scenario where `studentId` exists but profile couldn't be loaded:

**Cloud Function Receives**:
```json
{
  "studentId": "user_456",
  "studentName": "",
  "activityType": "level_complete",
  "details": "Completed Level 3"
}
```

**Expected**:
- ❌ Notification NOT sent (validation fails on app side)
- ✅ `TeacherNotificationService` rejects before sending to Firestore

---

## Deployment

```bash
cd e:\Apps\gravity_app

# Deploy updated Cloud Functions
firebase deploy --only functions:notifyTeachersOnStudentActivity

# View logs
firebase functions:log --only notifyTeachersOnStudentActivity
```

---

## Summary

**Before**:
- ❌ Empty fields sent to Cloud Function
- ❌ Vague "Unknown Student performed activity (unknown): No details provided"
- ❌ No validation, no logging

**After**:
- ✅ Mandatory validation in `TeacherNotificationService`
- ✅ Invalid payloads logged to `notification_errors` collection
- ✅ Cloud Function rejects incomplete data
- ✅ Clear error messages: `"Student profile unavailable"` only when profile fetch fails
- ✅ No more vague notifications
