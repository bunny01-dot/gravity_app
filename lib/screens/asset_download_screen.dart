import 'package:flutter/material.dart';
import 'package:gravity_app/dashboard.dart';
import 'package:gravity_app/teacher_dashboard.dart';
import 'package:gravity_app/services/remote_asset_service.dart';
import 'package:gravity_app/services/placement_state_service.dart';
import 'package:gravity_app/screens/placement_entry_screen.dart';
import 'package:lottie/lottie.dart';

class AssetDownloadScreen extends StatefulWidget {
  final String userRole;

  const AssetDownloadScreen({super.key, required this.userRole});

  @override
  State<AssetDownloadScreen> createState() => _AssetDownloadScreenState();
}

class _AssetDownloadScreenState extends State<AssetDownloadScreen> {
  static const String _assetZipUrl = String.fromEnvironment(
    'ASSET_ZIP_URL',
    defaultValue: '',
  );

  double _progress = 0.0;
  String _statusMessage = "Preparing to download assets...";
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    final service = RemoteAssetService();

    // Configure via:
    // flutter run --dart-define=ASSET_ZIP_URL=https://...
    service.setZipUrl(_assetZipUrl);

    // Skip setup when no remote bundle is configured.
    if (service.totalAssets == 0 || _assetZipUrl.trim().isEmpty) {
      debugPrint('Asset download skipped (ASSET_ZIP_URL not configured).');
      // No assets configured or placeholder active, skip immediately
      _navigateToDashboard();
      return;
    }

    setState(() {
      _statusMessage = "Downloading learning materials...";
    });

    try {
      await service.downloadAndExtractAssets(
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
              if (progress >= 0.99) {
                _statusMessage = "Unpacking materials...";
              } else {
                _statusMessage = "Downloading... ${(progress * 100).toInt()}%";
              }
            });
          }
        },
      );
      _navigateToDashboard();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage =
              "Error downloading assets. Please check your internet connection.";
        });
      }
    }
  }

  Future<void> _navigateToDashboard() async {
    if (!mounted) return;
    final navigator = Navigator.of(context);

    if (widget.userRole == 'teacher') {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TeacherDashboard()),
        (route) => false,
      );
    } else {
      await PlacementStateService.ensureInitialized();
      final status = await PlacementStateService.getPlacementQuizStatus();
      final hasCompleted = status == PlacementStateService.statusCompleted;
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => hasCompleted
              ? const DashboardScreen()
              : const PlacementEntryScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final progressPercent = (_progress * 100).clamp(0, 100).toInt();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [
              colorScheme.primary.withValues(alpha: 0.25),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Lottie.asset(
                    'assets/lottie/loading.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Setting up your experience",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "We are downloading the latest lesson content for you. This helps keep the app small and fast.",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (_hasError)
                  Column(
                    children: [
                      Text(
                        _statusMessage,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _startDownload,
                        child: const Text("Retry"),
                      ),
                      TextButton(
                        onPressed: _navigateToDashboard,
                        child: Text(
                          "Skip for now",
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withValues(
                            alpha: 0.65,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                                color: colorScheme.primary,
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "$progressPercent%",
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _statusMessage,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
