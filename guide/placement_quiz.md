# Placement Quiz Design Document v2.0 (Verified)

## Overview
This document outlines the final 25-question placement quiz. The logic ensures that users are placed in a level that challenges them without being overwhelming.

---

## Final Placement Decision Logic
To move away from simple total-score logic, we use segment-based requirements:

1. **Section 1: Level C – Beginner (Q1–9)**
   * *Requirement*: At least **6 correct** to consider passing this base.
2. **Section 2: Level B – Intermediate (Q10–18)**
   * *Requirement*: At least **6 correct** to consider passing this level.
3. **Section 3: Level A – Advanced (Q19–25)**
   * *Requirement*: At least **4 correct** to consider passing this level.

### Final Level Assignment:
* **Level C (Beginner)**:
  * Fails Beginner section (< 6/9) **OR** Total score 0–10.
* **Level B (Intermediate)**:
  * Passes Beginner section (>= 6/9).
  * Partial or full pass of Intermediate section.
  * Total score 11–18.
* **Level A (Advanced)**:
  * Passes Beginner & Intermediate sections (>= 6/9 both).
  * Passes Advanced section (>= 4/7).
  * Total score 19–25.

---

## The Quiz Questions

### Section 1: Beginner
1. **Subject–Verb Agreement**
   "Which sentence is correct?"
   A) She don't like apples.
   ✅ B) She doesn't like apples.
   C) She not like apples.
   D) She isn't likes apples.

2. **Articles**
   "I saw ___ airplane in the sky."
   A) a
   ✅ B) an
   C) the
   D) (no article)

3. **Simple Present Tense**
   "My brother ___ video games every weekend."
   A) play
   B) playing
   ✅ C) plays
   D) is play

4. **Parts of Speech**
   "In 'The fast car won the race', what is 'fast'?"
   A) Noun
   B) Verb
   ✅ C) Adjective
   D) Adverb

5. **Prepositions**
   "The cat is hiding ___ the table."
   A) of
   B) in
   ✅ C) under
   D) at

6. **Simple Past Tense**
   "Yesterday, we ___ to the park."
   A) go
   B) goes
   ✅ C) went
   D) gone

7. **Plurals**
   "Select the correct plural form of 'Child'."
   A) Childs
   B) Childrens
   ✅ C) Children
   D) Childer

8. **Basic Vocabulary**
   "What is the opposite of 'Difficult'?"
   A) Hard
   B) Heavy
   ✅ C) Easy
   D) Soft

9. **Pronouns**
   "Please give the book to ___."
   A) I
   ✅ B) me
   C) my
   D) mine

### Section 2: Intermediate
10. **Modal Verbs**
    "You ___ smoke in the hospital. It is forbidden."
    A) don't have to
    ✅ B) must not
    C) might not
    D) couldn't

11. **Future Forms**
    "Look at those dark clouds! It ___ rain."
    A) will
    ✅ B) is going to
    C) shall
    D) rains

12. **Comparatives**
    "This problem is ___ than the last one."
    ✅ A) more complicated
    B) complicateder
    C) most complicated
    D) as complicated

13. **Conjunctions**
    "I wanted to buy the shoes, ___ they were too expensive."
    A) or
    B) so
    ✅ C) but
    D) because

14. **Adverbs**
    "He speaks English very ___."
    A) good
    ✅ B) well
    C) best
    D) nice

15. **Verbal Nouns**
    "She enjoys ___ books in her free time."
    A) read
    B) to read
    ✅ C) reading
    D) reads

16. **Voice**
    "The telephone ___ by Alexander Graham Bell."
    A) invented
    B) is invented
    ✅ C) was invented
    D) has been invented

17. **Meaning in Context**
    "What does this sentence mean? 'I might come later.'"
    A) I will definitely come
    B) I am refusing
    ✅ C) I am unsure
    D) I already came

18. **Conditionals (First)**
    "If it rains tomorrow, we ___ the picnic."
    ✅ A) will cancel
    B) cancel
    C) would cancel
    D) cancelled

### Section 3: Advanced
19. **Conditionals (Second)**
    "If I ___ you, I would accept the job offer."
    A) am
    B) was
    ✅ C) were
    D) have been

20. **Perfect Tenses**
    "By the time we arrive, the movie ___."
    A) will start
    B) has starting
    ✅ C) will have started
    D) is starting

21. **Reported Speech**
    "Choose the correct indirect speech: He said, 'I am busy now.'"
    A) He said that he is busy now.
    B) He said that he was busy now.
    ✅ C) He said that he was busy then.
    D) He said that I am busy then.

22. **Relative Pronouns**
    "The artist, ___ paintings are famous worldwide, lives here."
    A) who
    B) whom
    ✅ C) whose
    D) which

23. **Idioms**
    "What does it mean to 'sit on the fence'?"
    A) To be lazy
    B) To be in a dangerous position
    ✅ C) To be undecided
    D) To be very comfortable

24. **Advanced Vocabulary**
    "The instructions were **ambiguous**, leading to many mistakes."
    A) Clear and concise
    B) Long and detailed
    ✅ C) Unclear or having multiple meanings
    D) Incorrect

25. **Reading & Inference**
    "Ravi read the message twice. It sounded polite, but the tone made him uneasy. What can we infer?"
    A) Ravi is happy
    B) The message is informal
    ✅ C) Ravi senses hidden concern
    D) The message is confusing