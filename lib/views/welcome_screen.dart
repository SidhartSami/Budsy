import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutortyper_app/views/login_view.dart';
import 'package:tutortyper_app/views/register_view.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Helper for responsive sizing
    final size = MediaQuery.of(context).size;

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
                        width: size.width * 0.6,
                        height: size.height * 0.25,
                        fit: BoxFit.contain,
                      ),

                      SizedBox(height: size.height * 0.02),

                      // App Title
                      Text(
                        'Budsy',
                        style: TextStyle(
                          color: const Color(0xFF0C3C2B),
                          fontSize: size.width * 0.12,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      SizedBox(height: size.height * 0.01),

                      // Subtitle
                      Text(
                        'Your Digital Garden',
                        style: TextStyle(
                          color: const Color(0xFF0C3C2B).withOpacity(0.7),
                          fontSize: size.width * 0.04,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      SizedBox(height: size.height * 0.08),

                      // Login Button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginView(),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.08,
                            vertical: size.height * 0.02,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF0C3C2B),
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
                          child: Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size.width * 0.06,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.025),

                      // Sign Up Button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterView(),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.08,
                            vertical: size.height * 0.02,
                          ),
                          decoration: ShapeDecoration(
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                size.width * 0.07,
                              ),
                              side: BorderSide(
                                color: const Color(0xFF0C3C2B),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'Sign Up',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF0C3C2B),
                              fontSize: size.width * 0.06,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.04),

                      // Welcome message
                      Text(
                        'Start your journey with us',
                        style: TextStyle(
                          color: const Color(0xFF0C3C2B).withOpacity(0.6),
                          fontSize: size.width * 0.035,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}