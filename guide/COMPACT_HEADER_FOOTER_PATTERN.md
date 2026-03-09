# Storybook Lesson - Compact Header & Footer Pattern

## Gold Standard Dimensions (from `lesson_present_tense_screen.dart`)

### Header (`_buildModernHeader` / `_buildHeader`)
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // COMPACT: ~60px height
  decoration: const BoxDecoration(
    color: Color(0xFF1E293B),
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
  ),
  child: Row( // Single Row, NOT Column
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(...),  // Close button
      Text(...),        // Lesson title (18px font)
      Container(...),   // Progress counter pill
    ],
  ),
)
```

**Key Points:**
- ✅ Padding: `horizontal: 20, vertical: 12` (NOT 24)
- ✅ Simple `Row` layout (NO Column, NO gradient, NO shadows)
- ✅ Rounded bottom corners only: `BorderRadius.vertical(bottom: Radius.circular(20))`
- ✅ Title font size: `18` (NOT 22)
- ✅ Progress pill on the RIGHT (NOT below title)

---

### Footer (`_buildModernFooter` / `_buildFooter`)
```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // ULTRA-COMPACT: ~44px height
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _currentIndex > 0
          ? IconButton(
              onPressed: _prevPage,
              iconSize: 20,              // Smaller icon
              padding: EdgeInsets.zero,  // No padding
              constraints: const BoxConstraints(), // Minimal constraints
              icon: Icon(Icons.arrow_back_ios, color: Colors.white70),
            )
          : SizedBox(width: 40), // Reduced from 48
      Row(
        children: List.generate(_slides.length, (index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 3), // Tighter spacing
            width: _currentIndex == index ? 10 : 5,      // Smaller dots
            height: 5,                                    // Smaller height
            decoration: BoxDecoration(
              color: _currentIndex == index ? Colors.cyanAccent : Colors.white24,
              borderRadius: BorderRadius.circular(2.5),
            ),
          );
        }),
      ),
      IconButton(
        onPressed: _nextPage,
        iconSize: 20,              // Smaller icon
        padding: EdgeInsets.zero,  // No padding
        constraints: const BoxConstraints(), // Minimal constraints
        icon: Icon(Icons.arrow_forward_ios, color: Colors.cyanAccent),
      ),
    ],
  ),
)
```

**Key Points:**
- ✅ Padding: `horizontal: 16, vertical: 12` (REDUCED from 20)
- ✅ IconButtons: `iconSize: 20` with `padding: EdgeInsets.zero`
- ✅ Dots: width 10/5, height 5 (REDUCED from 12/6 and 6)
- ✅ Dot margin: `horizontal: 3` (REDUCED from 4)
- ✅ SizedBox placeholder: width 40 (REDUCED from 48)
- ✅ Total footer height: **~44px** (was ~70px)

---

## What to AVOID (❌ Bloated Design)
- ❌ Gradients in header background
- ❌ Box shadows everywhere
- ❌ Column layout in header
- ❌ Large padding (vertical: 20+)
- ❌ Container wrappers around IconButtons (50x50)
- ❌ AnimatedContainer for dots
- ❌ Glowing shadows on dots
- ❌ BorderRadius on footer Container (30px)
- ❌ Separate progress pill below title

---

## Implementation Checklist
- [ ] Header: `padding: horizontal 20, vertical 12`
- [ ] Header: Single `Row` layout (NO Column)
- [ ] Header: Simple background color (NO gradient)
- [ ] Header: Title font size 18
- [ ] Header: Progress pill on RIGHT side
- [ ] Footer: `padding: horizontal 16, vertical 12` ⚡ ULTRA-COMPACT
- [ ] Footer: `IconButton` with `iconSize: 20, padding: EdgeInsets.zero`
- [ ] Footer: Smaller dots (width 10/5, height 5)
- [ ] Footer: Tighter spacing (margin horizontal: 3)
- [ ] Total header+footer: **~104px** (Header ~60px + Footer ~44px) 🎯
- [ ] Maximum space for content cards!
