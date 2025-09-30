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

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.currentUser.predefinedAvatar;
    _useCustomPhoto = widget.currentUser.photoUrl != null && 
                     widget.currentUser.predefinedAvatar == null;
  }

  void _onFieldChanged() {
    final hasImageChanges = _selectedImage != null || _removeImage;
    final hasAvatarChanges = _selectedAvatar != widget.currentUser.predefinedAvatar;

    setState(() {
      _hasChanges = hasImageChanges || hasAvatarChanges;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Profile Picture',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture Section
            _buildProfilePictureSection(),

            const SizedBox(height: 30),

            // Form Fields
            _buildFormFields(),

            const SizedBox(height: 30),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromARGB(255, 104, 234, 243),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildProfileImage(),
            ),

            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 104, 234, 243),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  onPressed: _showImagePickerOptions,
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          'Tap camera to change photo',
          style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[600]),
        ),

        if (_selectedImage != null) ...[
          const SizedBox(height: 8),
          Text(
            'New photo selected',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: const Color.fromARGB(255, 104, 234, 243),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        if (_removeImage && _selectedImage == null) ...[
          const SizedBox(height: 8),
          Text(
            'Photo will be removed',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileImage() {
    // If removing image and no new image selected
    if (_removeImage && _selectedImage == null) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        child: Text(
          widget.currentUser.displayName.isNotEmpty
              ? widget.currentUser.displayName[0].toUpperCase()
              : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 48,
          ),
        ),
      );
    }

    // If new image selected
    if (_selectedImage != null) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        backgroundImage: FileImage(_selectedImage!),
      );
    }

    // If using predefined avatar
    if (_selectedAvatar != null && _selectedAvatar != 'custom' && 
        AvatarManager.isPredefinedAvatar(_selectedAvatar)) {
      return ClipOval(
        child: SvgPicture.asset(
          _selectedAvatar!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    // If user has existing photo URL
    if (widget.currentUser.photoUrl != null) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        backgroundImage: CachedNetworkImageProvider(widget.currentUser.photoUrl!),
      );
    }

    // Default to initials
    return CircleAvatar(
      radius: 60,
      backgroundColor: const Color.fromARGB(255, 104, 234, 243),
      child: Text(
        widget.currentUser.displayName.isNotEmpty
            ? widget.currentUser.displayName[0].toUpperCase()
            : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 48,
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar Selection - Show all avatars regardless of gender
        AvatarSelectionWidget(
          selectedAvatar: _selectedAvatar,
          gender: 'all', // Show both male and female avatars
          onAvatarSelected: (avatar) {
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
      ],
    );
  }



  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? hintText,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(
              icon,
              color: const Color.fromARGB(255, 104, 234, 243),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 104, 234, 243),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_hasChanges) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 104, 234, 243),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _resetChanges,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Reset Changes',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 30),

        // Account Actions
        _buildAccountActions(),
      ],
    );
  }

  Widget _buildAccountActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Actions',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),

          const SizedBox(height: 16),

          _buildActionTile(
            icon: Icons.visibility_off,
            title: 'Privacy Settings',
            subtitle: 'Manage who can see your profile',
            onTap: () => _showComingSoonDialog('Privacy Settings'),
          ),

          _buildActionTile(
            icon: Icons.block,
            title: 'Blocked Users',
            subtitle: 'Manage blocked users',
            onTap: () => _showComingSoonDialog('Blocked Users'),
          ),

          _buildActionTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            color: Colors.red,
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[600]),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          color: color ?? Colors.grey[700],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Profile Photo',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),

                  _buildImagePickerOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),

                  if (widget.currentUser.photoUrl != null)
                    _buildImagePickerOption(
                      icon: Icons.delete,
                      label: 'Remove',
                      color: Colors.red,
                      onTap: _removeCurrentImage,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? const Color.fromARGB(255, 104, 234, 243))
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? const Color.fromARGB(255, 104, 234, 243),
              size: 30,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
              color: color ?? Colors.grey[700],
            ),
          ),
        ],
      ),
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

  void _resetChanges() {
    setState(() {
      _selectedImage = null;
      _removeImage = false;
      _selectedAvatar = widget.currentUser.predefinedAvatar;
      _useCustomPhoto = widget.currentUser.photoUrl != null && 
                       widget.currentUser.predefinedAvatar == null;
      _hasChanges = false;
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update user profile - only avatar
      await _userService.updateUserProfile(
        profileImage: _useCustomPhoto ? _selectedImage : null,
        removeImage: _removeImage,
        predefinedAvatar: _useCustomPhoto ? null : _selectedAvatar,
      );

      _showSuccessDialog('Profile updated successfully!');

      setState(() {
        _hasChanges = false;
        _selectedImage = null;
        _removeImage = false;
      });

      // Refresh the current user data
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      _showErrorDialog('Failed to update profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showComingSoonDialog(String feature) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: 'Coming Soon',
      desc: '$feature will be available in a future update!',
      btnOkOnPress: () {},
    ).show();
  }

  void _showDeleteAccountDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Delete Account',
      desc:
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        // TODO: Implement account deletion
        _showComingSoonDialog('Account Deletion');
      },
      btnOkColor: Colors.red,
      btnOkText: 'Delete',
      btnCancelText: 'Cancel',
    ).show();
  }

  void _showSuccessDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'Success',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }
}
