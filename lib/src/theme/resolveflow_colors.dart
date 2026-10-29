import 'package:flutter/material.dart';

/// ResolveFlow brand color system and WCAG AA contrast mappings.
abstract final class AppColors {
  // Raw Palette Hex Constants
  static const Color evergreen = Color(0xFF132A13);
  static const Color hunterGreen = Color(0xFF31572C);
  static const Color fern = Color(0xFF4F772D);
  static const Color palmLeaf = Color(0xFF90A955);
  static const Color limeCream = Color(0xFFECF39E);

  // Semantic mappings tailored for ResolveFlow UI
  static const Color primary = fern;
  static const Color primaryDark = hunterGreen;
  static const Color backgroundDark = evergreen;
  static const Color accent = palmLeaf;
  static const Color surfaceHighlight = limeCream;

  // Text on colors (for WCAG AA contrast compliance)
  static const Color onPrimary = Colors.white;
  static const Color onSurfaceHighlight = Color(0xFF132A13); // High contrast text over Lime Cream
  static const Color onBackgroundDark = Colors.white;
}

