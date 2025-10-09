import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Heading Styles
  static TextStyle get heading1 => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    letterSpacing: -0.5,
  );
  
  static TextStyle get heading2 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: -0.25,
  );
  
  static TextStyle get heading3 => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );
  
  static TextStyle get heading4 => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
  );
  
  // Body Styles
  static TextStyle get body1 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );
  
  static TextStyle get body2 => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );
  
  static TextStyle get body3 => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.3,
  );
  
  // Button Styles
  static TextStyle get buttonLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static TextStyle get buttonMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
  
  // Caption and Label Styles
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );
  
  static TextStyle get label => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
  );
  
  // Special Styles
  static TextStyle get noteTitle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.3,
  );
  
  static TextStyle get notePreview => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );
  
  static TextStyle get noteDate => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );
  
  // Dark theme variants
  static TextStyle heading1Dark = heading1.copyWith(color: AppColors.onSurfaceDark);
  static TextStyle heading2Dark = heading2.copyWith(color: AppColors.onSurfaceDark);
  static TextStyle heading3Dark = heading3.copyWith(color: AppColors.onSurfaceDark);
  static TextStyle heading4Dark = heading4.copyWith(color: AppColors.onSurfaceDark);
  static TextStyle body1Dark = body1.copyWith(color: AppColors.onSurfaceDark);
  static TextStyle body2Dark = body2.copyWith(color: AppColors.onSurfaceVariantDark);
  static TextStyle body3Dark = body3.copyWith(color: AppColors.onSurfaceVariantDark);
  static TextStyle labelDark = label.copyWith(color: AppColors.onSurfaceDark);
  static TextStyle noteTitleDark = noteTitle.copyWith(color: AppColors.onSurfaceDark);
  static TextStyle notePreviewDark = notePreview.copyWith(color: AppColors.onSurfaceVariantDark);
  static TextStyle noteDateDark = noteDate.copyWith(color: AppColors.onSurfaceVariantDark);
}
