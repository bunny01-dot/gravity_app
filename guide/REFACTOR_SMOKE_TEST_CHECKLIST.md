# Refactor Smoke Test Checklist

Date: 2026-03-02
Scope: `main.dart` split, dashboard/home-tab split, teacher dashboard split.

## 1. App Boot And Routing

- [ ] Launch app from cold start.
- [ ] Verify no red screen during bootstrap/loading states.
- [ ] Login as student and verify student home loads.
- [ ] Login as teacher and verify teacher dashboard loads.

## 2. Student Dashboard Core

- [ ] Pull to refresh on home tab and verify loading indicator appears/disappears.
- [ ] Open course progress popup and verify "Quizzes Passed" count renders (`0/<total>` format).
- [ ] Verify leaderboard/award card does not show stale eligibility warning text after threshold is met.
- [ ] Confirm XP display is consistent with reward policy (single task = `250 XP`) across cards/screens.

## 3. Reminder Notifications

- [ ] Keep default reminder time and verify one reminder is delivered at `9:00 AM`.
- [ ] Change reminder time in settings and verify only one reminder at the custom time.
- [ ] Verify no duplicate notifications fire at `9:00 AM` after custom time is saved.

## 4. Placement Quiz Flow

- [ ] Complete placement quiz through question 25.
- [ ] Verify navigation proceeds to result screen after final question.
- [ ] Confirm score/result UI renders without freezing.

## 5. Teacher Dashboard

- [ ] Open all tabs: Dashboard, Students, Library, Settings.
- [ ] Dashboard tab: attendance loads and pull refresh works.
- [ ] Students tab: open student detail, menu actions open expected dialogs.
- [ ] Change student difficulty and verify success snackbar.
- [ ] Library tab: open item edit dialog, close safely, and import CSV dialog opens.
- [ ] Settings tab: verify teacher logout option is not shown.

## 6. Teacher Announcements And History

- [ ] Send announcement (important + non-important) and verify success feedback.
- [ ] Open Manage History and delete a single item.
- [ ] Run "Delete Older (>7d)" and "Delete All" actions and confirm no navigator crash.

## 7. Stability Checks

- [ ] Watch logs while navigating dashboard cards; verify no `ParentDataWidget Positioned` error.
- [ ] Run daily verbs "mark all complete" path and verify no `Bad state: No element` pop crash.
- [ ] Run `flutter analyze lib/main.dart lib/features/dashboard/widgets/home_tab.dart lib/teacher_dashboard`.

