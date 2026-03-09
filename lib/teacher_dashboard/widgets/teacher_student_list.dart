import 'package:flutter/material.dart';

class TeacherStudentsHeader extends StatelessWidget {
  final int studentCount;
  final VoidCallback onFindMissing;

  const TeacherStudentsHeader({
    super.key,
    required this.studentCount,
    required this.onFindMissing,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              "$studentCount Students",
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: onFindMissing,
            icon: const Icon(Icons.person_search_rounded, size: 16),
            label: const Text("Find Missing"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orangeAccent,
              iconSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class TeacherStageLegend extends StatelessWidget {
  const TeacherStageLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : onSurface.withValues(alpha: 0.12),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 8,
        children: const [
          _LegendItem("Level", Color(0xFF4FACFE)),
          _LegendItem("Completed", Color(0xFF2ED573)),
          _LegendItem("Assessments", Color(0xFFFFA502)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : onSurface.withValues(alpha: 0.62),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class TeacherStudentListItem extends StatelessWidget {
  final String name;
  final String email;
  final String photoUrl;
  final bool isBlocked;
  final String activeText;
  final String? roleLabel;
  final VoidCallback onTap;
  final Widget difficultyBadge;
  final Widget progressWidget;
  final Widget menuButton;

  const TeacherStudentListItem({
    super.key,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.isBlocked,
    required this.activeText,
    required this.roleLabel,
    required this.onTap,
    required this.difficultyBadge,
    required this.progressWidget,
    required this.menuButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E2C)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : onSurface.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: photoUrl.isEmpty
                        ? const LinearGradient(
                            colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    image: photoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: photoUrl.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (isBlocked) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.block,
                              size: 14,
                              color: Colors.redAccent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.62),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF00F2FE,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              activeText == "Never" ? "Inactive" : activeText,
                              style: const TextStyle(
                                color: Color(0xFF00F2FE),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          difficultyBadge,
                          if (roleLabel != null)
                            Text(
                              roleLabel!,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.yellowAccent
                                    : const Color(0xFFB45309),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                progressWidget,
                menuButton,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
