# Lesson 3: Present Tense - Design Document

## 1. Lesson Analysis & Pedagogical Goals
**Topic**: Simple Present Tense
**Target Audience**: Beginner / Early Intermediate
**Core Concepts**:
1.  **Habits & Routines** (Things we do every day).
2.  **Universal Facts** (Things that are always true).
3.  **The "Third Person S" Rule** (He/She/It walks vs I/You/We/They walk).
4.  **Negatives** (Do not / Does not).

To effectively teach this visually, we need scenes that contrast the **Actors** (Pronouns) performing similar actions, highlighting the consistency of the action (Habit) or the specific subject change (He vs They).

## 2. Image Requirements
Based on the standard Gravity Lesson format (8-10 Slides), we need **8 Core Scenes** to cover the progression from 1st person -> 3rd person -> Negatives -> Summary.

**Total Images Needed**: 8
**Aspect Ratio**: 9:16 (Portrait) or 1:1 (Square) - *Recommended: 9:16 for full screen immersion.*
**Style**: Premium 3D Cartoon / Pixar-style. Vibrant, warm, and cute.

## 3. Scene Breakdown & Image Prompts

### Scene 1: The Daily Routine (I)
*Concept*: Introducing habits with "I".
*Text*: "**I wake** up at 7 AM every day."
*Prompt*:
> A cute 3D cartoon boy sitting up in bed stretching, morning sunlight streaming through the window, alarm clock on nightstand showing 7:00, cozy bedroom, vibrant colors, pixar style, high detail 8k --ar 9:16

### Scene 2: Shared Habits (We)
*Concept*: Plural subject, Base verb.
*Text*: "**We eat** breakfast together."
*Prompt*:
> A diverse 3D cartoon family (boy, mom, dad) eating breakfast at a modern round kitchen table, bowls of colorful cereal and orange juice, happy expressions, bright sunny kitchen environment, 3d render --ar 9:16

### Scene 3: Group Activity (They)
*Concept*: Plural subject, Base verb.
*Text*: "My friends **play** soccer."
*Prompt*:
> A group of diverse 3D cartoon kids playing soccer on a vivid green grass field, dynamic action pose kicking the ball, school building in background, bright blue sky, energetic atmosphere, disney style --ar 9:16

### Scene 4: Third Person Singular (He + S)
*Concept*: Highlighting the 'S'. Active movement.
*Text*: "**He runs** very fast."
*Prompt*:
> Close up of the 3D cartoon boy (Leo) running on a track, blurred background to show speed, determined happy expression, wind in hair, sneakers kicking up dust, 3d animation style, cinematic lighting --ar 9:16

### Scene 5: Third Person Fact (The Sun + S)
*Concept*: Universal truth / Inanimate 'It'.
*Text*: "The sun **rises** in the morning."
*Prompt*:
> A stunning 3D stylized landscape, golden bright sun rising over rolling green hills and a small river, fluffy white clouds, birds flying, beautiful inviting nature scene, high quality --ar 9:16

### Scene 6: Third Person Hobby (She + S)
*Concept*: Contrast with 'He'.
*Text*: "**She reads** a big book."
*Prompt*:
> A cute 3D cartoon girl sitting under a large oak tree reading a colorful open book, wearing glasses, peaceful magical garden atmosphere, dappled sunlight through leaves, detailed textures --ar 9:16

### Scene 7: The Negative (Do not)
*Concept*: Introducing "Do not/Don't".
*Text*: "I **do not** like broccoli!"
*Prompt*:
> The 3D cartoon boy (Leo) sitting at a dinner table looking at a plate of green broccoli with a funny skeptical face, arms crossed, refusing to eat, expressive emotion, humorous, warm lighting --ar 9:16

### Scene 8: Summary / Emotion (Love)
*Concept*: Positive conclusion using a Stative Verb.
*Text*: "**We love** to learn!"
*Prompt*:
> Leo and his diverse group of friends standing together smiling at the camera, holding colorful books, giving thumbs up, floating math and alphabet symbols in the background, celebratory, confetti, bright colors --ar 9:16

## 4. Implementation Steps
1.  **Generate Images**: Use the prompts above with the `generate_image` tool.
2.  **Save Assets**: Save to `assets/Lessons/Lesson_03_Tense_Present/`.
3.  **Update Config**: Update `lesson_present_tense_screen.dart` (to be created) with the file names `present_01.png` through `present_08.png`.
