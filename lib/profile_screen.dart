import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gravity_app/main.dart'; // To navigate back to LandingPage
import 'package:gravity_app/screens/teacher_feedback_screen.dart';
import 'package:gravity_app/screens/placement_quiz_screen.dart';
import 'package:gravity_app/screens/vocabulary_history_screen.dart';

import 'package:gravity_app/widgets/modern_glass_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gravity_app/services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool highlightFeedback;

  const ProfileScreen({super.key, this.highlightFeedback = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _retakePlacementUnlockLevel = 90;

  final TextEditingController _nameController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _userRole = 'student';
  String _avatarSeed = '';
  String _photoUrl = '';
  bool _isUploading = false;
  String _englishProficiencyLevel = 'Beginner (A1)';
  int _currentLearningStage = 1;
  int _xpLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String userName = prefs.getString('user_name') ?? "Guest User";
    String role = prefs.getString('user_role') ?? 'student';
    String seed = prefs.getString('avatar_seed') ?? '';
    String photoUrl = prefs.getString('photo_url') ?? '';
    String englishLevel =
        prefs.getString('english_proficiency_level') ?? 'Beginner (A1)';
    int currentStage = prefs.getInt('current_learning_stage') ?? 1;
    int xpLevel =
        prefs.getInt('user_xp_level') ?? prefs.getInt('user_level') ?? 1;

    try {
      if (_currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (data.containsKey('name')) {
            userName = data['name'];
            await prefs.setString('user_name', userName);
          }
          if (data.containsKey('role')) {
            role = data['role'];
            await prefs.setString('user_role', role);
          }
          if (data.containsKey('english_proficiency_level')) {
            englishLevel = (data['english_proficiency_level'] ?? '')
                .toString()
                .trim();
            if (englishLevel.isEmpty) englishLevel = 'Beginner (A1)';
            await prefs.setString('english_proficiency_level', englishLevel);
          }
          if (data.containsKey('avatar_seed')) {
            seed = data['avatar_seed'];
            await prefs.setString('avatar_seed', seed);
          } else {
            seed = '';
            await prefs.remove('avatar_seed');
          }
          if (data.containsKey('photo_url')) {
            photoUrl = data['photo_url'];
            await prefs.setString('photo_url', photoUrl);
          } else {
            photoUrl = '';
            await prefs.remove('photo_url');
          }
        }

        final progressDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .collection('progress')
            .doc('all_data')
            .get();
        final progress = progressDoc.data();
        if (progress != null) {
          currentStage =
              (progress['current_learning_stage'] as num?)?.toInt() ??
              currentStage;
          xpLevel =
              (progress['user_xp_level'] as num?)?.toInt() ??
              (progress['user_level'] as num?)?.toInt() ??
              xpLevel;
          await prefs.setInt('current_learning_stage', currentStage);
          await prefs.setInt('user_xp_level', xpLevel);
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }

    if (mounted) {
      setState(() {
        _nameController.text = userName;
        _userRole = role;
        _avatarSeed = seed;
        _photoUrl = photoUrl;
        _englishProficiencyLevel = englishLevel;
        _currentLearningStage = currentStage < 1 ? 1 : currentStage;
        _xpLevel = xpLevel < 1 ? 1 : xpLevel;
      });
    }
  }

  void _showSnackBar(
    String message, {
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    if (!mounted) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final snackBarTextStyle = theme.snackBarTheme.contentTextStyle;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(
          message,
          style:
              snackBarTextStyle?.copyWith(
                color:
                    foregroundColor ??
                    snackBarTextStyle.color ??
                    colorScheme.onInverseSurface,
              ) ??
              TextStyle(
                color: foregroundColor ?? colorScheme.onInverseSurface,
              ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final user = _currentUser;
      if (user == null) return;

      // Request permissions explicitly to ensure access
      if (Platform.isAndroid) {
        // Attempt to request both storage (old) and photos (new)
        await [Permission.storage, Permission.photos].request();
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        debugPrint("Image picking cancelled or failed.");
        return;
      }

      // Crop Image
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: colorScheme.surface,
            toolbarWidgetColor: colorScheme.onSurface,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            backgroundColor: theme.scaffoldBackgroundColor,
          ),
          IOSUiSettings(title: 'Crop Profile Photo'),
        ],
      );

      if (croppedFile == null) return;

      if (!mounted) return;
      setState(() => _isUploading = true);
      Navigator.pop(context); // Close sheet

      // Upload to Firebase Storage
      final File file = File(croppedFile.path);
      final String fileName = "${user.uid}_profile.jpg";
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child(fileName);

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Save to Firestore & Prefs
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photo_url': downloadUrl, 'avatar_seed': ''});

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('photo_url', downloadUrl);
      await prefs.setString('avatar_seed', '');

      if (mounted) {
        setState(() {
          _photoUrl = downloadUrl;
          _avatarSeed = ''; // Clear avatar seed to prefer photo
          _isUploading = false;
        });
        _showSnackBar('Profile photo updated!');
      }
    } catch (e) {
      debugPrint("Error uploading photo: $e");
      if (mounted) {
        setState(() => _isUploading = false);
        final colorScheme = Theme.of(context).colorScheme;
        _showSnackBar(
          'Failed to upload photo: $e',
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
        );
      }
    }
  }

  void _removePhoto() async {
    // Clear Photo
    setState(() {
      _photoUrl = '';
    });

    if (_currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .update({'photo_url': FieldValue.delete()});

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('photo_url');
    }

    if (mounted) {
      Navigator.pop(context);
      _showSnackBar('Profile photo removed.');
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.4, // Increased height
          child: Column(
            children: [
              Text(
                "Profile Photo",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Upload from Gallery
              GestureDetector(
                onTap: _pickAndUploadImage,
                child: _buildPickerOption(
                  icon: Icons.add_photo_alternate_rounded,
                  label: "Upload from Gallery",
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Adjust (Re-crop/Upload)
              GestureDetector(
                onTap:
                    _pickAndUploadImage, // Re-uses pick logic which includes crop
                child: _buildPickerOption(
                  icon: Icons.crop_rotate_rounded,
                  label: "Adjust / Crop",
                  color: colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 16),

              // 3. Remove Photo
              if (_photoUrl.isNotEmpty)
                GestureDetector(
                  onTap: _removePhoto,
                    child: _buildPickerOption(
                      icon: Icons.delete_outline_rounded,
                      label: "Remove Photo",
                      color: colorScheme.error,
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    await prefs.setString('user_name', newName);
    await prefs.setString('avatar_seed', _avatarSeed);

    try {
      if (_currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .update({'name': newName, 'avatar_seed': _avatarSeed});
      }
    } catch (e) {
      debugPrint("Error saving profile to Firestore: $e");
    }

    if (mounted) {
      _showSnackBar('Profile updated!');
      Navigator.pop(context, true); // Return true to indicate update
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      _showSnackBar(
        'Logout failed: $e',
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final onSurface = theme.colorScheme.onSurface;
    final secondaryText = onSurface.withValues(alpha: 0.7);
    final inputFill = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerHighest;
    final inputFillMuted = inputFill.withValues(alpha: isDark ? 0.65 : 0.72);

    // Build the Profile UI
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Picture (Avatar)
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _showAvatarPicker,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        color: inputFill,
                      ),
                      child: ClipOval(
                        child: _isUploading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : _photoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _photoUrl,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) {
                                  return Icon(
                                    Icons.error_outline,
                                    color: theme.colorScheme.error,
                                  );
                                },
                                placeholder: (context, url) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: theme.colorScheme.primary,
                                    ),
                                  );
                                },
                              )
                            : Icon(
                                Icons.person,
                                size: 60,
                                color: theme.colorScheme.primary,
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Name Field
            TextField(
              controller: _nameController,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: "Your Name",
                labelStyle: TextStyle(color: secondaryText),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email Field (Read-only)
            TextField(
              controller: TextEditingController(
                text: _currentUser?.email ?? 'No email',
              ),
              readOnly: true,
              style: TextStyle(color: secondaryText),
              decoration: InputDecoration(
                labelText: "Email Address",
                labelStyle: TextStyle(color: secondaryText),
                filled: true,
                fillColor: inputFillMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Learning Level Info
            _buildLearningLevelCard(),
            const SizedBox(height: 24),

            // Settings / Support Section
            _buildSettingsItem(
              icon: Icons.notifications_active_outlined,
              title: "System Notification Settings",
              onTap: () async {
                await openAppSettings();
              },
            ),
            _buildSettingsItem(
              icon: Icons.history_edu_rounded,
              title: "Vocabulary History",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VocabularyHistoryScreen(),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              icon: Icons.history_toggle_off_rounded,
              title: "Verb History",
              onTap: _showVerbHistorySheet,
            ),

            if (_userRole == 'teacher')
              _buildSettingsItem(
                icon: Icons.feedback_outlined,
                title: "View Student Feedback",
                onTap: () => _navigateToTeacherFeedback(
                  collection: 'feedback',
                  title: 'Student Feedback',
                ),
              )
            else
              _buildSettingsItem(
                icon: Icons.feedback_outlined,
                title: "Give Feedback",
                onTap: _showFeedbackDialog,
              ),

            if (_userRole == 'teacher')
              _buildSettingsItem(
                icon: Icons.bug_report_outlined,
                title: "View Student Bugs",
                onTap: () => _navigateToTeacherFeedback(
                  collection: 'bug_reports',
                  title: 'Student Bug Reports',
                ),
                isDestructive: false,
              )
            else
              _buildSettingsItem(
                icon: Icons.bug_report_outlined,
                title: "Report a Bug",
                onTap: _showBugReportDialog,
                isDestructive: false, // Orange accent maybe?
              ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Log Out",
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningLevelCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surface;
    final borderColor = colorScheme.primary.withValues(alpha: isDark ? 0.42 : 0.22);
    final glowColor = colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.1);
    final mutedText = colorScheme.onSurface.withValues(alpha: 0.66);
    final supportingText = colorScheme.onSurface.withValues(alpha: 0.55);

    final bool isRetakeUnlocked =
        _currentLearningStage >= _retakePlacementUnlockLevel;
    final int levelsRemaining = isRetakeUnlocked
        ? 0
        : _retakePlacementUnlockLevel - _currentLearningStage;
    final String proficiencyLabel = _englishProficiencyLevel
        .split('(')
        .first
        .trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: colorScheme.onPrimary,
                  size: 34,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Proficiency',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      proficiencyLabel.isEmpty
                          ? _englishProficiencyLevel
                          : proficiencyLabel,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Learning Stage $_currentLearningStage - XP Level $_xpLevel',
                      style: TextStyle(
                        color: supportingText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(
            color: colorScheme.onSurface.withValues(alpha: 0.14),
            thickness: 1,
          ),
          if (_userRole != 'teacher') ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: isRetakeUnlocked
                  ? FilledButton.icon(
                      onPressed: _retakePlacementQuiz,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.quiz_rounded),
                      label: const Text(
                        'Retake Placement Quiz',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Unlock after $levelsRemaining more stages',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
  Future<void> _retakePlacementQuiz() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_currentLearningStage < _retakePlacementUnlockLevel) {
      if (!mounted) return;
      final levelsRemaining =
          _retakePlacementUnlockLevel - _currentLearningStage;
      _showSnackBar(
        "Retake unlocks at level $_retakePlacementUnlockLevel. "
        "$levelsRemaining more levels needed.",
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.onTertiaryContainer,
      );
      return;
    }

    final shouldRetake = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        title: Text(
          'Retake placement quiz?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Your proficiency level may change based on your new score.',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
            child: const Text('Retake'),
          ),
        ],
      ),
    );

    if (shouldRetake != true || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PlacementQuizScreen(isFirstTime: false),
      ),
    );

    if (!mounted) return;
    await _loadProfile();
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final Color color = isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _showVerbHistorySheet() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final List<MapEntry<String, int>> history = <MapEntry<String, int>>[];

    for (int i = 0; i < 90; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey = date.toIso8601String().split('T').first;
      final count =
          (prefs.getStringList('learned_verbs_$dateKey') ?? const <String>[])
              .length;
      if (count > 0) {
        history.add(MapEntry<String, int>(dateKey, count));
      }
    }

    final totalLearned =
        (prefs.getStringList('learned_verbs_ids') ?? const <String>[]).length;

    if (!mounted) return;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final sheetColors = sheetTheme.colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verb History',
                  style: TextStyle(
                    color: sheetColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total learned verbs: $totalLearned',
                  style: TextStyle(
                    color: sheetColors.onSurface.withValues(alpha: 0.72),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'No verb history found yet.',
                      style: TextStyle(
                        color: sheetColors.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: history.length,
                      separatorBuilder: (_, __) => Divider(
                        color: sheetColors.outlineVariant.withValues(alpha: 0.4),
                        height: 1,
                      ),
                      itemBuilder: (_, index) {
                        final item = history[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.history_rounded,
                            color: sheetColors.primary,
                          ),
                          title: Text(
                            item.key,
                            style: TextStyle(color: sheetColors.onSurface),
                          ),
                          trailing: Text(
                            '${item.value}',
                            style: TextStyle(
                              color: sheetColors.onSurface.withValues(
                                alpha: 0.72,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFeedbackDialog() {
    _showSubmissionDialog(
      title: "Give Feedback",
      hint: "Tell us what you love or what we can improve...",
      collection: "feedback",
      successMsg: "Thank you for your feedback!",
    );
  }

  void _showBugReportDialog() {
    _showSubmissionDialog(
      title: "Report a Bug",
      hint: "Describe the error (steps to reproduce, what happened)...",
      collection: "bug_reports",
      successMsg: "Bug report submitted. We'll look into it!",
      isBug: true,
    );
  }

  void _showSubmissionDialog({
    required String title,
    required String hint,
    required String collection,
    required String successMsg,
    bool isBug = false,
  }) {
    final TextEditingController textController = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModernDialog(
      context,
      title: title,
      content: TextField(
        controller: textController,
        style: TextStyle(color: colorScheme.onSurface),
        maxLines: 5,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: isDark
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.72)
              : colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      primaryButtonText: "Submit",
      onPrimaryPressed: () async {
        if (textController.text.trim().isEmpty) return;

        Navigator.pop(context); // Close dialog
        await _submitToFirestore(
          collection,
          textController.text.trim(),
          isBug: isBug,
        );
        if (mounted) {
          _showSnackBar(
            successMsg,
            backgroundColor: colorScheme.tertiaryContainer,
            foregroundColor: colorScheme.onTertiaryContainer,
          );
        }
      },
      secondaryButtonText: "Cancel",
      onSecondaryPressed: () => Navigator.pop(context),
      icon: isBug ? Icons.bug_report_outlined : Icons.feedback_outlined,
      accentColor: isBug ? colorScheme.tertiary : colorScheme.primary,
    );
  }

  Future<void> _submitToFirestore(
    String collection,
    String content, {
    bool isBug = false,
  }) async {
    try {
      if (_currentUser == null) return;

      await FirebaseFirestore.instance.collection(collection).add({
        'userId': _currentUser.uid,
        'userEmail': _currentUser.email,
        'userName': _nameController.text, // Use current input name
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'new', // For teacher/admin to track
        'type': isBug ? 'bug' : 'feedback',
      });

      // 1. Notify the User (Local)
      NotificationService().showNotification(
        isBug ? 'Bug Report Received' : 'Feedback Received',
        'Thanks! We have received your ${isBug ? 'report' : 'feedback'}.',
      );

      // 2. Notify the Teacher/Admin (Cloud)
      // We add a document to 'notifications' collection targeting 'teacher' role or specific admins
      // For now, we'll create a general notification that teachers listen to
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': isBug ? "New Bug Report" : "New Feedback",
        'message':
            "${_nameController.text} submitted ${isBug ? 'a bug report' : 'feedback'}: ${content.length > 30 ? '${content.substring(0, 30)}...' : content}",
        'timestamp': FieldValue.serverTimestamp(),
        'targetRole': 'teacher', // Targeted for teachers
        'type': isBug ? 'bug_alert' : 'feedback_alert',
        'relatedId': _currentUser.uid,
      });

      // 3. Send Push Notification to Teachers
      // Handled by Cloud Functions (notifyTeachersOnFeedback/notifyTeachersOnBugReport)
      // which triggers on document creation.
      debugPrint("Feedback submitted. Cloud function will notify teachers.");
    } catch (e) {
      debugPrint("Error submitting $collection: $e");
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        _showSnackBar(
          'Failed to submit. Please try again.',
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
        );
      }
    }
  }

  void _navigateToTeacherFeedback({
    required String collection,
    required String title,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TeacherFeedbackScreen(collection: collection, title: title),
      ),
    );
  }
}

