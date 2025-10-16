// widgets/avatar_selection_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AvatarSelectionWidget extends StatefulWidget {
  final String? selectedAvatar;
  final String? gender;
  final Function(String) onAvatarSelected;
  final bool showCustomOption;

  const AvatarSelectionWidget({
    super.key,
    this.selectedAvatar,
    this.gender,
    required this.onAvatarSelected,
    this.showCustomOption = true,
  });

  @override
  State<AvatarSelectionWidget> createState() => _AvatarSelectionWidgetState();
}

class _AvatarSelectionWidgetState extends State<AvatarSelectionWidget> {
  String? _selectedAvatar;

  static const Color _primaryGreen = Color(0xFF0C3C2B);

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.selectedAvatar;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildDefaultAvatarOption()),
          const SizedBox(width: 12),
          if (widget.showCustomOption)
            Expanded(child: _buildCustomAvatarOption()),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatarOption() {
    final defaultAvatar = AvatarManager.getDefaultAvatarForGender(
      widget.gender,
    );
    final isSelected = _selectedAvatar == defaultAvatar;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedAvatar = defaultAvatar;
        });
        widget.onAvatarSelected(defaultAvatar);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryGreen.withOpacity(0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _primaryGreen : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(defaultAvatar, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check_circle, color: _primaryGreen, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(
                  'Default',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? _primaryGreen : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAvatarOption() {
    final isSelected = _selectedAvatar == 'custom';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedAvatar = 'custom';
        });
        widget.onAvatarSelected('custom');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryGreen.withOpacity(0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? _primaryGreen.withOpacity(0.1)
                    : Colors.grey.shade200,
                border: Border.all(
                  color: isSelected ? _primaryGreen : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                color: isSelected ? _primaryGreen : Colors.grey.shade600,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check_circle, color: _primaryGreen, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(
                  'Custom',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? _primaryGreen : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AvatarManager {
  static const String maleDefaultAvatar = 'assets/avatars/male.png';
  static const String femaleDefaultAvatar = 'assets/avatars/female.png';

  static String getDefaultAvatarForGender(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return maleDefaultAvatar;
      case 'female':
        return femaleDefaultAvatar;
      default:
        return maleDefaultAvatar;
    }
  }

  static bool isPredefinedAvatar(String? avatarPath) {
    if (avatarPath == null || avatarPath == 'custom') return false;
    return avatarPath == maleDefaultAvatar || avatarPath == femaleDefaultAvatar;
  }

  static String getGenderFromAvatarPath(String avatarPath) {
    if (avatarPath == maleDefaultAvatar) return 'male';
    if (avatarPath == femaleDefaultAvatar) return 'female';
    return 'male';
  }
}
