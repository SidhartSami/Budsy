import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutortyper_app/views/welcome_screen.dart';
import 'package:tutortyper_app/views/login_view.dart';
import 'package:tutortyper_app/views/register_view.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  int _currentPage = 0;
  Timer? _countdownTimer;
  double _fillProgress = 0.0;
  bool _showCountdown = true;
  
  final List<IntroductionPage> _pages = [
    IntroductionPage(
      title: "Conversations that flow.",
      description: "Stay close with friends and groups through fast, real-time chat.",
      gradientColors: [Colors.white, Colors.white],
      imagePath: 'assets/images/Chatting-bro.svg',
      accentColor: Color(0xFF4CAF50),
    ),
    IntroductionPage(
      title: "Chat. Share. Remember.",
      description: "Send notes, ideas, and reminders that never get lost in the scroll.",
      gradientColors: [Colors.white, Colors.white],
      imagePath: 'assets/images/Bullet journal-pana.svg',
      accentColor: Color(0xFF4CAF50),
    ),
    IntroductionPage(
      title: "Private. Simple. Yours.",
      description: "Secure conversations designed around you — no clutter, just connection.",
      gradientColors: [Colors.white, Colors.white],
      imagePath: 'assets/images/Security-rafiki.svg',
      accentColor: Color(0xFF4CAF50),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeAnimations();
    _startCountdown();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _scaleController.forward();
  }

  void _startCountdown() {
    _fillProgress = 0.0;
    _showCountdown = true;
    
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _fillProgress += 0.0125; // 4 seconds = 4000ms, 4000/50 = 80 steps, 1.0/80 = 0.0125
        });
        
        if (_fillProgress >= 1.0) {
          timer.cancel();
          _showCountdown = false;
          // Auto-advance after countdown - loop back to first page
            _nextPage();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _nextPage() {
    _countdownTimer?.cancel();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Loop back to first page
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToWelcome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterView()),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for the three introduction screens
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              _countdownTimer?.cancel();
              _startCountdown();
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildIntroductionPage(_pages[index]);
            },
          ),
          
          
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Sign In Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _navigateToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Sign In',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Register Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _navigateToRegister,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              side: const BorderSide(
                color: Color(0xFF4CAF50),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Register',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => _buildPageIndicator(index),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    bool isCurrentPage = index == _currentPage;
    
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrentPage ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isCurrentPage 
                ? const Color(0xFF4CAF50)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroductionPage(IntroductionPage page) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: page.gradientColors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Top spacing - consistent for all pages
              const SizedBox(height: 20),
              
              // Image section - consistent size and positioning for all pages
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 280,
                            maxHeight: 280,
                          ),
                          child: SvgPicture.asset(
                            page.imagePath,
                            fit: BoxFit.contain,
                            placeholderBuilder: (context) => Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                color: page.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.image_not_supported,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Content section - consistent for all pages
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with consistent typography
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description with consistent styling
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[700],
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Page indicators - consistent positioning
              const SizedBox(height: 20),
              _buildPageIndicators(),
              
              // Action buttons - consistent positioning
              const SizedBox(height: 20),
              _buildActionButtons(),
              
              // Bottom spacing - consistent for all pages
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class IntroductionPage {
  final String title;
  final String description;
  final List<Color> gradientColors;
  final String imagePath;
  final Color accentColor;

  IntroductionPage({
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.imagePath,
    required this.accentColor,
  });
}
