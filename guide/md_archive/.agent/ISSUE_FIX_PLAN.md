# Data Integrity & Notification Fixes - Implementation Plan

## Issue Summary
This document outlines the fixes for 4 critical issues related to data integrity (vocabulary history) and notifications (permissions, teacher self-notifications, and UX animations).

---

## Issue 1: Vocabulary History Counting Incorrect Words ❌

### Problem
Vocabulary History is counting **assigned** words as "learned" instead of only counting **completed/earned** words.

### Current Implementation Analysis
- **File**: `lib/screens/vocabulary_history_screen.dart`
- **Problem**: `_load Vocabulary History()` at line 38-78 loads ALL vocabulary for a date from `vocab_$dateKey` keys
- The logic checks `if (prefs.containsKey(key))` which includes **assigned** words, not just **completed** ones
- Words are counted as soon as they're assigned (`totalWords += words.length` at line 58)

### Root Cause
- No distinction between "assigned" and "learned/completed" vocabulary
- The app tracks `vocab_$dateKey` for assignments but doesn't track completion status per word
- Need separate tracking for `learned_vocab_$dateKey` (what EXISTS in `day_based_progress_service.dart`)

### Solution
1. **Use `learned_vocab_$dateKey` instead of `vocab_$dateKey`** for vocabulary history
2. Update `_loadVocabularyHistory()` to only count words from the learned list
3. Ensure streak calculation also uses learned words only
4. Cross-reference with `day_based_progress_service.dart` which already tracks learned vocab per date

### Files to Modify
- `lib/screens/vocabulary_history_screen.dart` - Update data loading logic
- Potentially `lib/services/data_service.dart` - Create helper method to get learned words history

---

## Issue 2: Students Not Receiving Teacher Notifications 🔔

### Problem
Students do not receive notifications sent by teachers, possibly due to:
- Permission issues (user allows "while using app" but system shows OFF)
- Missing runtime permission checks
- No user guidance for enabling notifications

### Current Implementation Analysis
- **Notification Service**: `lib/services/notification_service.dart`
- **FCM Service**: `lib/services/fcm_service.dart`
- Permissions are requested in `init()` but there's NO:
  - Follow-up check if permission was actually granted
  - User tutorial/guide for enabling notifications
  - Detection of permission state changes
  - Deep-linking to settings

### Solution
1. **Add Permission State Detection**
   - Check actual permission status after init
   - Detect if permissions are denied/permanently denied
   - Add method to check current permission state

2. **Create Notification Permission Tutorial**
   - Create a new tutorial screen/dialog
   - Show step-by-step guide with screenshots/illustrations
   - Include deep-link button to app notification settings
   - Trigger when permission is denied or notifications fail

3. **Add Runtime Permission Checks**
   - Before sending notifications, verify permissions
   - Show contextual prompt if disabled
   - Track permission state in SharedPreferences

4. **Update FCM Service**
   - Add permission verification before topic subscription
   - Log permission states for debugging
   - Handle permission denied gracefully

### Files to Modify
- `lib/services/notification_service.dart` - Add permission checking
- `lib/widgets/notification_permission_tutorial.dart` - NEW FILE
- `lib/services/fcm_service.dart` - Add permission guards
- Add to main dashboard or settings as needed

---

##...Issue 3: Teacher Receiving Own Announcements 🚫

### Problem
When a teacher sends an announcement, the teacher account itself receives the notification.

### Current Implementation Analysis
- **File**: `lib/teacher_dashboard.dart` line 1898
- Uses `FCMService().notifyAllStudents()` which sends to 'announcements' topic
- **File**: `lib/services/fcm_service.dart` line 169-180
- `notifyAllStudents()` sends to topic 'announcements' with NO role filtering
- Teacher accounts are likely subscribed to the same topic as students

### Root Cause
- No role-based filtering when sending notifications
- Teachers subscribe to 'announcements' topic same as students
- Topic-based messaging doesn't exclude sender

### Solution
1. **Add Role Filtering to Notification Sending**
   - Before sending, check current user's role
   - If user is teacher, exclude teacher FCM tokens from recipient list
   - OR: Use separate topics ('student_announcements' vs 'announcements')

