# Technical Issue Reporting - System Documentation

**Date**: 2026-01-23  
**Status**: ✅ Working as Designed

---

## 📍 **Where Are Technical Issues Stored?**

Technical issues are stored in **TWO separate Firestore collections**:

### 1. **`app_errors`** Collection (Full Technical Details)
- **Location**: Firebase Firestore → `app_errors` collection
- **Purpose**: Stores complete error details for developers
- **Access**: Anyone with Firestore access (Firebase Console)
- **Fields**:
  - `studentId`: Student's UID
  - `studentName`: Student's display name
  - `errorMessage`: Complete error message
  - `stackTrace`: Full stack trace
  - `category`: User-friendly error type
  - `severity`: high/medium/low
  - `timestamp`: When the error occurred
  - `platform`: "Flutter"
  - `resolved`: false by default

### 2. **`teacher_notifications`** Collection (Simplified Alerts)
- **Location**: Firebase Firestore → `teacher_notifications` collection
- **Purpose**: Shows simplified notifications to teachers in-app
- **Access**: Teachers via the Teacher Dashboard notification system
- **Fields**:
  - `studentId`: Student's UID
  - `studentName`: Student's display name  
  - `activityType`: "app_error"
  - `details`: "Technical Issue|medium" (category|severity)
  - `timestamp`: When notification was created
  - `read`: false by default

---

## 🔍 **How to View Technical Issues**

### **Option 1: Firebase Console (Recommended for Full Details)**
1. Go to Firebase Console → Your Project
2. Navigate to **Firestore Database**
3. Open **`app_errors`** collection
4. Filter by:
   - `studentName` = "Bunny"
   - `resolved` = false
   - Sort by `timestamp` (descending)

### **Option 2: Teacher Dashboard (In-App)**
1. Go to **Settings** tab
2. Tap **"Technical Issues (Debug)"**
3. View full list of errors + stack traces

### **Option 3: Teacher Dashboard (Notifications)**
1. Login as a teacher
2. Click the notification bell icon
3. Look for "Technical Issue" alerts

---

## ❓ **Why Can't Teachers See Full Details?**

**By Design**: Teachers see **simplified notifications** to avoid overwhelming them with technical jargon.

- **Teachers See**: "Technical Issue from Bunny" (user-friendly)
- **Developers See**: Full stack trace + error message (in `app_errors` collection)

This is intentional to keep the teacher dashboard clean and actionable.

---

## 🚨 **Who Receives These Notifications?**

### **Current Behavior:**
✅ **Teachers Only** - Notifications go to `teacher_notifications` collection  
❌ **Students Do NOT receive** - No student notification system for errors

### **How It Works:**
1. Student's app crashes/errors
2. `_reportErrorToTeacher()` in `main.dart` (line 105) is called
3. Creates TWO records:
   - **`app_errors`**: Full technical log
   - **`teacher_notifications`**: Simplified alert for teachers
4. Teachers see the notification in their dashboard
5. Students see nothing (error is logged silently)

### **Code Location:**
- File: `lib/main.dart`
- Function: `_reportErrorToTeacher()` (lines 105-145)
- Notification Service: `lib/services/teacher_notification_service.dart`

---

## 🛠️ **How to Solve/Manage Issues**

### **Step 1: View the Error**
```
Firebase Console → Firestore → app_errors →
Filter: studentName == "Bunny" && resolved == false
```

### **Step 2: Analyze the Error**
Check these fields:
- `category`: What type of issue? (UI Layout, Network, Data Sync, etc.)
- `severity`: How serious? (high/medium/low)
- `errorMessage`: What went wrong?
- `stackTrace`: Where in the code?

### **Step 3: Mark as Resolved**
After fixing, update the document:
```
Firebase Console → app_errors → [document] →
Set resolved = true
```

### **Step 4: (Optional) Add Resolution Notes**
Add a new field:
```
resolution_notes: "Fixed layout overflow in lesson screen"
resolved_at: [timestamp]
resolved_by: "Teacher/Developer Name"
```

---

## 🔧 **Common Error Categories**

Based on `_categorizeError()` in `main.dart`:

| Category | Trigger Keywords | Typical Cause |
|----------|-----------------|---------------|
| **UI Layout Issue** | renderflex, overflow, viewport | Screen content too large |
| **Network Connection Issue** | network, socket, connection | Internet connectivity |
| **Data Sync Issue** | firebase, firestore | Cloud sync problems |
| **Data Processing Issue** | null, type | Missing/wrong data format |
| **Permission Issue** | permission, denied | Missing app permissions |
| **Data Format Issue** | format, parse | Invalid data structure |
| **Technical Issue** | (fallback) | Miscellaneous errors |

---

## 📊 **Severity Levels**

| Severity | Trigger Keywords | Priority |
|----------|-----------------|----------|
| **High** | exception, fatal, crash | Fix immediately |
| **Medium** | network, timeout, state | Fix soon |
| **Low** | overflow, render, layout | Monitor/fix when convenient |

---

## 🔒 **Security Note**

**Students CANNOT see error reports** - They are sent silently in the background.  
**Only teachers and Firebase admins** can access this information.

---

## ✅ **Quick Fix Checklist**

When you receive a "Technical Issue" notification:

1. ☐ Open Firebase Console → `app_errors`
2. ☐ Find the error for that student
3. ☐ Check `category` and `severity`
4. ☐ Read `errorMessage` and `stackTrace`
5. ☐ If it's a known issue, mark `resolved = true`
6. ☐ If it's critical, contact the developer
7. ☐ If it's low priority, log it for later

---

## 📝 **Example Error Document**

```json
{
  "studentId": "abc123xyz",
  "studentName": "Bunny",
  "errorMessage": "RenderFlex overflowed by 45 pixels on the right",
  "stackTrace": "...",
  "category": "UI Layout Issue",
  "severity": "low",
  "timestamp": "2026-01-23T22:00:00Z",
  "platform": "Flutter",
  "resolved": false
}
```

Corresponding notification in `teacher_notifications`:
```json
{
  "studentId": "abc123xyz",
  "studentName": "Bunny",
  "activityType": "app_error",
  "details": "UI Layout Issue|low",
  "timestamp": "2026-01-23T22:00:00Z",
  "read": false
}
```

---

## 🚀 **Future Improvements** (Optional)

1. Add a "Technical Issues" tab in Teacher Dashboard
2. Show top 10 recent errors with links to Firebase
3. Add "Acknowledge" button to mark as read
4. Filter by severity/category
5. Export error reports as CSV
