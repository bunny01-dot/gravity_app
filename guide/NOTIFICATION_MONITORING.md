# 📊 Notification Delivery Monitoring Guide

## Overview

Lightweight delivery logging has been added to track notification success/failure rates in production.

---

## 📁 Firestore Collection: `notification_logs`

### Document Structure

```javascript
{
  type: "announcement" | "daily_reminder" | "feedback" | "bug_report",
  success: true | false,
  timestamp: Timestamp,
  
  // For announcements:
  topic: "student_announcements",
  messageId: "fcm_message_id",
  sentBy: "teacher_uid",
  important: true,
  
  // For failures:
  error: "error message",
  
  // For daily reminders:
  scheduledTime: "2026-01-15T09:00:00.000Z"
}
```

---

## 📊 Monitoring Queries

### 1. **Daily Reminder Success Rate (Last 7 Days)**

**Firebase Console Query:**
```
Collection: notification_logs
Where: type == "daily_reminder"
Where: timestamp >= [7 days ago]
Order by: timestamp desc
```

**Success Rate Calculation:**
```javascript
const successCount = logs.filter(log => log.success).length;
const totalCount = logs.length;
const successRate = (successCount / totalCount) * 100;

console.log(`Daily Reminder Success Rate: ${successRate}%`);
// Target: >95%
```

### 2. **Announcement Delivery Tracking**

**Recent Announcements:**
```
Collection: notification_logs
Where: type == "announcement"
Order by: timestamp desc
Limit: 50
```

**Failed Announcements:**
```
Collection: notification_logs
Where: type == "announcement"
Where: success == false
Order by: timestamp desc
```

### 3. **Teacher Activity (Who's Sending)**

```
Collection: notification_logs
Where: type == "announcement"
Group by: sentBy
```

---

## 🔍 Firestore Rules (Add to firestore.rules)

```javascript
match /notification_logs/{logId} {
  // Only Cloud Functions can write
  allow create: if false;
  
  // Teachers and admins can read
  allow read: if request.auth != null && 
    (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'teacher' ||
     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
}
```

---

## 📈 Key Metrics to Monitor

| Metric | Query | Target |
|--------|-------|--------|
| Daily Reminder Success Rate | `type == "daily_reminder" && success == true` | >95% |
| Daily Reminder Fires Daily | Count logs per day | 1/day |
| Announcement Success Rate | `type == "announcement" && success == true` | >98% |
| Average Announcements/Week | Count by week | Varies |
| Failed Delivery Count | `success == false` | <5/week |

---

## 🚨 Alert Thresholds

**When to Investigate:**

1. ✅ **Daily Reminder Success Rate < 90%**
   - Check Cloud Scheduler status
   - Verify FCM topic health
   - Review error messages

2. ✅ **No Daily Reminder Log for 2+ Days**
   - Cloud Scheduler may be paused
   - Function may have deployment issue

3. ✅ **Announcement Success Rate < 90%**
   - Check FCM service status
   - Review error patterns
   - Verify teacher permissions

---

## 📊 Sample Query Scripts

### Node.js Script (for admins)

```javascript
const admin = require('firebase-admin');
admin.initializeApp();

async function getDailyReminderStats(days = 7) {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - days);
  
  const snapshot = await admin.firestore()
    .collection('notification_logs')
    .where('type', '==', 'daily_reminder')
    .where('timestamp', '>=', cutoff)
    .get();
  
  const total = snapshot.size;
  const successful = snapshot.docs.filter(doc => doc.data().success).length;
  const failed = total - successful;
  
  console.log(`Daily Reminder Stats (Last ${days} days):`);
  console.log(`  Total: ${total}`);
  console.log(`  Successful: ${successful}`);
  console.log(`  Failed: ${failed}`);
  console.log(`  Success Rate: ${(successful/total*100).toFixed(2)}%`);
  
  return { total, successful, failed, successRate: successful/total };
}

getDailyReminderStats(7);
```

### Check Last 24 Hours

```javascript
async function checkLast24Hours() {
  const cutoff = new Date();
  cutoff.setHours(cutoff.getHours() - 24);
  
  const snapshot = await admin.firestore()
    .collection('notification_logs')
    .where('timestamp', '>=', cutoff)
    .orderBy('timestamp', 'desc')
    .get();
  
  const grouped = {};
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    if (!grouped[data.type]) {
      grouped[data.type] = { success: 0, failed: 0 };
    }
    if (data.success) {
      grouped[data.type].success++;
    } else {
      grouped[data.type].failed++;
    }
  });
  
  console.log('Last 24 Hours Summary:');
  console.table(grouped);
}

checkLast24Hours();
```

---

## 🧹 Data Retention (Optional)

To prevent unbounded growth, set up a cleanup function:

```javascript
// functions/index.js
const { onSchedule } = require("firebase-functions/v2/scheduler");

exports.cleanupOldLogs = onSchedule(
  {
    schedule: "0 0 * * 0", // Weekly on Sunday midnight
    timeZone: "Asia/Kolkata",
  },
  async (event) => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 90); // Keep 90 days
    
    const snapshot = await admin.firestore()
      .collection('notification_logs')
      .where('timestamp', '<', cutoff)
      .limit(500)
      .get();
    
    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    
    await batch.commit();
    console.log(`Deleted ${snapshot.size} old notification logs`);
  }
);
```

---

## 📱 Optional: Flutter Client Tracking

Add to `FCMService` foreground handler:

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Existing logic...
  
  // ✅ Track delivery (optional)
  AnalyticsService().logEvent('notification_received_foreground', {
    'type': message.data['type'] ?? 'unknown',
    'message_id': message.messageId ?? 'unknown',
  });
});
```

---

## ✅ Verification

After deploying, verify logging works:

1. **Send Test Announcement:**
   ```bash
   # From teacher dashboard, send announcement
   ```

2. **Check Firestore:**
   ```bash
   # Firebase Console → Firestore → notification_logs
   # Should see new document with:
   # - type: "announcement"
   # - success: true
   # - messageId: [FCM ID]
   # - timestamp: [now]
   ```

3. **Trigger Daily Reminder:**
   ```bash
   gcloud scheduler jobs run firebase-schedule-dailyStudentReminder-us-central1
   ```

4. **Check Log:**
   ```bash
   # Firestore → notification_logs
   # Should see:
   # - type: "daily_reminder"
   # - success: true
   # - scheduledTime: [ISO timestamp]
   ```

---

## 🎯 Success Criteria

✅ **Logging is Working When:**
- New log appears in Firestore after each notification send
- Success/failure is correctly tracked
- No performance impact on notification delivery
- Logs contain useful debugging info (messageId, error details)

✅ **Production Health Indicators:**
- Daily reminder logs appear every day at 9:00 AM
- Success rate > 95% for daily reminders
- Success rate > 98% for announcements
- Failed notifications have clear error messages

---

## 🚀 Deployment

The logging is already integrated into:
- ✅ `sendAnnouncement` function
- ✅ `dailyStudentReminder` function

Deploy:
```bash
cd functions
firebase deploy --only functions
```

Logging will start automatically!
