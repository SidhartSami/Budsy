import 'dart:async';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:tutortyper_app/firebase_options.dart';
import 'package:tutortyper_app/views/login_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> with TickerProviderStateMixin {
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _confirmPassword;
  late final TextEditingController _username;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool _isUsernameValid = false;
  String? _usernameErrorMessage;

  // Add debounce timer
  Timer? _debounceTimer;

  // Helper for responsive sizing
  Size get size => MediaQuery.of(context).size;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _confirmPassword = TextEditingController();
    _username = TextEditingController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _username.dispose();
    _animationController.dispose();
    _debounceTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  Widget _buildInputField({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: size.height * 0.01),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: size.width * 0.04,
          ),
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: const Color(0xFF0C3C2B),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.02,
          ),
        ),
        style: TextStyle(
          color: Colors.black,
          fontSize: size.width * 0.04,
        ),
        cursorColor: const Color(0xFF0C3C2B),
        obscureText: isPassword,
        enabled: !_isLoading,
        enableSuggestions: false,
        autocorrect: false,
        textCapitalization: isPassword
            ? TextCapitalization.none
            : TextCapitalization.none,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(color: Color(0xFFF1EDE6)),
        child: Stack(
          children: [
            // Background decoration container (top area)
            Positioned(
              left: -size.width * 0.075,
              top: -size.height * 0.035,
              child: Container(
                width: size.width * 1.25,
                height: size.height * 0.625,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(minHeight: size.height * 0.9),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.05,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Lottie Animation
                            Lottie.asset(
                              'assets/animations/sahiwala.json',
                              width: size.width * 0.5,
                              height: size.height * 0.15,
                              fit: BoxFit.contain,
                            ),

                            SizedBox(height: size.height * 0.01),

                            // Register Title
                            Text(
                              'Register',
                              style: TextStyle(
                                color: const Color(0xFF0C3C2B),
                                fontSize: size.width * 0.08,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            SizedBox(height: size.height * 0.02),

                            // Username Field
                            _buildInputField(
                              icon: Icons.alternate_email,
                              controller: _username,
                              hint: 'Choose a unique username',
                              suffixIcon: _getSuffixIcon(),
                              onChanged: _onUsernameChanged,
                            ),

                            // Username validation messages
                            if (_usernameErrorMessage != null)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: size.height * 0.005,
                                  left: size.width * 0.1,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _usernameErrorMessage!,
                                    style: TextStyle(
                                      color: Colors.red[300],
                                      fontSize: size.width * 0.025,
                                    ),
                                  ),
                                ),
                              ),
                            if (_isUsernameValid && _username.text.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: size.height * 0.005,
                                  left: size.width * 0.1,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Username @${_username.text} is available!',
                                    style: TextStyle(
                                      color: Colors.green[300],
                                      fontSize: size.width * 0.025,
                                    ),
                                  ),
                                ),
                              ),

                            SizedBox(height: size.height * 0.02),

                            // Email Field
                            _buildInputField(
                              icon: Icons.email,
                              controller: _email,
                              hint: 'Enter your email',
                            ),

                            SizedBox(height: size.height * 0.02),

                            // Password Field
                            _buildInputField(
                              icon: Icons.lock,
                              controller: _password,
                              hint: 'Enter your password',
                              isPassword: true,
                            ),

                            SizedBox(height: size.height * 0.02),

                            // Confirm Password Field
                            _buildInputField(
                              icon: Icons.lock,
                              controller: _confirmPassword,
                              hint: 'Confirm your password',
                              isPassword: true,
                            ),

                            SizedBox(height: size.height * 0.04),

                            // Register Button
                            GestureDetector(
                              onTap: _isLoading ? null : _registerUser,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.08,
                                  vertical: size.height * 0.015,
                                ),
                                decoration: ShapeDecoration(
                                  color: _isLoading
                                      ? Colors.grey
                                      : const Color(0xFF0C3C2B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      size.width * 0.07,
                                    ),
                                  ),
                                  shadows: [
                                    BoxShadow(
                                      color: const Color(0x3F000000),
                                      blurRadius: size.width * 0.01,
                                      offset: Offset(0, size.height * 0.005),
                                    ),
                                  ],
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: size.width * 0.05,
                                        height: size.width * 0.05,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Register Now!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: size.width * 0.06,
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),

                            SizedBox(height: size.height * 0.015),

                            // Login Link
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginView(),
                                      ),
                                    ),
                              child: Text(
                                'Already have an account? Login here',
                                style: TextStyle(
                                  color: const Color(0xFF0C3C2B),
                                  fontSize: size.width * 0.04,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: const Color(0xFF0C3C2B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFieldBorderColor() {
    if (_username.text.isEmpty) return Colors.grey;
    if (_isCheckingUsername) return const Color.fromARGB(255, 104, 234, 243);
    if (_isUsernameValid) return Colors.green;
    return Colors.red;
  }

  Widget? _getSuffixIcon() {
    if (_username.text.isEmpty) return null;

    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color.fromARGB(255, 104, 234, 243),
          ),
        ),
      );
    }

    return Icon(
      _isUsernameValid ? Icons.check_circle : Icons.error,
      color: _isUsernameValid ? Colors.green : Colors.red,
    );
  }

  // NEW: Debounced username input handler
  void _onUsernameChanged(String username) {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    // Only clear states if username becomes empty
    if (username.isEmpty) {
      if (mounted) {
        setState(() {
          _usernameErrorMessage = null;
          _isUsernameValid = false;
          _isCheckingUsername = false;
        });
      }
      return;
    }

    // Start a new timer - check username after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 1200), () {
      // Double check the username hasn't changed and widget is still mounted
      if (mounted && _username.text.trim() == username.trim()) {
        _checkUsernameDebounced(username.trim());
      }
    });
  }

  // Separate method for debounced checking to avoid conflicts
  void _checkUsernameDebounced(String username) async {
    if (!mounted) return;

    // Check minimum length first
    if (username.length < 3) {
      if (mounted) {
        setState(() {
          _usernameErrorMessage = 'Username must be at least 3 characters';
          _isCheckingUsername = false;
          _isUsernameValid = false;
        });
      }
      return;
    }

    // Validate username format
    if (!_isValidUsername(username)) {
      if (mounted) {
        setState(() {
          _usernameErrorMessage =
              'Username can only contain letters, numbers, and underscores';
          _isCheckingUsername = false;
          _isUsernameValid = false;
        });
      }
      return;
    }

    // Start checking availability
    if (mounted) {
      setState(() {
        _isCheckingUsername = true;
        _usernameErrorMessage = null;
        _isUsernameValid = false;
      });
    }

    try {
      final userService = UserService();
      final isAvailable = await userService.isUsernameAvailable(username);

      if (mounted) {
        setState(() {
          _isUsernameValid = isAvailable;
          _isCheckingUsername = false;
          if (!isAvailable) {
            _usernameErrorMessage = 'Username @$username is already taken';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUsernameValid = false;
          _isCheckingUsername = false;
          _usernameErrorMessage = 'Error checking username availability';
        });
      }
    }
  }

  // Enhanced username checking - now only called during registration
  void _checkUsername(String username) async {
    // This method is now only used during final registration validation
    final userService = UserService();
    final isAvailable = await userService.isUsernameAvailable(username);

    if (!isAvailable) {
      throw Exception('Username is no longer available');
    }
  }

  bool _isValidUsername(String username) {
    // Username should be 3-20 characters, alphanumeric and underscores only
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  Future<void> _registerUser() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    final confirmPassword = _confirmPassword.text.trim();
    final username = _username.text.trim();

    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      _showDialog(
        DialogType.warning,
        'Missing Fields',
        'Please fill in all required fields.',
      );
      return;
    }

    if (!_isUsernameValid) {
      _showDialog(
        DialogType.warning,
        'Invalid Username',
        'Please choose a valid and available username.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showDialog(
        DialogType.warning,
        'Password Mismatch',
        'The passwords you entered do not match.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Starting registration process...');
      print('DEBUG: Email: $email, Username: $username');

      // Double-check username availability before proceeding
      final userService = UserService();
      final isUsernameStillAvailable = await userService.isUsernameAvailable(
        username,
      );

      if (!isUsernameStillAvailable) {
        _showDialog(
          DialogType.error,
          'Username Taken',
          'This username was recently taken. Please choose another one.',
        );
        return;
      }

      // Step 1: Create Firebase Auth account
      print('DEBUG: Creating Firebase Auth account...');
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        throw Exception('Failed to create user account');
      }

      print(
        'DEBUG: ✅ Firebase Auth account created with UID: ${userCredential.user!.uid}',
      );

      // Step 2: Create user profile in Firestore with username
      print('DEBUG: Creating Firestore user profile...');

      await userService.createUserProfile(
        userId: userCredential.user!.uid,
        email: email.toLowerCase(),
        displayName: username,
        username: username.toLowerCase(),
        photoUrl: userCredential.user!.photoURL,
      );

      print('DEBUG: ✅ Firestore user profile created');

      // Step 3: Verify the document was actually created
      print('DEBUG: Verifying Firestore document creation...');
      final createdUser = await userService.getCurrentUser();

      if (createdUser == null) {
        throw Exception('Failed to verify user document creation');
      }

      print(
        'DEBUG: ✅ User document verified: ${createdUser.email}, Username: ${createdUser.username}',
      );

      // Step 4: Send email verification
      print('DEBUG: Sending email verification...');
      await userCredential.user?.sendEmailVerification();
      print('DEBUG: ✅ Email verification sent');

      _showDialog(
        DialogType.success,
        'Registration Successful',
        'Account created successfully with username @$username! A verification email has been sent to $email. Please check your inbox and verify your email before logging in.',
      );

      print('DEBUG: ✅ Registration process completed successfully');
    } on FirebaseAuthException catch (e) {
      print('DEBUG: ❌ FirebaseAuth error: ${e.code} - ${e.message}');

      if (e.code == 'weak-password') {
        _showDialog(
          DialogType.warning,
          'Weak Password',
          'Please choose a stronger password (at least 6 characters).',
        );
      } else if (e.code == 'email-already-in-use') {
        _showDialog(
          DialogType.error,
          'Email Already in Use',
          'This email is already associated with another account.',
        );
      } else if (e.code == 'invalid-email') {
        _showDialog(
          DialogType.error,
          'Invalid Email',
          'Please enter a valid email address.',
        );
      } else {
        _showDialog(
          DialogType.error,
          'Authentication Error',
          e.message ?? 'An authentication error occurred.',
        );
      }
    } catch (e) {
      print('DEBUG: ❌ Unexpected error during registration: $e');
      _showDialog(
        DialogType.error,
        'Registration Failed',
        'An error occurred during registration: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDialog(DialogType type, String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkOnPress: () {
        // Clear form after successful registration
        if (type == DialogType.success) {
          _email.clear();
          _password.clear();
          _confirmPassword.clear();
          _username.clear();
        }
      },
    ).show();
  }
}