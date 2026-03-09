import re
from pathlib import Path


TARGET_FILES = [
    "lib/screens/lesson_active_passive_screen.dart",
    "lib/screens/lesson_adverbs_screen.dart",
    "lib/screens/lesson_articles_screen.dart",
    "lib/screens/lesson_comparatives_screen.dart",
    "lib/screens/lesson_conditionals_screen.dart",
    "lib/screens/lesson_correlative_conjunctions_screen.dart",
    "lib/screens/lesson_determiners_screen.dart",
    "lib/screens/lesson_future_perfect_continuous_screen.dart",
    "lib/screens/lesson_future_perfect_screen.dart",
    "lib/screens/lesson_idioms_screen.dart",
    "lib/screens/lesson_infinitives_participles_screen.dart",
    "lib/screens/lesson_irregular_verbs_screen.dart",
    "lib/screens/lesson_linking_words_screen.dart",
    "lib/screens/lesson_modal_verbs_screen.dart",
    "lib/screens/lesson_past_continuous_screen.dart",
    "lib/screens/lesson_past_perfect_continuous_screen.dart",
    "lib/screens/lesson_past_perfect_screen.dart",
    "lib/screens/lesson_phrasal_verbs_screen.dart",
    "lib/screens/lesson_prefixes_suffixes_screen.dart",
    "lib/screens/lesson_present_continuous_screen.dart",
    "lib/screens/lesson_present_perfect_continuous_screen.dart",
    "lib/screens/lesson_present_perfect_screen.dart",
    "lib/screens/lesson_punctuation_screen.dart",
    "lib/screens/lesson_question_types_screen.dart",
    "lib/screens/lesson_relative_pronoun_screen.dart",
    "lib/screens/lesson_reported_questions_screen.dart",
    "lib/screens/lesson_sentence_patterns_screen.dart",
    "lib/screens/lesson_simple_future_screen.dart",
    "lib/screens/lesson_simple_past_screen.dart",
    "lib/screens/lesson_subject_verb_agreement_screen.dart",
    "lib/screens/lesson_types_of_sentences_screen.dart",
    "lib/screens/lesson_verbal_nouns_screen.dart",
]


def _extract_bracket_block(text: str, anchor: str) -> str:
    anchor_idx = text.find(anchor)
    if anchor_idx == -1:
        raise ValueError(f"Anchor not found: {anchor}")

    start = text.find("[", anchor_idx)
    if start == -1:
        raise ValueError(f"List start not found after anchor: {anchor}")

    i = start
    depth = 0
    in_single = False
    in_double = False
    in_line_comment = False
    in_block_comment = False
    escaped = False

    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""

        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
            i += 1
            continue

        if in_block_comment:
            if ch == "*" and nxt == "/":
                in_block_comment = False
                i += 2
            else:
                i += 1
            continue

        if in_single:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == "'":
                in_single = False
            i += 1
            continue

        if in_double:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_double = False
            i += 1
            continue

        if ch == "/" and nxt == "/":
            in_line_comment = True
            i += 2
            continue
        if ch == "/" and nxt == "*":
            in_block_comment = True
            i += 2
            continue
        if ch == "'":
            in_single = True
            i += 1
            continue
        if ch == '"':
            in_double = True
            i += 1
            continue

        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                return text[start : i + 1]

        i += 1

    raise ValueError(f"Unclosed list for anchor: {anchor}")


def _title_from_class(class_name: str) -> str:
    base = class_name
    if base.startswith("Lesson"):
        base = base[len("Lesson") :]
    if base.endswith("Screen"):
        base = base[: -len("Screen")]
    words = re.findall(r"[A-Z][a-z0-9]*", base)
    return " ".join(words) if words else base


def _fallback_key(file_path: Path) -> str:
    stem = file_path.stem
    if stem.endswith("_screen"):
        stem = stem[: -len("_screen")]
    return stem


def _convert_file(file_path: Path) -> None:
    text = file_path.read_text(encoding="utf-8")

    class_match = re.search(
        r"class\s+([A-Za-z0-9_]+)\s+extends\s+StatefulWidget", text
    )
    if not class_match:
        raise ValueError("StatefulWidget class not found")
    class_name = class_match.group(1)

    constructor_name = class_name

    asset_match = re.search(
        r"final\s+String\s+_assetPath\s*=\s*('(?:[^'\\]|\\.)*')\s*;",
        text,
        re.S,
    )
    if not asset_match:
        raise ValueError("_assetPath not found")
    asset_path_literal = asset_match.group(1)

    progress_match = re.search(r"'(lesson_[a-z0-9_]+)_story_completed'", text)
    if not progress_match:
        progress_match = re.search(r"'(lesson_[a-z0-9_]+)_quiz_completed'", text)
    progress_base_key = progress_match.group(1) if progress_match else _fallback_key(file_path)

    lesson_id = progress_base_key
    title = _title_from_class(class_name)

    slides_block = _extract_bracket_block(text, "_slides = [")
    quiz_block = _extract_bracket_block(text, "_quizQuestions = [")

    output = f"""import 'package:flutter/material.dart';
import 'package:gravity_app/models/lesson_models.dart';
import 'package:gravity_app/widgets/lesson_scaffold.dart';

class {class_name} extends StatelessWidget {{
  final int initialStoryIndex;
  final int initialQuizIndex;
  final String? initialMode;

  const {constructor_name}({{
    super.key,
    this.initialStoryIndex = 0,
    this.initialQuizIndex = 0,
    this.initialMode,
  }});

  @override
  Widget build(BuildContext context) {{
    return LessonScaffold(
      lessonId: '{lesson_id}',
      title: '{title}',
      slides: _slides,
      quizQuestions: _quizQuestions,
      assetPath: {asset_path_literal},
      progressBaseKey: '{progress_base_key}',
      initialStoryIndex: initialStoryIndex,
      initialQuizIndex: initialQuizIndex,
      initialMode: initialMode,
    );
  }}
}}

final List<LessonUnit> _slides = {slides_block};

final List<Map<String, dynamic>> _quizQuestions = {quiz_block};
"""

    file_path.write_text(output, encoding="utf-8")
    print(f"[OK] Converted {file_path}")


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    for rel in TARGET_FILES:
        path = root / rel
        try:
            _convert_file(path)
        except Exception as exc:
            print(f"[SKIP] {path}: {exc}")


if __name__ == "__main__":
    main()
