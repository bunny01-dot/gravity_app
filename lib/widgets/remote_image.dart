import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gravity_app/services/remote_asset_service.dart';

class RemoteImage extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const RemoteImage(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit,
  });

  @override
  State<RemoteImage> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<RemoteImage> {
  File? _imageFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(RemoteImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() => _isLoading = true);
    final file = await RemoteAssetService().getAssetFile(widget.assetPath);
    if (mounted) {
      setState(() {
        _imageFile = file;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    // Fallback if not found (maybe generic placeholder or error icon)
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
