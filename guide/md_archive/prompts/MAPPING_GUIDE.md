# Lesson-to-Prompt Mapping Guide

## Quick Reference: Lesson ID → Prompt File

| # | Lesson Folder | Lesson ID | Prompt File | Status |
|---|--------------|-----------|-------------|---------|
| 1 | Lesson_01_Subjects | `subjects` | subjects_prompts.md | ✅ |
| 2 | Lesson_02_PartsOfSpeech | `parts_of_speech` | parts_of_speech_prompts.md | ✅ |
| 3 | Lesson_03_Articles | `articles` | articles_prompts.md | ✅ |
| 4 | Lesson_03_Tense_Present | `simple_present` | simple_present_prompts.md | ✅ |
| 5 | Lesson_04_Irregular_Verbs | `irregular_verbs` | irregular_verbs_prompts.md | ✅ |
| 6 | Lesson_04_Tense_Past | `simple_past` | simple_past_prompts.md | ✅ |
| 7 | Lesson_05_Tense_Future | `simple_future` | simple_future_prompts.md | ✅ |
| 8 | Lesson_07_Sentence_Patterns | `sentence_patterns` | sentence_patterns_prompts.md | ✅ |
| 9 | Lesson_08_Types_of_Sentences | `types_of_sentences` | types_of_sentences_prompts.md | ✅ |
| 10 | Lesson_09_Modal_Verbs | `modal_verbs` | modal_verbs_prompts.md | ✅ |
| 11 | Lesson_12_Active_Passive | `active_passive` | active_passive_prompts.md | ✅ |
| 12 | Lesson_14_Question_Types | `question_types` | question_types_prompts.md | ✅ |
| 13 | Lesson_16_Relative_Pronoun | `relative_pronoun` | relative_pronoun_prompts.md | ✅ |
| 14 | Lesson_27_Adverbs | `adverbs` | adverbs_prompts.md | ✅ |
| 15 | Lesson_28_Linking_Words | `linking_words` | linking_words_prompts.md | ✅ |
| 16 | Lesson_Comparatives | `comparatives` | comparatives_prompts.md | ✅ |
| 17 | Lesson_Conditionals | `conditionals` | conditionals_prompts.md | ✅ |
| 18 | Lesson_Correlative_Conjunctions | `correlative_conjunctions` | correlative_conjunctions_prompts.md | ✅ |
| 19 | Lesson_Determiners | `determiners` | determiners_prompts.md | ✅ |
| 20 | Lesson_Direct_Indirect_Speech | `direct_indirect_speech` | direct_indirect_speech_prompts.md | ✅ |
| 21 | Lesson_Idioms | `idioms` | idioms_prompts.md | ✅ |
| 22 | Lesson_Infinitives_Participles | `infinitives_participles` | infinitives_participles_prompts.md | ✅ |
| 23 | Lesson_Phrasal_Verbs | `phrasal_verbs` | phrasal_verbs_prompts.md | ✅ |
| 24 | Lesson_Prefixes_Suffixes | `prefixes_suffixes` | prefixes_suffixes_prompts.md | ✅ |
| 25 | Lesson_Prepositions | `prepositions` | prepositions_prompts.md | ✅ |
| 26 | Lesson_Punctuation | `punctuation` | punctuation_prompts.md | ✅ |
| 27 | Lesson_Reported_Questions | `reported_questions` | reported_questions_prompts.md | ✅ |
| 28 | Lesson_Subject_Verb_Agreement | `subject_verb_agreement` | subject_verb_agreement_prompts.md | ✅ |
| 29 | Lesson_Verbal_Nouns | `verbal_nouns` | verbal_nouns_prompts.md | ✅ |
| 30 | - | `present_continuous` | present_continuous_prompts.md | ✅ |
| 31 | - | `present_perfect` | present_perfect_prompts.md | ✅ |
| 32 | - | `present_perfect_continuous` | present_perfect_continuous_prompts.md | ✅ |
| 33 | - | `past_continuous` | past_continuous_prompts.md | ✅ |
| 34 | - | `past_perfect` | past_perfect_prompts.md | ✅ |
| 35 | - | `past_perfect_continuous` | past_perfect_continuous_prompts.md | ✅ |
| 36 | - | `future_continuous` | future_continuous_prompts.md | ✅ |
| 37 | - | `future_perfect` | future_perfect_prompts.md | ✅ |
| 38 | - | `future_perfect_continuous` | future_perfect_continuous_prompts.md | ✅ |

## 📊 Summary Statistics

- **Total Prompt Files Created:** 38
- **Total Lessons Covered:** 38
- **Completion Rate:** 100%
- **Average Images per Lesson:** 8-10

## 🎨 Image Generation Workflow

### Step 1: Select a Lesson
Choose which lesson you want to generate images for.

### Step 2: Open Prompt File
Navigate to `e:\Apps\gravity_app\prompts\[lesson_name]_prompts.md`

### Step 3: Generate Images
For each row in the prompt table:
1. Copy the detailed prompt from the "Prompt" column
2. Use with your AI image generator (DALL-E, Midjourney, Stable Diffusion, etc.)
3. Download the generated image
4. Convert to WebP format if necessary
5. Rename to the filename specified in "Image File" column

### Step 4: Organize Images
Place generated images in the appropriate lesson folder:
```
assets/Lessons/Lesson_XX_Name/
├── 01_intro.webp
├── 02_concept.webp
├── 03_example.webp
└── ...
```

### Step 5: Verify
- Check image quality and consistency
- Ensure Ravi character looks consistent across images
- Verify all required images are generated
- Test loading in the app

## 🔧 Batch Generation Tips

### Using DALL-E 3
- Generate in batches of 5-10 images
- Use consistent seed/style parameters
- Save prompts for future reference

### Using Midjourney
- Create a dedicated channel for lesson images
- Use `--style` parameter for consistency
- Save favorite character renders as references

### Quality Checklist
- ✅ Ravi's appearance is consistent
- ✅ Premium 3D Pixar-style quality
- ✅ Warm, educational lighting
- ✅ Vibrant but harmonious colors
- ✅ Clear visual concept representation
- ✅ Appropriate for educational context
- ✅ WebP format, optimized file size

---

**Ready to Generate!** 🚀

All prompts are now ready for image generation. Start with any lesson and work through systematically.
