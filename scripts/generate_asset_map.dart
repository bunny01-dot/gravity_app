import 'dart:io';
import 'package:path/path.dart' as path;

/// Run this script to generate the asset map for your RemoteAssetService.
/// Usage: `dart scripts/generate_asset_map.dart <project-id> <bucket-name>`
/// Example: `dart scripts/generate_asset_map.dart my-app-123 my-app-123.appspot.com`

void main(List<String> args) {
  if (args.isEmpty) {
    stdout.writeln('Usage: dart scripts/generate_asset_map.dart <bucket-name>');
    stdout.writeln(
      'Example: dart scripts/generate_asset_map.dart gravity-app.appspot.com',
    );
    return;
  }

  final bucketName = args[0];
  final assetsDir = Directory('assets');

  if (!assetsDir.existsSync()) {
    stdout.writeln('Error: "assets" directory not found in current path.');
    return;
  }

  stdout.writeln(
    '// Copy this map into lib/services/remote_asset_service.dart',
  );
  stdout.writeln('final Map<String, String> _assetUrls = {');

  final files = assetsDir.listSync(recursive: true).whereType<File>();

  for (var file in files) {
    // normalize path to use forward slashes
    final relativePath = path
        .relative(file.path, from: '.')
        .replaceAll('\\', '/');

    // Skip system files
    if (relativePath.contains('.DS_Store') ||
        relativePath.contains('Thumbs.db')) {
      continue;
    }

    // Encode path for URL (slashes become %2F)
    final urlPath = Uri.encodeComponent(relativePath);

    // Construct Firebase Storage Public Download URL
    // Pattern: https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<path>?alt=media
    final url =
        'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/$urlPath?alt=media';

    stdout.writeln("    '$relativePath': '$url',");
  }

  stdout.writeln('};');
}
