import 'package:flutter/material.dart';

abstract class LessonUnit {}

class LessonSlide extends LessonUnit {
  final String title;
  final String content;
  final String imagePath;
  final String? soundPath;
  final String hindiContent;
  final String tamilContent;
  final String? formula;
  final BoxFit? imageFit;

  LessonSlide({
    required this.title,
    required this.content,
    required this.imagePath,
    this.soundPath,
    this.hindiContent = "",
    this.tamilContent = "",
    this.formula,
    this.imageFit,
  });
}

class LessonHighlightInteraction extends LessonUnit {
  final String title;
  final String introText;
  final List<String> highlightItems;
  final String exampleText;
  final String imagePath;
  final String hindiContent;
  final String tamilContent;
  final BoxFit? imageFit;

  LessonHighlightInteraction({
    required this.title,
    required this.introText,
    required this.highlightItems,
    required this.exampleText,
    required this.imagePath,
    this.hindiContent = "",
    this.tamilContent = "",
    this.imageFit,
  });
}

class LessonQuizInteraction extends LessonUnit {
  final String title;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String imagePath;
  final BoxFit? imageFit;

  LessonQuizInteraction({
    required this.title,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.imagePath,
    this.imageFit,
  });
}

class LessonSpeakingPractice extends LessonUnit {
  final String title;
  final String? micIconPath;
  final String imagePath;
  final List<String> prompts;
  final List<String> summaryPoints;
  final BoxFit? imageFit;

  LessonSpeakingPractice({
    required this.title,
    this.micIconPath,
    required this.imagePath,
    required this.prompts,
    this.summaryPoints = const [],
    this.imageFit,
  });
}
