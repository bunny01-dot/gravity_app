# Future Enhancement: Difficulty-Based Learning System

**Status:** PLANNED - Phase 2 Feature (Post Option A Implementation)  
**Date Documented:** January 19, 2026  
**Priority:** Medium - Implement after core Option A is validated with users

---

## Overview

This document outlines the planned enhancement to introduce **difficulty-based learning** with an **initial assessment test** to personalize the vocabulary learning experience.

**Important:** This feature is deliberately DEFERRED until after Option A (personal day counter) is implemented, tested, and validated with real users.

---

## The Vision

### Initial Assessment Test

**On First Launch (New Users Only):**
- Present a 20-question assessment covering:
  - Basic grammar (subject/verb identification)
  - Vocabulary recognition (word meanings)
  - Sentence construction
  - Tense recognition
  - Common word usage
  
**Scoring Brackets:**
- **Beginner:** < 7/20 correct answers
- **Intermediate:** 10-14/20 correct answers
- **Advanced:** 15+/20 correct answers

**UX Considerations:**
- Make assessment optional ("Take Test" vs "Skip - Start as Beginner")
- Must be engaging, not intimidating
- Show progress during test (Question 5/20)
- Immediate results with encouraging feedback
- Allow retake from Settings

---

## Three Difficulty Tracks

### Beginner Track
**Target Users:** New English learners, basic vocabulary knowledge

**Content Focus:**
- Basic nouns (cat, dog, book, pen, house)
- Simple verbs (eat, sleep, run, walk, talk)
- Common adjectives (big, small, hot, cold)
- Essential daily vocabulary

**Estimated Content:** 100 days (500 words)

---

### Intermediate Track
**Target Users:** Students with foundational English, ready for context

**Content Focus:**
- Contextual vocabulary (success, organize, creative)
- Phrasal verbs (give up, look after, run into)
- Moderate complexity nouns/adjectives
- Work, school, social vocabulary

**Estimated Content:** 100 days (500 words)

---

### Advanced Track
**Target Users:** Proficient learners seeking to master nuanced vocabulary

**Content Focus:**
- Sophisticated vocabulary (ephemeral, ubiquitous, paradox)
- Academic and professional terms
- Idiomatic expressions
- Abstract concepts

**Estimated Content:** 100 days (500 words)

---

## How It Works with Option A

### User Journey

**New User - First Launch:**
1. Welcome screen
2. Optional assessment test (or skip to Beginner Day 1)
3. Score calculated → Difficulty level assigned
4. User placed at Day 1 of their difficulty track
5. Normal Option A progression begins

**Personal Day Counter (Option A) Still Applies:**
- Beginner User A: Day 1, Day 2, Day 3... (of beginner track)
- Intermediate User B: Day 1, Day 2, Day 3... (of intermediate track)
- Both progress at their own pace through their track

**Progression Across Tracks:**
- After completing 100 days of Beginner → Offer to move to Intermediate
- Or allow retake of assessment test anytime
- Smooth transition: "Congratulations! Ready for Intermediate words?"

---

## CSV Structure Changes Required

### Option 1: Single CSV with Difficulty Column (RECOMMENDED)

```csv
word_id,word,definition,example,difficulty,day_number,category
1,cat,A small furry animal...,I have a pet cat,beginner,1,animals
2,dog,A common pet...,The dog is barking,beginner,1,animals
3,book,Pages with text...,I read a book,beginner,1,objects
4,pen,Writing instrument...,Write with a pen,beginner,1,objects
5,run,Move quickly...,I run every day,beginner,1,verbs
501,democracy,System of government...,India is a democracy,intermediate,1,concepts
502,organize,Arrange systematically...,Let's organize the event,intermediate,1,verbs
1001,ephemeral,Lasting very briefly...,Fame can be ephemeral,advanced,1,adjectives
1002,ubiquitous,Found everywhere...,Smartphones are ubiquitous,advanced,1,adjectives
```

**New Columns:**
- `difficulty`: beginner | intermediate | advanced
- `day_number`: 1-100 (resets for each difficulty level)

### Option 2: Three Separate CSVs

- `vocab_beginner.csv`
- `vocab_intermediate.csv`
- `vocab_advanced.csv`

Each with same structure as current CSV, but day_number 1-100

**Verdict:** Single CSV is cleaner, easier to maintain

---

## Technical Implementation Checklist

### Database/User Model Changes
- [ ] Add `difficulty_level` field (String: beginner/intermediate/advanced)
- [ ] Add `current_day_number` field (int, default: 1)
- [ ] Add `assessment_taken` field (bool, default: false)
- [ ] Add `assessment_score` field (int, nullable)
- [ ] Add `assessment_date` field (DateTime, nullable)
- [ ] Add `track_start_date` field (DateTime)
- [ ] Add `days_completed` field (int, for streak tracking)

