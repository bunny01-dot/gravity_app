# Image Generation Prompts for AI Tools

Copy these prompts to use with DALL-E, Midjourney, Stable Diffusion, or other AI image generators.
All images should be **square format (1:1 ratio)**, educational illustration style, colorful and child-friendly.

---

## Image 1: ravi_before_school_square.png
**Prompt:**
```
Square educational illustration of an Indian boy named Ravi (age 8-10) thinking and remembering. Show thought bubble with "BEFORE" arrow pointing to smaller scenes of morning activities like waking up and eating breakfast. Warm colors, child-friendly cartoon style, clean simple design, square 1:1 format.
```

---

## Image 2: past_perfect_timeline_square.png
**Prompt:**
```
Educational timeline diagram showing Past Perfect tense. Three points on a horizontal arrow: left labeled "Past 1 (had eaten)", middle labeled "Past 2 (movie started)", right labeled "Now". Simple clean design, bright educational colors, icons for each event, square 1:1 format.
```

---

## Image 3: had_pastpart_table_square.png
**Prompt:**
```
Grammar formula chart table with three columns. Column 1: subjects (I, You, He, She, We, They), Column 2: the word "had", Column 3: past participles (finished, eaten, gone). Colorful rows, clear headers, educational design, square 1:1 format.
```

---

## Image 4: ravi_morning_sequence_square.png
**Prompt:**
```
Educational illustration of a clock face showing 4 time points with icons. 7:00 AM (bed/wake icon), 7:15 AM (toothbrush icon), 7:30 AM (breakfast plate icon), 8:00 AM (school building icon). Circular layout, colorful icons, clean educational style, square 1:1 format.
```

---

## Image 5: before_after_by_square.png
**Prompt:**
```
Educational grammar illustration with three colorful boxes containing the words "before", "after", and "by the time". Each box has directional arrows showing time relationships. Clean modern design, bright colors, square 1:1 format.
```

---

## Image 6: past_perfect_neg_questions_square.png
**Prompt:**
```
Educational illustration with speech bubbles. Large central bubble asks "Had he studied?" with two smaller answer bubbles showing "Yes, he had" and "No, he hadn't". Colorful, simple, child-friendly design, square 1:1 format.
```

---

## Image 7: pp_vs_past_simple_square.png
**Prompt:**
```
Comparison diagram with two timelines labeled A and B. Timeline A shows two events on same horizontal line (simple past). Timeline B shows one event with "had done" arrow pointing earlier, then "went/arrived" event. Color-coded, clear educational design, square 1:1 format.
```

---

## Image 8: past_perfect_quiz_square.png
**Prompt:**
```
Educational quiz icon showing a checklist or quiz paper with checkmarks, a pencil, and multiple choice bubbles (A, B, C). Colorful, engaging, simple design suitable for grammar lesson, square 1:1 format.
```

---

## Image 9: past_perfect_speaking_square.png
**Prompt:**
```
Educational speaking practice illustration with a microphone icon and two-step arrows. Arrows labeled "had done" pointing to "came". Speech waves or sound elements. Colorful engaging design for English learning, square 1:1 format.
```

---

## Image 10: past_perfect_summary_square.png
**Prompt:**
```
Educational summary illustration showing Indian boy Ravi with two events marked with green checkmarks, showing chronological order (1st and 2nd). Success theme with stars or badges, warm educational colors, square 1:1 format.
```

---

## Quick Tips for Image Generation:

### For DALL-E / ChatGPT:
1. Go to ChatGPT Plus
2. Use GPT-4 with DALL-E
3. Paste each prompt
4. Download as 1024x1024 PNG
5. Rename to match the filename

### For Midjourney:
1. Add to each prompt: `--ar 1:1 --style raw`
2. Use `--v 6` for best quality
3. Example: `/imagine [prompt above] --ar 1:1 --v 6 --style raw`

### For Canva (Free):
1. Create new design → Custom size → 1024 x 1024 px
2. Search for "educational illustration" templates
3. Customize with text, arrows, icons
4. Download as PNG

### For Leonardo.ai:
1. Select "Preset: Illustration"
2. Set dimensions to 1024x1024
3. Paste prompts
4. Generate

### Color Palette Suggestions:
- **Warm tones** for Ravi: #FF9966, #FFCC99
- **Educational blue**: #4FACFE
- **Success green**: #00E676
- **Text/contrast**: #333333, #FFFFFF
- **Past Perfect theme**: #FF6F61 (coral/orange)

---

## Batch Generation Script (Optional)

If using Python with OpenAI API:

```python
import openai
import os

openai.api_key = "your-api-key-here"

images = {
    "ravi_before_school_square.png": "Square educational illustration of an Indian boy...",
    # ... add all 10 prompts
}

for filename, prompt in images.items():
    response = openai.Image.create(
        prompt=prompt,
        n=1,
        size="1024x1024"
    )
    image_url = response['data'][0]['url']
    # Download and save with filename
```

---

## Alternative: Use Stock Images + Editing

1. **iconscout.com** - Educational illustrations
2. **freepik.com** - Free vectors and illustrations
3. **flaticon.com** - Icons and simple graphics
4. **undraw.co** - Customizable illustrations

Download, edit in Canva/Figma to add:
- Text labels
- Arrows
- Color adjustments
- Resize to 1024x1024

---

Save all images to:
`e:/Apps/gravity_app/assets/Lessons/Lesson_04_Tense_Past/03_Past_Perfect/`

Then run:
```bash
flutter clean
flutter pub get
flutter run
```
