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
        
        // Avatar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _getAvatarCount() + (widget.showCustomOption ? 1 : 0),
          itemBuilder: (context, index) {
            if (widget.showCustomOption && index == _getAvatarCount()) {
              return _buildCustomAvatarOption();
            }
            
            final avatarPath = _getAvatarPath(index);
            final isSelected = _selectedAvatar == avatarPath;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAvatar = avatarPath;
                });
                widget.onAvatarSelected(avatarPath);
              },
              child: Container(
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
                  child: SvgPicture.asset(
                    avatarPath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
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
                        : 'Avatar selected',
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
      child: Container(
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
    );
  }

  int _getAvatarCount() {
    return 5; // We have 5 avatars for each gender
  }

  String _getAvatarPath(int index) {
    final gender = widget.gender ?? 'male';
    return 'assets/avatars/$gender/avatar_${index + 1}.svg';
  }
}

// Helper class for avatar management
class AvatarManager {
  static const List<String> maleAvatars = [
    'assets/avatars/male/avatar_1.svg',
    'assets/avatars/male/avatar_2.svg',
    'assets/avatars/male/avatar_3.svg',
    'assets/avatars/male/avatar_4.svg',
    'assets/avatars/male/avatar_5.svg',
  ];

  static const List<String> femaleAvatars = [
    'assets/avatars/female/avatar_1.svg',
    'assets/avatars/female/avatar_2.svg',
    'assets/avatars/female/avatar_3.svg',
    'assets/avatars/female/avatar_4.svg',
    'assets/avatars/female/avatar_5.svg',
  ];

  static List<String> getAvatarsForGender(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return maleAvatars;
      case 'female':
        return femaleAvatars;
      case 'all':
        return [...maleAvatars, ...femaleAvatars]; // Show both male and female avatars
      default:
        return [...maleAvatars, ...femaleAvatars]; // Default to all avatars
    }
  }

  static bool isPredefinedAvatar(String? avatarPath) {
    if (avatarPath == null || avatarPath == 'custom') return false;
    return maleAvatars.contains(avatarPath) || femaleAvatars.contains(avatarPath);
  }

  static String getGenderFromAvatarPath(String avatarPath) {
    if (avatarPath.contains('/male/')) return 'male';
    if (avatarPath.contains('/female/')) return 'female';
    return 'male'; // Default
  }
}
