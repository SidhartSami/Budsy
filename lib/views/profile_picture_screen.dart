// views/profile_picture_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/widgets/avatar_selection_widget.dart';

class ProfilePictureScreen extends StatefulWidget {
  final UserModel currentUser;

  const ProfilePictureScreen({super.key, required this.currentUser});

  @override
  State<ProfilePictureScreen> createState() => _ProfilePictureScreenState();
}

class _ProfilePictureScreenState extends State<ProfilePictureScreen> {
  final UserService _userService = UserService();

  File? _selectedImage;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _removeImage = false;
  String? _selectedAvatar;
  bool _useCustomPhoto = false;

  static const Color _primaryGreen = Color(0xFF0C3C2B);

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.currentUser.predefinedAvatar;
    _useCustomPhoto =
        widget.currentUser.photoUrl != null &&
        widget.currentUser.predefinedAvatar == null;
  }

  void _onFieldChanged() {
    final hasImageChanges = _selectedImage != null || _removeImage;
    final hasAvatarChanges =
        _selectedAvatar != widget.currentUser.predefinedAvatar;

    setState(() {
      _hasChanges = hasImageChanges || hasAvatarChanges;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Profile Photo',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _primaryGreen,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _primaryGreen,
                        ),
                      ),
                    )
                  : Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: _primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 32),
          _buildProfilePictureSection(),
          const SizedBox(height: 40),
          _buildAvatarSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: ClipOval(child: _buildProfileImage()),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.currentUser.displayName,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${widget.currentUser.username}',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'New photo selected',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileImage() {
    if (_removeImage && _selectedImage == null) {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Text(
            widget.currentUser.displayName.isNotEmpty
                ? widget.currentUser.displayName[0].toUpperCase()
                : 'U',
            style: GoogleFonts.inter(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 40,
            ),
          ),
        ),
      );
    }

    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    }

    if (_selectedAvatar != null &&
        _selectedAvatar != 'custom' &&
        AvatarManager.isPredefinedAvatar(_selectedAvatar)) {
      return Image.asset(
        _selectedAvatar!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    }

    if (widget.currentUser.photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.currentUser.photoUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.error),
        ),
      );
    }

    if (widget.currentUser.gender != null) {
      final defaultAvatar = AvatarManager.getDefaultAvatarForGender(
        widget.currentUser.gender,
      );
      return Image.asset(
        defaultAvatar,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    }

    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Text(
          widget.currentUser.displayName.isNotEmpty
              ? widget.currentUser.displayName[0].toUpperCase()
              : 'U',
          style: GoogleFonts.inter(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Choose Avatar',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryGreen,
              secondary: _primaryGreen,
            ),
          ),
          child: AvatarSelectionWidget(
            selectedAvatar: _selectedAvatar,
            gender: widget.currentUser.gender,
            onAvatarSelected: (avatar) {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedAvatar = avatar;
                _useCustomPhoto = avatar == 'custom';
                if (_useCustomPhoto) {
                  _selectedImage = null;
                  _removeImage = false;
                }
              });
              _onFieldChanged();
            },
          ),
        ),
      ],
    );
  }

  void _showImagePickerOptions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.camera_alt, color: _primaryGreen),
                title: Text('Take Photo', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: _primaryGreen),
                title: Text('Choose from Library', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (widget.currentUser.photoUrl != null ||
                  _selectedImage != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Remove Photo',
                    style: GoogleFonts.inter(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeCurrentImage();
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _removeImage = false;
        });
        _onFieldChanged();
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  void _removeCurrentImage() {
    setState(() {
      _selectedImage = null;
      _removeImage = true;
    });
    _onFieldChanged();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.updateUserProfile(
        profileImage: _useCustomPhoto ? _selectedImage : null,
        removeImage: _removeImage,
        predefinedAvatar: _useCustomPhoto ? null : _selectedAvatar,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        setState(() {
          _hasChanges = false;
          _selectedImage = null;
          _removeImage = false;
        });

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showErrorDialog('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Error',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                color: _primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
