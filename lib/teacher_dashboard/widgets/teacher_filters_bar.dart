import 'package:flutter/material.dart';

class TeacherFiltersBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const TeacherFiltersBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(category.toUpperCase()),
              selected: isSelected,
              onSelected: (bool value) {
                onCategorySelected(category);
              },
              backgroundColor: isDark
                  ? const Color(0xFF1E1E2C)
                  : Colors.white.withValues(alpha: 0.9),
              selectedColor: const Color(0xFFFFD700),
              labelStyle: TextStyle(
                color: isSelected
                    ? const Color(0xFF1E1E2C)
                    : (isDark
                          ? Colors.white70
                          : onSurface.withValues(alpha: 0.74)),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                            ? Colors.white12
                            : onSurface.withValues(alpha: 0.18)),
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }
}