2. **Update Topic Subscription Logic**
   - Teachers subscribe to 'teacher_notifications' topic only
   - Students subscribe to 'student_announcements' topic only
   - Update `FCMService` topic subscriptions based on role

3. **Alternative: Token-based Sending**
   - Instead of topic, send to individual student FCM tokens
   - Query Firestore for student tokens, exclude teacher
   - More precise but requires token management

### Recommended Approach
**Use separate topics** - simpler and more maintainable

### Files to Modify
- `lib/services/fcm_service.dart` - Update topic names and subscription logic
- `lib/teacher_dashboard.dart` - Change 'announcements' topic to 'student_announcements'
- Update FCM initialization to subscribe based on user role
- `lib/main.dart` or auth flow - Subscribe to correct topic based on role

---

## Issue 4: Notification Popup Close Animation 🎬

### Problem
Popup notifications disappear abruptly when closed, making the interaction feel stiff and unpolished.

### Current Implementation Analysis
- Need to find where notification popups are displayed
- Likely in `lib/screens/notifications_screen.dart` or overlay widgets
- Currently NO close animation implemented

### Searching for Notification Popup Components
Need to locate:
- Overlay notification display logic
- Popup/dialog widgets for notifications
- Close/dismiss handlers

### Solution
1. **Add Close Animation to Popup Notifications**
   - Use `AnimatedOpacity` + `AnimatedScale` for smooth fade and scale-down
   - Duration: 200-300ms
   - Curve: `Curves.easeInOut` or `Curves.ease OutCubic`

2. **Implementation Pattern**
```dart
// Before closing, trigger animation
setState(() => _isClosing = true);
await Future.delayed(Duration(milliseconds: 250));
Navigator.pop(context); // or remove overlay
```

3. **Animation Specs**
   - Fade opacity: 1.0 → 0.0
   - Scale: 1.0 → 0.95
   - Optional: Slight slide up (translateY: 0 → -10px)
   - Professional and subtle

### Files to Modify
- TBD after locating popup implementation
- Likely a dialog or overlay widget
- May need to wrap in `AnimatedWidget` or use `flutter_animate`

---

## Implementation Order

### Phase 1: Data Integrity (Priority: CRITICAL)
1. **Issue 1** - Fix vocabulary history counting (1-2 hours)

### Phase 2: Notification Permissions (Priority: HIGH)
2. **Issue 2** - Add permission detection and tutorial (2-3 hours)

### Phase 3: Notification Logic (Priority: MEDIUM)
3. **Issue 3** - Exclude teacher from own announcements (1 hour)

### Phase 4: UX Polish (Priority: LOW)
4. **Issue 4** - Add popup close animation (30 mins - 1 hour)

---

## Testing Checklist

### Issue 1 Testing
- [ ] Complete daily vocabulary tasks
- [ ] Check that only completed words appear in history
- [ ] Miss a day, verify missed words are NOT counted
- [ ] Verify total learned count matches actual completions
- [ ] Check streak calculation uses only learned words
- [ ] Verify calendar indicators show correct days

### Issue 2 Testing
- [ ] Fresh install: Permission request appears
- [ ] User denies permission: Tutorial shows
- [ ] User allows permission: Notifications work
- [ ] User disables in system settings: App detects and prompts
- [ ] Deep-link to settings works on both Android/iOS
- [ ] Permission state persists correctly

### Issue 3 Testing
- [ ] Teacher sends announcement
- [ ] Teacher account does NOT receive notification
- [ ] All student accounts DO receive notification
- [ ] Verify correct topic subscriptions by role
- [ ] Test with multiple teachers/students

### Issue 4 Testing
- [ ] Notification popup appears
- [ ] Close button triggers smooth animation
- [ ] Animation duration feels natural (not too fast/slow)
- [ ] No visual glitches or jumps
- [ ] Works on different screen sizes

---

## Notes

- All fixes should maintain backward compatibility
- Cloud sync should continue to work
- No changes to UI layout (except new tutorial)
- Ensure analytics events are logged where appropriate
- Document any new SharedPreferences keys or Firestore collections

---

**Status**: Ready for Implementation
**Last Updated**: 2026-01-11
