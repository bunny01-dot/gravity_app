# Notification History System - Implementation Guide

## 🎯 Problem Summary

**Current Issues:**
1. ❌ Notifications disappear when dismissed (no history)
2. ❌ Same notification shows on every login
3. ❌ No 7-day retention period
4. ❌ No persistent storage

**Required Solution:**
1. ✅ Save all notifications to Firestore user history
2. ✅ Show each notification only once
3. ✅ Auto-delete after 7 days
4. ✅ Keep dismissed notifications in history

---

## 📦 New Service Created

### `lib/services/notification_history_service.dart` ✅

**Key Methods:**
- `saveToHistory()` - Save notification when first received
- `hasReceivedNotification()` - Check if user already saw it
- `markAsRead()` - Mark notification as read
- `markAsDismissed()` - When user swipes away
- `getActiveNotifications()` - Non-dismissed notifications
- `getNotificationHistory()` - All notifications (7-day window)
- `cleanupExpiredNotifications()` - Auto-delete old ones

---

## 🔧 Required Code Changes

### 1. Update FCM Service (`lib/services/fcm_service.dart`)

**Add import:**
```dart
import 'package:gravity_app/services/notification_history_service.dart';
```

**In `init()` method, update the `FirebaseMessaging.onMessage.listen` block:**

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  debugPrint('Got a message whilst in the foreground! ${message.messageId}');
  
  final historyService = NotificationHistoryService();
  final messageId = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  // Check if already received
  final alreadyReceived = await historyService.hasReceivedNotification(messageId);
  if (alreadyReceived) {
    debugPrint('⚠️ Notification already received, skipping: $messageId');
    return;
  }

  // Handle Data Payload
  if (message.data.containsKey('title')) {
    String title = message.data['title'] ?? 'Notification';
    String body = message.data['body'] ?? '';
    String type = message.data['announcement_type'] ?? 'normal';
    bool isImportant = type == 'important';

    // Save to history FIRST
    await historyService.saveToHistory(
      announcementId: messageId,
      title: title,
      message: body,
      type: type,
      receivedAt: DateTime.now(),
    );

    // Then show notification
    _notificationService.showNotification(
      title,
      body,
      isImportant: isImportant,
    );
  } else if (message.notification != null) {
    // Fallback
    await historyService.saveToHistory(
      announcementId: messageId,
      title: message.notification!.title ?? 'Notification',
      message: message.notification!.body ?? '',
      type: 'normal',
      receivedAt: DateTime.now(),
    );

    _notificationService.showNotification(
      message.notification!.title ?? 'New Notification',
      message.notification!.body ?? '',
      isImportant: false,
    );
  }
});
```

---

### 2. Update Dashboard - Check on Login

**In `main.dart` or where you initialize after login:**

```dart
import 'package:gravity_app/services/notification_history_service.dart';

// After successful login, check for new announcements
Future<void> _checkForNewAnnouncements() async {
  final historyService = NotificationHistoryService();
  
  // Cleanup old notifications first
  await historyService.cleanupExpiredNotifications();
  
  // Fetch recent announcements from Firestore
  final snapshot = await FirebaseFirestore.instance
      .collection('announcements')
      .where('timestamp', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))))
      .orderBy('timestamp', descending: true)
      .limit(10)
      .get();

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final announcementId = doc.id;
    
    // Check if already received
    final alreadyReceived = await historyService.hasReceivedNotification(announcementId);
    if (!alreadyReceived) {
      // Save to history
      await historyService.saveToHistory(
        announcementId: announcementId,
        title: data['title'] ?? 'Announcement',
        message: data['message'] ?? '',
        type: data['type'] ?? 'normal',
        receivedAt: (data['timestamp'] as Timestamp).toDate(),
      );

      // Show notification
      final isImportant = data['type'] == 'important';
      await NotificationService().showNotification(
        data['title'] ?? 'Announcement',
        data['message'] ?? '',
        isImportant: isImportant,
      );
    }
  }
}

