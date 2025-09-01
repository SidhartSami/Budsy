import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:tutortyper_app/views/register_view.dart';
import 'package:tutortyper_app/main.dart';
import 'package:tutortyper_app/services/user_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _username;
  late final TextEditingController _password;
  bool _isLoading = false;

  @override
  void initState() {
    _username = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Lottie.asset(
              'assets/animations/login_view.json',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(child: Text('Background not available')),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Login',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _username,
                    decoration: InputDecoration(
                      hintText: 'Enter Username',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(200),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      prefixIcon: const Icon(
                        Icons.alternate_email,
                        color: Colors.grey,
                      ),
                    ),
                    enableSuggestions: false,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    style: const TextStyle(color: Colors.black),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(200),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                    ),
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    style: const TextStyle(color: Colors.black),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 120,
                    child: NeumorphicButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: NeumorphicStyle(
                        color: _isLoading
                            ? Colors.grey[300]
                            : const Color.fromARGB(255, 104, 234, 243),
                        boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(200),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const RegisterView(),
                              ),
                            );
                          },
                    child: const Text(
                      'Don\'t have an account? Register Now!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final username = _username.text.trim();
    final password = _password.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields", Colors.orange);
      return;
    }

    if (!_isValidUsername(username)) {
      _showSnackBar("Please enter a valid username", Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Starting username-based login process...');
      print('DEBUG: Username: $username');

      // Step 1: Find user by username to get their email
      final userService = UserService();
      final userByUsername = await userService.findUserByUsername(username);

      if (userByUsername == null) {
        _showSnackBar("Username not found", Colors.red);
        return;
      }

      final email = userByUsername.email;
      print('DEBUG: Found user with email: $email');

      // Step 2: Sign in with Firebase Auth using the email
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        throw Exception('Login failed - no user returned');
      }

      print('DEBUG: ✅ Firebase Auth login successful');
      print('DEBUG: User ID: ${userCredential.user!.uid}');
      print('DEBUG: User Email: ${userCredential.user!.email}');
      print('DEBUG: Email Verified: ${userCredential.user!.emailVerified}');

      // Step 3: Verify user document exists in Firestore
      final existingUser = await userService.getCurrentUser();

      if (existingUser == null) {
        print(
          'DEBUG: ⚠️ User document missing in Firestore - this should not happen during login',
        );
        throw Exception('User profile not found in database');
      } else {
        print(
          'DEBUG: ✅ User document exists in Firestore: ${existingUser.email}, Username: @${existingUser.username}',
        );
      }

      // Step 4: Update online status
      await userService.updateOnlineStatus(true);
      print('DEBUG: ✅ Online status updated');

      // Step 5: Check email verification and navigate
      if (userCredential.user!.emailVerified) {
        print('DEBUG: ✅ Email verified - navigating to home');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const NotesView()),
          );
        }
      } else {
        print('DEBUG: ⚠️ Email not verified - showing verification dialog');
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.scale,
          title: 'Email Not Verified',
          desc:
              'Please verify your email address before logging in. Check your inbox for verification email.',
          btnOkOnPress: () {
            // Optionally sign out the user since they can't proceed
            FirebaseAuth.instance.signOut();
          },
          btnOkColor: Colors.orange,
        ).show();
      }

      print('DEBUG: ✅ Login process completed');
    } on FirebaseAuthException catch (e) {
      print('DEBUG: ❌ Firebase Auth error: ${e.code} - ${e.message}');

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "No user found with this username";
          break;
        case 'wrong-password':
          message = "Incorrect password";
          break;
        case 'invalid-email':
          message = "Invalid credentials";
          break;
        case 'user-disabled':
          message = "This account has been disabled";
          break;
        case 'too-many-requests':
          message = "Too many failed attempts. Try again later";
          break;
        case 'invalid-credential':
          message = "Invalid username or password";
          break;
        default:
          message = "Login failed: ${e.message}";
      }
      _showSnackBar(message, Colors.red);
    } catch (e) {
      print('DEBUG: ❌ Unexpected error during login: $e');
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
      }
      _showSnackBar(errorMessage, Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
