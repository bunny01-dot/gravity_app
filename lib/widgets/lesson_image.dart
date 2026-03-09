import 'dart:io';

import 'package:flutter/material.dart';

import '../services/lesson_content_service.dart';

class LessonImage extends StatefulWidget {
  final String lessonId;
  final String imageName;
  final String fallbackAssetPath;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const LessonImage({
    super.key,
    required this.lessonId,
    required this.imageName,
    required this.fallbackAssetPath,
    this.fit,
    this.width,
    this.height,
  });

  static final Map<String, Future<File?>> _localAssetFutureCache =
      <String, Future<File?>>{};

  static String normalizeImageName(String raw, {String? lessonId}) {
    var value = raw.trim();
    if (value.isEmpty) return value;

    if (value.startsWith('assets/Lessons/')) {
      value = value.substring('assets/Lessons/'.length);
    }

    if (lessonId != null && value.isNotEmpty) {
      final mappedFolder = LessonContentService().getMappedFolder(lessonId);
      final prefix = '$mappedFolder/';
      if (value.startsWith(prefix)) {
        value = value.substring(prefix.length);
      } else if (value == mappedFolder) {
        value = '';
      }
    }

    return value;
  }

  static String buildCloudUrl({
    required String lessonId,
    required String imageName,
  }) {
    final folder = LessonContentService().getMappedFolder(lessonId);
    final normalizedName = normalizeImageName(imageName, lessonId: lessonId);
    return 'https://firebasestorage.googleapis.com/v0/b/gravity-app-f9933.appspot.com/o/Lessons%2F$folder%2F${Uri.encodeComponent(normalizedName)}?alt=media';
  }

  static Future<File?> resolveLocalFile({
    required String lessonId,
    required String imageName,
  }) {
    final normalizedName = normalizeImageName(imageName, lessonId: lessonId);
    final cacheKey = '$lessonId::$normalizedName';
    return _localAssetFutureCache.putIfAbsent(
      cacheKey,
      () => LessonContentService().getLocalAsset(lessonId, normalizedName),
    );
  }

  static Future<List<ImageProvider>> buildPrecacheProviders({
    required String lessonId,
    required String imageName,
    required String fallbackAssetPath,
  }) async {
    final providers = <ImageProvider>[];
    final normalizedName = normalizeImageName(imageName, lessonId: lessonId);

    final localFile = await resolveLocalFile(
      lessonId: lessonId,
      imageName: normalizedName,
    );
    if (localFile != null) {
      providers.add(FileImage(localFile));
    }

    providers.add(AssetImage(fallbackAssetPath));
    providers.add(
      NetworkImage(
        buildCloudUrl(lessonId: lessonId, imageName: normalizedName),
      ),
    );

    return providers;
  }

  @override
  State<LessonImage> createState() => _LessonImageState();
}

class _LessonImageState extends State<LessonImage> {
  File? _localFile;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkLocalFile();
  }

  Future<void> _checkLocalFile() async {
    final file = await LessonImage.resolveLocalFile(
      lessonId: widget.lessonId,
      imageName: widget.imageName,
    );
    if (mounted) {
      setState(() {
        _localFile = file;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      // Paint fast while local lookup is still running.
      return _buildBundledFallback();
    }

    if (_localFile != null) {
      return Image.file(
        _localFile!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Local file corrupted: ${widget.imageName}');
          return _buildBundledFallback();
        },
      );
    }

    // Bundle first for fast paint, cloud only as last fallback.
    return _buildBundledFallback();
  }

  Widget _buildBundledFallback() {
    return Image.asset(
      widget.fallbackAssetPath,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) {
        return _buildCloudFallback();
      },
    );
  }

  Widget _buildCloudFallback() {
    final cloudUrl = LessonImage.buildCloudUrl(
      lessonId: widget.lessonId,
      imageName: widget.imageName,
    );

    return Image.network(
      cloudUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.white.withValues(alpha: 0.05),
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: Colors.white24,
              size: 40,
            ),
          ),
        );
      },
    );
  }
}