// Call this after login:
await _checkForNewAnnouncements();
```

---

### 3. Update Notifications Screen

**Replace Firestore announcements stream with notification history:**

**In `lib/screens/notifications_screen.dart`:**

**Add import:**
```dart
import 'package:gravity_app/services/notification_history_service.dart';
```

**Replace the StreamBuilder (line ~156):**

```dart
StreamBuilder<QuerySnapshot>(
  stream: NotificationHistoryService().getActiveNotifications(), // Changed
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Center(
        child: Text(
          "Error loading notifications",
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return _buildEmptyState();
    }

    final docs = snapshot.data!.docs;
    final allVisibleIds = docs.map((d) => d.id).toList();

    return Column(
      children: [
        // ... existing UI code ...
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final id = data['announcementId'] as String; // Changed field
              final isRead = data['readAt'] != null; // Changed logic
              final isSelected = _selectedIds.contains(id);

              return Dismissible(
                key: Key(id),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    // Swipe Right -> Mark Read
                    if (!isRead) {
                      await NotificationHistoryService().markAsRead(id);
                    }
                    return false;
                  } else if (direction == DismissDirection.endToStart) {
                    // Swipe Left -> Dismiss (not delete)
                    await NotificationHistoryService().markAsDismissed(id);
                    return true;
                  }
                  return false;
                },
                child: _buildNotificationItem(doc, data, isRead, isSelected, index),
              );
            },
          ),
        ),
      ],
    );
  },
)
```

**Update `_buildNotificationItem` to use history fields:**

```dart
Widget _buildNotificationItem(
  DocumentSnapshot doc,
  Map<String, dynamic> data,
  bool isRead,
  bool isSelected,
  int index,
) {
  final title = data['title'] ?? 'Notification';
  final message = data['message'] ?? '';
  final timestamp = data['receivedAt'] as Timestamp?; // Changed
  final dateStr = timestamp != null
      ? _formatTimestamp(timestamp.toDate())
      : 'Just now';

  // ... rest of existing code ...
}
```

---

### 4. Update Delete Logic

**When user permanently deletes (not just dismisses):**

```dart
Future<void> _deleteNotification(String id) async {
  await NotificationHistoryService().permanentlyDelete(id);
  setState(() {
    _deletedIds.add(id);
  });
}
```

---

## 🗄️ Firestore Structure

### Collection: `users/{uid}/notification_history/{announcementId}`

```json
{
  "announcementId": "abc123",
  "title": "Important Update",
  "message": "Please check the new curriculum",
  "type": "important",
  "receivedAt": Timestamp,
  "readAt": Timestamp | null,
  "dismissedAt": Timestamp | null,
  "expiresAt": Timestamp  // receivedAt + 7 days
}
```

---

## 🔒 Firestore Security Rules

**Add to `firestore.rules`:**

```javascript
match /users/{userId}/notification_history/{notificationId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  
  // Auto-cleanup rule (enforced by function/client)
  allow delete: if request.auth.uid == userId 
    && resource.data.expiresAt < request.time;
}
```

---

## ⏰ Automatic Cleanup

**Option 1: Cloud Function (Recommended)**

Create `functions/cleanupNotifications.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.cleanupExpiredNotifications = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    
    const usersSnapshot = await db.collection('users').get();
    
    for (const userDoc of usersSnapshot.docs) {
      const historySnapshot = await db
        .collection('users')
        .doc(userDoc.id)
        .collection('notification_history')
        .where('expiresAt', '<', now)
        .get();
      
      const batch = db.batch();
      historySnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      if (!batch.isEmpty) {
        await batch.commit();
        console.log(`Cleaned up ${historySnapshot.size} notifications for user ${userDoc.id}`);
      }
    }
  });
```

**Option 2: Client-side (on app startup)**

```dart
// In main.dart or dashboard initState
await NotificationHistoryService().cleanupExpiredNotifications();
```

---

## ✅ Testing Checklist

- [ ] New notification appears only once
- [ ] Dismissed notification stays in history
- [ ] Can view history in notifications screen
- [ ] Notifications auto-delete after 7 days
- [ ] Re-login doesn't show same notification
- [ ] Swipe left dismisses (keeps in history)
- [ ] Swipe right marks as read
- [ ] Permanent delete removes from history
- [ ] Unread count is accurate

---

## 🐛 Common Issues & Fixes

### Issue: Notifications still appearing on every login
**Cause:** Not checking `hasReceivedNotification()` before showing
**Fix:** Add check in FCM listener and dashboard init

### Issue: Notifications disappear after dismiss
**Cause:** Using old delete logic instead of `markAsDismissed()`
**Fix:** Update swipe dismiss to call `markAsDismissed()`

### Issue: History shows duplicate
notifications
**Cause:** Firestore `announcementId` not matching FCM `messageId`
**Fix:** Use consistent ID (announcement doc ID from Firestore)

---

## 📊 Impact Summary

**Before:**
- ❌ Notifications lost when dismissed
- ❌ Duplicates on every login
- ❌ No history tracking

**After:**
- ✅ 7-day notification history
- ✅ One-time delivery per notification
- ✅ Persistent storage in Firestore
- ✅ Auto-cleanup of old notifications
- ✅ Read/dismissed status tracking

---

**Estimated Implementation Time:** 2-3 hours
**Priority:** High (User Experience Issue)

