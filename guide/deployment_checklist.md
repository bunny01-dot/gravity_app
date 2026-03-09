# Pre-Deployment Checklist

## Session: February 1-2, 2026
## Status: ⚠️ TESTING REQUIRED

---

## ✅ Code Changes Complete

### Fix #1: Verb Forms Examples
- [x] Synced CSV from Google Sheets
- [x] Updated DataService parsing logic
- [x] Enhanced Dashboard UI
- [x] Created documentation
- [ ] **TESTING REQUIRED**

### Fix #2: Day Badge Calculation  
- [x] Fixed dashboard day calculation
- [x] Added CurriculumProgressService import
- [x] Created documentation
- [ ] **TESTING REQUIRED**

### Fix #3: Review Story Button
- [x] Added button to Subjects lesson
- [x] Created documentation
- [ ] **TESTING REQUIRED**

### Fix #4: Missed Lessons Count
- [x] Rewrote getMissedDates logic
- [x] Created documentation
- [ ] **TESTING REQUIRED**

---

## 🧪 Testing Checklist

### Manual Testing (Required Before Deployment)

#### Test #1: Verb Forms Examples
- [ ] Open Today's Verbs section
- [ ] Tap on a verb card to expand
- [ ] Verify English examples display (3 examples)
- [ ] Verify Tamil/Hindi examples display (based on preference)
- [ ] Verify examples are separated by "//" correctly
- [ ] Test with verb that has no examples (should fall back)
- [ ] Switch language preference, verify examples update

#### Test #2: Day Badge
- [ ] Check current day badge on dashboard
- [ ] Complete all daily tasks (vocab, verbs, pronunciation)
- [ ] Verify day badge increments to next day
- [ ] Restart app, verify day persists
- [ ] Test with new user account (should show Day 1)
- [ ] Test with user who skipped days (should show correct day)

#### Test #3: Review Story Button
- [ ] Open Subjects lesson
- [ ] Complete all story slides
- [ ] Complete the quiz (pass with 80%+)
- [ ] Verify "Review Story" button appears
- [ ] Tap "Review Story", verify goes to first slide
- [ ] Swipe through all slides
- [ ] Verify "Practice Again" button appears
- [ ] Tap "Practice Again", verify quiz restarts
- [ ] Verify "Return to Menu" works

#### Test #4: Missed Lessons Count
- [ ] Check "Pending Review(s)" count on dashboard
- [ ] Verify count matches actual missed days
- [ ] Test with Day 1 user (should show 0)
- [ ] Test with Day 3 user who completed all (should show 0)
- [ ] Test with user who skipped Day 2 (should show 1)
- [ ] Complete a missed lesson, verify count decreases

### Edge Case Testing

#### Edge Case #1: New User (Day 1)
- [ ] Create new account
- [ ] Verify day badge shows "Day 1"
- [ ] Verify missed lessons shows 0
- [ ] Complete first day tasks
- [ ] Verify day advances to "Day 2"

#### Edge Case #2: User Who Skipped Days
- [ ] Use account that skipped 2-3 days
- [ ] Verify missed lessons count is accurate
- [ ] Verify day badge shows current learning day (not calendar days)
- [ ] Complete a missed day
- [ ] Verify count updates correctly

#### Edge Case #3: Verb Without Examples
- [ ] Find a verb with empty example fields
- [ ] Verify it falls back to "Forms: V1 / V2 / V3"
- [ ] Verify no errors occur

#### Edge Case #4: Failed Quiz
- [ ] Complete Subjects lesson story
- [ ] Fail the quiz (score < 80%)
- [ ] Verify different completion screen shows
- [ ] Verify "Review Story" button NOT shown (only for passed quiz)
- [ ] Verify "Retake Quiz" option available

### Regression Testing

#### Core Features (Must Still Work)
- [ ] Daily vocabulary task completion
- [ ] Daily verbs task completion
- [ ] Daily pronunciation task completion
- [ ] Daily quiz completion
- [ ] Progress tracking and saving
- [ ] Cloud sync (Firebase)
- [ ] Notifications
- [ ] Black Hole feature
- [ ] Games Hub
- [ ] Profile screen
- [ ] Settings screen

---

## 🔍 Code Review Checklist

### Code Quality
- [x] No syntax errors
- [x] Follows existing code patterns
- [x] Proper error handling with fallbacks
- [x] Clear variable names
- [ ] **Lint warnings checked**
- [ ] **No console errors in debug mode**

### Performance
- [ ] No noticeable lag when expanding verb cards
- [ ] Day calculation doesn't slow down app startup
- [ ] Missed lessons calculation is fast
- [ ] No memory leaks

### Security
- [x] No hardcoded credentials
- [x] User data properly scoped (userId)
- [x] SharedPreferences keys properly namespaced
- [x] No SQL injection risks (N/A - using SharedPreferences)

---

## 📊 Monitoring Setup

### Metrics to Track (Post-Deployment)

#### User Engagement
- [ ] Set up analytics for "Review Story" button clicks
- [ ] Track verb example expansion rate
- [ ] Monitor lesson completion rates
- [ ] Track daily task completion rates

