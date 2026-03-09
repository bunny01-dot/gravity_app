# Audit Reminders

This file contains reminders for future audits and production readiness checks.

## Content Delivery & App Size Optimization
**Status**: Partially Implemented / Deferred
**Date**: 2026-01-17

The mechanisms for offloading large assets (images, storybooks, audio) to the cloud have been implemented in code but are currently inactive/using placeholders because the lessons are still being developed.

### Action Items for "Audit" Phase:
1. **Compress & Zip Assets**: 
   - Gather all final assets from `assets/Lessons/` and other large folders.
   - Compress them into a single `assets.zip` file.
   - Ensure the internal structure of the zip matches the expected pathing (i.e., inside the zip, paths should align with what the code expects, e.g., `Lessons/...`).

2. **Upload to Cloud**:
   - Upload `assets.zip` to a hosting provider (OneDrive "Download" link, Firebase Storage, or AWS S3).
   - Ensure the link is a **direct download** link (starts the download immediately, no preview page).

3. **Configure the App**:
   - Open `lib/screens/asset_download_screen.dart`.
   - Update `service.setZipUrl('...')` with the actual URL.
   - Verify `RemoteAssetService` logic in `lib/services/remote_asset_service.dart`.

4. **Cleanup Local Assets**:
   - Once verified, remove the heavy folders from the local `assets/` directory in the project.
   - Update `pubspec.yaml` to remove those local asset references (so they aren't bundled).

### Current State:
- `RemoteAssetService` is implemented to handle Zip downloads and extraction.
- `AssetDownloadScreen` is implemented to show progress.
- `AssetDownloadScreen` is currently configured to **SKIP** the download if the URL is set to the placeholder `REPLACE_WITH_YOUR_DIRECT_DOWNLOAD_LINK`.
