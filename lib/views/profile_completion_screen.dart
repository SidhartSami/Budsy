// views/profile_completion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/main.dart';
import 'package:tutortyper_app/widgets/avatar_selection_widget.dart';
import 'dart:io';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  DateTime? selectedBirthDate;
  File? selectedImage;
  String? imageUrl;
  bool showBirthDate = false;
  bool showOnlineStatus = true;
  bool isLoading = false;
  bool isUploadingImage = false;
  String? selectedGender;
  String? selectedAvatar;
  bool useCustomPhoto = false;

  final ImagePicker _picker = ImagePicker();

  static const Color _primaryGreen = Color(0xFF0C3C2B);

  int _currentStep = 0;

  // Track which type of avatar is selected: 'none', 'predefined', 'custom'
  String _avatarType = 'none';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primaryGreen,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, size: 24),
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                splashRadius: 24,
              )
            : null,
        title: Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(_primaryGreen),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_currentStep + 1}/3',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Form(key: _formKey, child: _buildCurrentStep()),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildInfoStep();
      case 1:
        return _buildPhotoStep();
      case 2:
        return _buildPrivacyStep();
      default:
        return Container();
    }
  }

  Widget _buildPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add a profile photo',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how you want to appear',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),

        // Profile Avatar Display
        Center(
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _avatarType != 'none'
                        ? _primaryGreen.withOpacity(0.3)
                        : Colors.grey.shade300,
                    width: 3,
                  ),
                  boxShadow: _avatarType != 'none'
                      ? [
                          BoxShadow(
                            color: _primaryGreen.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(child: _buildProfileAvatar()),
              ),
              if (isUploadingImage)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              if (_avatarType != 'none')
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // Photo Source Options
        Text(
          'Choose your style',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Custom Photo Options
        _buildPhotoSourceCard(
          icon: Icons.camera_alt_rounded,
          title: 'Take a Photo',
          subtitle: 'Use your camera',
          onTap: () => _pickImage(ImageSource.camera),
          isSelected: _avatarType == 'custom' && selectedImage != null,
        ),
        const SizedBox(height: 12),
        _buildPhotoSourceCard(
          icon: Icons.photo_library_rounded,
          title: 'Choose from Gallery',
          subtitle: 'Pick an existing photo',
          onTap: () => _pickImage(ImageSource.gallery),
          isSelected: _avatarType == 'custom' && selectedImage != null,
        ),

        const SizedBox(height: 24),

        // Divider with text
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 1,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),

        const SizedBox(height: 24),

        // Avatar Selection - Now always available
        _buildPhotoSourceCard(
          icon: Icons.face_rounded,
          title: 'Choose an Avatar',
          subtitle: 'Select from our collection',
          onTap: () => _showAvatarSelectionBottomSheet(),
          isSelected: _avatarType == 'predefined',
        ),

        const SizedBox(height: 24),

        // Skip option
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _avatarType = 'none';
                selectedImage = null;
                imageUrl = null;
                selectedAvatar = null;
                useCustomPhoto = false;
              });
            },
            child: Text(
              'Skip for now',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSourceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryGreen.withOpacity(0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryGreen.withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? _primaryGreen : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _primaryGreen : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    // Show predefined avatar
    if (_avatarType == 'predefined' &&
        selectedAvatar != null &&
        AvatarManager.isPredefinedAvatar(selectedAvatar)) {
      return Image.asset(
        selectedAvatar!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    }

    // Show custom photo (local or uploaded)
    if (_avatarType == 'custom') {
      if (selectedImage != null) {
        return Image.file(
          selectedImage!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        );
      }
      if (imageUrl != null) {
        return Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        );
      }
    }

    // Default placeholder
    return Container(
      color: Colors.grey.shade100,
      child: Icon(Icons.person_outline, size: 60, color: Colors.grey.shade400),
    );
  }

  void _showAvatarSelectionBottomSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose an Avatar',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select your preferred avatar style',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Avatar Grid
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildAvatarOption(
                      AvatarManager.getDefaultAvatarForGender(selectedGender),
                      'Default',
                    ),
                    // Add more avatar options here in the future
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarOption(String avatarPath, String label) {
    final isSelected =
        selectedAvatar == avatarPath && _avatarType == 'predefined';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          selectedAvatar = avatarPath;
          _avatarType = 'predefined';
          useCustomPhoto = false;
          selectedImage = null;
          imageUrl = null;
        });
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _primaryGreen : Colors.grey.shade300,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _primaryGreen.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(child: Image.asset(avatarPath, fit: BoxFit.cover)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? _primaryGreen : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about yourself',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us personalize your experience',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Gender',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildGenderOption('Male', 'male')),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderOption('Female', 'female')),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Birthday',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectBirthDate(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedBirthDate != null
                      ? '${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}'
                      : 'Select your birthday',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: selectedBirthDate != null
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (selectedBirthDate != null) ...[
          const SizedBox(height: 12),
          _getAgeValidationWidget(),
        ],
      ],
    );
  }

  Widget _buildPrivacyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy settings',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Control what others can see',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        _buildPrivacyToggle(
          icon: Icons.cake_outlined,
          title: 'Show Birthday',
          subtitle: 'Let friends see your birthday',
          value: showBirthDate,
          onChanged: (value) => setState(() => showBirthDate = value),
        ),
        const SizedBox(height: 16),
        _buildPrivacyToggle(
          icon: Icons.circle,
          title: 'Show Online Status',
          subtitle: 'Let friends see when you\'re online',
          value: showOnlineStatus,
          onChanged: (value) => setState(() => showOnlineStatus = value),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String label, String value) {
    final isSelected = selectedGender == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          selectedGender = value;
          // Reset avatar if changing gender
          if (_avatarType == 'predefined') {
            selectedAvatar = null;
            _avatarType = 'none';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryGreen.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? _primaryGreen : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primaryGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: (newValue) {
                HapticFeedback.lightImpact();
                onChanged(newValue);
              },
              activeColor: _primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canProceed() && !isLoading ? _handleNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _currentStep == 2 ? 'Complete' : 'Next',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _getAgeValidationWidget() {
    final age = _calculateAge(selectedBirthDate!);
    final isValid = age >= 16;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? _primaryGreen.withOpacity(0.1) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? _primaryGreen.withOpacity(0.3) : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error_outline,
            color: isValid ? _primaryGreen : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isValid ? 'Age: $age years' : 'You must be at least 16 years old',
              style: GoogleFonts.inter(
                color: isValid ? _primaryGreen : Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return selectedGender != null &&
            selectedBirthDate != null &&
            _isValidAge();
      case 1:
        return true; // Can skip photo selection
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _handleNext() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeProfile();
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool _isValidAge() {
    if (selectedBirthDate == null) return false;
    return _calculateAge(selectedBirthDate!) >= 16;
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: _primaryGreen)),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedBirthDate) {
      setState(() {
        selectedBirthDate = picked;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
          _avatarType = 'custom';
          useCustomPhoto = true;
          selectedAvatar = null;
          isUploadingImage = true;
        });

        await _uploadImageToStorage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _uploadImageToStorage() async {
    if (selectedImage == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      final uploadTask = storageRef.putFile(selectedImage!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        imageUrl = downloadUrl;
        isUploadingImage = false;
      });
    } catch (e) {
      setState(() {
        isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading: $e')));
      }
    }
  }

  Future<void> _completeProfile() async {
    if (selectedBirthDate == null || !_isValidAge() || selectedGender == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Determine what to save based on avatar type
      String? photoUrlToSave;
      String? predefinedAvatarToSave;

      if (_avatarType == 'custom') {
        photoUrlToSave = imageUrl;
        predefinedAvatarToSave = null;
      } else if (_avatarType == 'predefined') {
        photoUrlToSave = null;
        predefinedAvatarToSave = selectedAvatar;
      } else {
        // If no avatar selected, use default for gender
        photoUrlToSave = null;
        predefinedAvatarToSave = AvatarManager.getDefaultAvatarForGender(
          selectedGender,
        );
      }

      await _userService.updateUserProfile(
        birthDate: selectedBirthDate!,
        showBirthDate: showBirthDate,
        showOnlineStatus: showOnlineStatus,
        photoUrl: photoUrlToSave,
        profileCompleted: true,
        gender: selectedGender,
        predefinedAvatar: predefinedAvatarToSave,
      );

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const NotesView()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