#### Technical Metrics
- [ ] Monitor error logs for new methods
- [ ] Track day badge accuracy
- [ ] Monitor missed lessons calculation time
- [ ] Check cloud sync success rate

#### Business Metrics
- [ ] User retention (7-day, 30-day)
- [ ] Support ticket volume
- [ ] User satisfaction scores
- [ ] Feature usage rates

---

## 🚀 Deployment Steps

### Pre-Deployment
- [ ] Complete all testing above
- [ ] Review all code changes
- [ ] Update version number
- [ ] Create release notes
- [ ] Backup production database

### Staging Deployment
- [ ] Deploy to staging environment
- [ ] Run smoke tests
- [ ] Test with staging data
- [ ] Monitor for 24-48 hours
- [ ] Collect feedback from beta testers

### Production Deployment
- [ ] Deploy to production
- [ ] Monitor error logs (first 2 hours)
- [ ] Check key metrics dashboard
- [ ] Verify cloud sync working
- [ ] Test on multiple devices
- [ ] Monitor user feedback channels

### Post-Deployment
- [ ] Send release announcement
- [ ] Update documentation
- [ ] Monitor support tickets
- [ ] Track key metrics for 1 week
- [ ] Plan follow-up fixes if needed

---

## ⚠️ Rollback Plan

### If Issues Found in Staging
1. Revert code changes
2. Identify root cause
3. Fix and re-test
4. Re-deploy to staging

### If Issues Found in Production
1. **Immediate:** Revert to previous version
2. **Within 1 hour:** Notify users of temporary rollback
3. **Within 24 hours:** Fix issues and re-test
4. **Within 48 hours:** Re-deploy with fixes

### Critical Issues Requiring Immediate Rollback
- Day badge showing incorrect values
- Missed lessons count causing crashes
- Verb examples breaking app
- Review button causing navigation errors
- Data loss or corruption

---

## 📝 Documentation Checklist

### User-Facing Documentation
- [ ] Update user guide with new features
- [ ] Create tutorial for Review Story button
- [ ] Update FAQ with new information
- [ ] Create release notes for users

### Developer Documentation
- [x] Session audit created
- [x] Individual fix documentation created
- [x] Code comments added
- [ ] API documentation updated (if applicable)
- [ ] Architecture diagrams updated (if needed)

---

## 🎯 Success Criteria

### Must Have (Before Production)
- [ ] All manual tests pass
- [ ] No critical bugs found
- [ ] Staging deployment successful
- [ ] Performance acceptable
- [ ] No data corruption

### Should Have (Before Production)
- [ ] Edge cases tested
- [ ] Regression tests pass
- [ ] Monitoring setup complete
- [ ] Rollback plan tested
- [ ] Documentation complete

### Nice to Have (Can Do Post-Production)
- [ ] Unit tests added
- [ ] Integration tests automated
- [ ] Performance optimizations
- [ ] Code refactoring
- [ ] Additional features

---

## 📞 Escalation Plan

### If Testing Reveals Critical Issues
**Contact:** Development Team Lead  
**Timeline:** Immediate  
**Action:** Delay deployment, fix issues

### If Staging Deployment Fails
**Contact:** DevOps Team  
**Timeline:** Within 1 hour  
**Action:** Investigate infrastructure issues

### If Production Deployment Causes Issues
**Contact:** Product Manager + CTO  
**Timeline:** Immediate  
**Action:** Execute rollback plan

---

## ✅ Final Sign-Off

### Before Staging Deployment
- [ ] All code changes reviewed
- [ ] All manual tests completed
- [ ] No critical issues found
- [ ] Team lead approval obtained

**Signed:** ________________  
**Date:** ________________

### Before Production Deployment
- [ ] Staging deployment successful
- [ ] 24-48 hour monitoring complete
- [ ] No issues reported
- [ ] Product manager approval obtained

**Signed:** ________________  
**Date:** ________________

---

## 📋 Quick Reference

### Files Modified (6 code files)
1. `assets/Master Sheets/Verb Forms Beginner - Sheet.csv`
2. `lib/services/data_service.dart`
3. `lib/dashboard.dart`
4. `lib/screens/lesson_subjects_screen.dart`

### Documentation Created (6 files)
5. `guide/verb_forms_example_update.md`
6. `guide/day_badge_fix.md`
7. `guide/review_story_button_fix.md`
8. `guide/missed_lessons_fix.md`
9. `guide/session_audit_2026_02_01.md`
10. `guide/review_button_audit.md`
11. `guide/session_summary.md`

### Key Contacts
- **Development Team:** [Contact Info]
- **QA Team:** [Contact Info]
- **Product Manager:** [Contact Info]
- **DevOps:** [Contact Info]

### Important Links
- **Staging Environment:** [URL]
- **Production Environment:** [URL]
- **Error Logs:** [URL]
- **Analytics Dashboard:** [URL]

---

**Last Updated:** 2026-02-02  
**Next Review:** Before Staging Deployment  
**Status:** ⚠️ AWAITING TESTING
