# Debug Report Service - Implementation Guide

**Created**: 2026-01-21  
**Purpose**: Capture all errors, exceptions, warnings, and console errors to Firestore debug channel

---

## 📋 Overview

The `DebugReportService` automatically captures and reports all errors to Firestore under `system/debug_reports/reports` for teacher/developer access only.

---

## 🎯 What Gets Captured

### **1. Flutter Errors**
- Widget build errors
- Render errors
- Assertion failures
- Layout errors

### **2. Exceptions**
- Uncaught exceptions
- Async errors
- Network errors
- Database errors

### **3. Warnings**
- Non-fatal issues
- Deprecation warnings
- Performance warnings

### **4. Console Errors**
- Debug print errors
- Custom error logs

---

## 🚀 Quick Start

### **Step 1: Update `pubspec.yaml`**

Add required dependencies:

```yaml
dependencies:
  device_info_plus: ^10.1.2
  package_info_plus: ^8.1.0
  
  # Already have:
  cloud_firestore: ^6.1.1
  firebase_auth: ^6.1.2
```

### **Step 2: Update `main.dart`**

Replace existing `main()` with error-reporting wrapper:

```dart
import 'package:gravity_app/services/debug_report_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ NEW: Run app with error reporting
  runAppWithErrorReporting(const MyApp());
}
```

**Before**:
```dart
void main() {
  runApp(const MyApp());
}
```

**After**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(/* ... */);
  
  runAppWithErrorReporting(const MyApp());  // ✅ Wraps app with error zone
}
```

---

## 📖 Usage Examples

### **1. Report Exceptions**

```dart
try {
  await riskyOperation();
} catch (e, stackTrace) {
  DebugReportService().reportException(
    e,
    stackTrace: stackTrace,
    context: 'Failed to load user data',
    additionalData: {'userId': user.uid},
  );
}
```

### **2. Report Warnings**

```dart
DebugReportService().reportWarning(
  'Quiz CSV has missing columns',
  context: 'DataService.getRawQuizData',
  additionalData: {'csvPath': 'assets/quiz.csv'},
);
```

### **3. Report Console Errors**

```dart
DebugReportService().reportConsoleError(
  'Network timeout after 30 seconds',
  context: 'API.fetchData',
  additionalData: {'endpoint': '/api/lessons'},
);
```

### **4. Safe Wrappers (Automatic Error Reporting)**

**Async**:
```dart
final data = await DebugReportService().safe(
  () => fetchDataFromFirebase(),
  context: 'Loading lessons',
  fallbackValue: [],  // Return this if error occurs
);
```

**Sync**:
```dart
final count = DebugReportService().safeSync(
  () => parseIntFromString(input),
  context: 'Parsing score',
  fallbackValue: 0,
);
```

---

## 🗄️ Firestore Structure

**Collection Path**: `system/debug_reports/reports`

**Document Structure**:
```javascript
{
  // Error Details
  "type": "Exception",           // FlutterError, Exception, Warning, ConsoleError, Debug
  "severity": "error",           // error | warning | info
  "message": "Network error...", // Error message
  "stackTrace": "...",          // Full stack trace
  "context": "Loading lessons", // Where it happened
  "library": "flutter",         // Library that caused error
  
  // User Context
  "userId": "abc123",
  "userEmail": "student@example.com",
  "userName": "John Doe",
  
  // Device & App Context
  "deviceInfo": "Android 14 (SDK 34) - Pixel 7",
  "appVersion": "1.2.3",
  "buildNumber": "42",
  "platform": "android",
  
  // Timing
  "timestamp": Timestamp,        // Server timestamp
  "clientTimestamp": "2026-01-21T...",
  
  // Additional Data
  "additionalData": {
    "userId": "abc123",
    "lessonId": "lesson_1",
    // Any custom data
  },
  
  // Status
  "resolved": false,             // Has been fixed?
  "viewedBy": []                 // Array of admin UIDs who viewed
}
```

---

## 🔒 Security Rules (Firestore)

Add these rules to ensure only teachers/admins can access debug reports:

```javascript
match /system/debug_reports/reports/{reportId} {
  // Only allow the app to write (authenticated users)
  allow create, update: if request.auth != null;
  
  // Only teachers/admins can read
  allow read: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
}
```

---

## 🎨 Teacher/Admin Dashboard (Future Enhancement)

Create a dashboard to view debug reports:

```dart
// Example query for teachers
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
    .collection('system')
    .doc('debug_reports')
    .collection('reports')
    .orderBy('timestamp', descending: true)
    .limit(50)
    .snapshots(),
  builder: (context, snapshot) {
    // Display reports in a table/list
  },
)
```

---

## 📊 Benefits

### **For Developers**:
- ✅ Automatic error capture (no manual logging needed)
- ✅ Full stack traces for debugging
- ✅ Device and app context for reproduction
- ✅ Centralized error tracking

### **For Teachers**:
- ✅ See when students encounter errors
- ✅ Understand app stability
- ✅ Report patterns to developers

### **For Students**:
- ✅ Errors are silently reported (no disruption)
- ✅ App continues to work (graceful degradation)
- ✅ Better support when issues occur

---

## 🔍 Error Severity Levels

| Severity | Type | Example |
|----------|------|---------|
| **error** | FlutterError, Exception | Crash, unhandled error |
| **warning** | Warning | Missing data, deprecated API |
| **info** | Debug | User action, state change (debug mode only) |

---

## ✅ Testing

### **Manual Test**:

```dart
// Add this to a test button
ElevatedButton(
  onPressed: () {
    DebugReportService().reportException(
      Exception('Test error from ${user.email}'),
      context: 'Manual test',
      additionalData: {'testRun': DateTime.now().toString()},
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error report sent!')),
    );
  },
  child: Text('Test Error Reporting'),
)
```

### **Check Firestore**:
1. Open Firebase Console
2. Navigate to Firestore
3. Go to `system` → `debug_reports` → `reports`
4. Verify new document was created

---

## 🚨 Important Notes

1. **Privacy**: Reports include user email/ID - ensure GDPR compliance
2. **Performance**: Reports are sent asynchronously (non-blocking)
3. **Offline**: Reports queue when offline, send when back online
4. **Debug Mode**: Extra verbose logging in debug mode, silent in production
5. **Storage**: Set up Firestore retention policy to auto-delete old reports

---

## 🔄 Migration Checklist

- [ ] Add dependencies to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Update `main.dart` with `runAppWithErrorReporting()`
- [ ] Add Firestore security rules
- [ ] Test error reporting with manual error
- [ ] Verify reports appear in Firestore
- [ ] (Optional) Create teacher dashboard for viewing reports

---

## 📝 Example: Replacing Manual Error Handling

**Before**:
```dart
try {
  await loadData();
} catch (e) {
  debugPrint('Error loading data: $e');  // Only logs to console
  // Error lost forever after app closes
}
```

**After**:
```dart
try {
  await loadData();
} catch (e, stackTrace) {
  DebugReportService().reportException(
    e,
    stackTrace: stackTrace,
    context: 'Loading data in DashboardScreen',
  );
  // Now logged to Firestore + console, accessible to teachers
}
```

**Or even simpler**:
```dart
final data = await DebugReportService().safe(
  () => loadData(),
  context: 'Loading data in DashboardScreen',
  fallbackValue: [],
);
// Automatically catches and reports errors, returns [] on failure
```

---

**Status**: ✅ **SERVICE CREATED - READY FOR INTEGRATION**

Next steps: Update `pubspec.yaml` and `main.dart` to enable service!
