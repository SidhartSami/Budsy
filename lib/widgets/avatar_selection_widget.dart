// widgets/avatar_selection_widget.dart
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.selectedAvatar;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Avatar',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        
        // Avatar Options
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Default Avatar Option
            _buildDefaultAvatarOption(),
            
            // Custom Avatar Option
            if (widget.showCustomOption)
              _buildCustomAvatarOption(),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Selected Avatar Info
        if (_selectedAvatar != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 104, 234, 243).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromARGB(255, 104, 234, 243).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: const Color.fromARGB(255, 104, 234, 243),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedAvatar == 'custom' 
                        ? 'Custom photo selected'
                        : 'Default avatar selected',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 104, 234, 243),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCustomAvatarOption() {
    final isSelected = _selectedAvatar == 'custom';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAvatar = 'custom';
        });
        widget.onAvatarSelected('custom');
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected 
                    ? const Color.fromARGB(255, 104, 234, 243)
                    : Colors.grey[300]!,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: const Color.fromARGB(255, 104, 234, 243).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
              child: Icon(
                Icons.camera_alt,
                color: isSelected 
                    ? const Color.fromARGB(255, 104, 234, 243)
                    : Colors.grey[600],
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Custom',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected 
                  ? const Color.fromARGB(255, 104, 234, 243)
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatarOption() {
    final defaultAvatar = AvatarManager.getDefaultAvatarForGender(widget.gender);
    final isSelected = _selectedAvatar == defaultAvatar;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAvatar = defaultAvatar;
        });
        widget.onAvatarSelected(defaultAvatar);
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected 
                    ? const Color.fromARGB(255, 104, 234, 243)
                    : Colors.grey[300]!,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: const Color.fromARGB(255, 104, 234, 243).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: ClipOval(
              child: Image.asset(
                defaultAvatar,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Default',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected 
                  ? const Color.fromARGB(255, 104, 234, 243)
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for avatar management
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
        return maleDefaultAvatar; // Default to male avatar
    }
  }

  static bool isPredefinedAvatar(String? avatarPath) {
    if (avatarPath == null || avatarPath == 'custom') return false;
    return avatarPath == maleDefaultAvatar || avatarPath == femaleDefaultAvatar;
  }

  static String getGenderFromAvatarPath(String avatarPath) {
    if (avatarPath == maleDefaultAvatar) return 'male';
    if (avatarPath == femaleDefaultAvatar) return 'female';
    return 'male'; // Default
  }
}