### CSV Updates
- [ ] Add `difficulty` column to existing CSV
- [ ] Add `day_number` column to existing CSV
- [ ] Curate and assign 500 beginner words to days 1-100
- [ ] Curate and assign 500 intermediate words to days 1-100
- [ ] Curate and assign 500 advanced words to days 1-100
- [ ] Validate no duplicates across difficulty levels

### New Screens/Components
- [ ] Create `assessment_screen.dart` (20-question test UI)
- [ ] Create `assessment_questions.json` or hardcode questions
- [ ] Create `difficulty_selection_screen.dart` (results + placement)
- [ ] Update onboarding flow to include optional assessment
- [ ] Add "Retake Assessment" option in Settings

### Service Layer Updates
- [ ] Modify `DailySentenceService` to filter by difficulty + day_number
- [ ] Update word fetching logic:
  ```
  getWordsForToday(userId) {
    user = getUser(userId)
    difficulty = user.difficulty_level
    dayNum = user.current_day_number
    return fetchWords(difficulty: difficulty, day: dayNum, limit: 5)
  }
  ```
- [ ] Create `AssessmentService` for scoring and level assignment
- [ ] Update `DataService` to sync difficulty_level to cloud

### UI/UX Updates
- [ ] Dashboard shows: "Day 7 - Intermediate Track"
- [ ] Progress indicator: "Day 7/100" with visual bar
- [ ] Milestone celebrations: "Day 10!", "Day 50!", "Day 100 Complete!"
- [ ] Settings: Show current level + option to retake test
- [ ] Peer matching filters by difficulty + day number

### Content Creation Tasks (MAJOR EFFORT)
- [ ] Design 20 assessment questions (balanced across difficulties)
- [ ] Curate 500 beginner words with simple definitions
- [ ] Curate 500 intermediate words with contextual definitions
- [ ] Curate 500 advanced words with nuanced definitions
- [ ] Create example sentences for each difficulty appropriately
- [ ] Review and validate pedagogical progression

---

## Timeline Estimate

**Assuming work starts AFTER Option A is validated:**

| Phase | Task | Time |
|-------|------|------|
| Content | Design 20 assessment questions | 1 week |
| Content | Curate 1,500 words across 3 difficulty levels | 3-4 weeks |
| Dev | Assessment screen + logic | 1 week |
| Dev | CSV restructuring + migration | 3 days |
| Dev | Service layer updates | 1 week |
| Dev | User model + cloud sync | 3 days |
| Dev | UI updates (dashboard, settings) | 4 days |
| Testing | Full regression + difficulty flow testing | 1 week |
| **TOTAL** | | **8-10 weeks** |

---

## Risks & Mitigation

### Risk 1: Assessment Creates Friction
**Mitigation:** Make it optional, default to Beginner if skipped

### Risk 2: Content Creation Burden
**Mitigation:** Start with 30 days (150 words) per difficulty, expand over time

### Risk 3: Users Placed in Wrong Track
**Mitigation:** Easy retake option, smart suggestions ("You're acing these, try Intermediate?")

### Risk 4: Fragmented User Base
**Mitigation:** Peer matching by difficulty+day, community events across levels

---

## Success Metrics (Post-Implementation)

- **Assessment completion rate:** >60% of new users take test
- **Track distribution:** Balanced split across beginner/intermediate/advanced
- **Accuracy of placement:** <10% of users retake to change level in first month
- **Engagement:** Higher retention for users in appropriate difficulty vs one-size-fits-all
- **Progression:** 70%+ of users who complete Beginner track move to Intermediate

---

## Decision Points

**Before implementing, validate:**
1. Is Option A working well? Are users progressing through days consistently?
2. Do we have user feedback indicating difficulty mismatch?
3. Do we have resources for 3-4 weeks of content curation?
4. Is the core curriculum work complete?

**Do NOT implement if:**
- Option A has low engagement (fix that first)
- Current vocabulary content is insufficient
- Still working on core curriculum features

---

## Alternative: Softer Approach

If full 3-track system feels too heavy, consider:

**Phase 2a: Assessment Only (No Separate Tracks)**
- Give assessment test
- Show results: "You're at Intermediate level!"
- But ALL users still get same words (Option A, single track)
- Use difficulty level only for:
  - Personalized encouragement
  - Suggesting which curriculum lessons to prioritize
  - Analytics and user segmentation

**Phase 2b: Add Difficulty Tracks Later**
- Once you have 1,500+ curated words
- Once you have proof that one-size-fits-all isn't working

---

## Related Documents

- `daily_vocabulary_system_options.md` - Original Option A vs Option B discussion
- (Future) `assessment_questions.json` - The actual 20 questions
- (Future) `vocabulary_curation_guidelines.md` - How to curate by difficulty

---

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-01-19 | Initial documentation | Antigravity |

---

**REMINDER:** This is a FUTURE feature. Focus on implementing and validating Option A first. Revisit this document when:
- User requests "audit"
- Option A is stable and validated
- Ready to discuss personalization features
