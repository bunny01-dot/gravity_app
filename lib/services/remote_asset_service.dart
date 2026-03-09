import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';

/// Service to handle downloading and extracting a zipped asset bundle.
/// Best for using services like OneDrive, Google Drive, or Dropbox where managing
/// individual links for hundreds of files is impossible.
class RemoteAssetService {
  static final RemoteAssetService _instance = RemoteAssetService._internal();
  factory RemoteAssetService() => _instance;
  RemoteAssetService._internal();

  /// The DIRECT download link to your assets.zip file.
  /// For OneDrive: Right-click file > Embed > Generate HTML.
  /// Look for the URL in 'src="https://..."'.
  /// Change 'embed' to 'download' in the URL.
  String? zipUrl;

  /// Sets the URL for the asset bundle.
  void setZipUrl(String url) {
    zipUrl = url;
  }

  /// Returns the local path where the assets should be stored.
  /// This is the root 'assets' folder in the app's document directory.
  Future<String> _getLocalAssetsDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    return path.join(docDir.path, 'assets');
  }

  /// Checks if the assets have already been downloaded/extracted.
  /// We check for the existence of the root assets directory.
  Future<bool> hasAssets() async {
    final localDir = await _getLocalAssetsDir();
    return Directory(localDir).exists();
  }

  /// Gets the File object for an asset.
  Future<File?> getAssetFile(String assetKey) async {
    final localDir = await _getLocalAssetsDir();
    // assetKey should typically start with 'assets/...' or just be the path inside the zip
    // e.g., 'assets/images/logo.png' -> check 'documents/assets/images/logo.png'

    // If the zip was "assets.zip" containing a folder "assets", then extraction might
    // nest it. We assume the user zips the CONTENTS of assets/

    final fullPath = path.join(localDir, assetKey.replaceFirst('assets/', ''));
    final file = File(fullPath);

    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Downloads and extracts the zip file.
  Future<void> downloadAndExtractAssets({Function(double)? onProgress}) async {
    if (zipUrl == null || zipUrl!.isEmpty) {
      debugPrint('No Zip URL provided');
      return;
    }

    try {
      debugPrint('Starting download from $zipUrl');
      final request = http.Request('GET', Uri.parse(zipUrl!));
      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        int received = 0;

        // Prepare temp file for the zip
        final tempDir = await getTemporaryDirectory();
        final zipFile = File(path.join(tempDir.path, 'temp_assets.zip'));
        final sink = zipFile.openWrite();

        // Download with progress
        await response.stream
            .listen(
              (List<int> chunk) {
                sink.add(chunk);
                received += chunk.length;
                if (contentLength > 0 && onProgress != null) {
                  onProgress(received / contentLength);
                }
              },
              onDone: () {},
              onError: (e) {
                throw e;
              },
            )
            .asFuture();

        await sink.close();
        debugPrint('Download complete. Extracting...');

        if (onProgress != null) onProgress(0.99); // extraction step

        // Extract
        final bytes = await zipFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        final localAssetsDir = await _getLocalAssetsDir();

        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final data = file.content as List<int>;
            // Determine path. If zip contains 'assets/folder/file', we keep structure.
            final p = path.join(localAssetsDir, filename);
            final f = File(p);
            await f.parent.create(recursive: true);
            await f.writeAsBytes(data);
          }
        }

        // Cleanup
        await zipFile.delete();
        debugPrint('Extraction complete.');
      } else {
        throw Exception('Failed to download: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading bundle: $e');
      rethrow;
    }
  }

  // Helper for UI to checking if we need to run the setup
  int get totalAssets => zipUrl != null ? 1 : 0;
}
