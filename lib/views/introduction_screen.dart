import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutortyper_app/views/welcome_screen.dart';

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
      gradientColors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      imagePath: 'assets/images/chat.png',
      accentColor: Color(0xFF60A5FA),
    ),
    IntroductionPage(
      title: "Chat. Share. Remember.",
      description: "Send notes, ideas, and reminders that never get lost in the scroll.",
      gradientColors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
      imagePath: 'assets/images/notes.png',
      accentColor: Color(0xFF60A5FA),
    ),
    IntroductionPage(
      title: "Private. Simple. Yours.",
      description: "Secure conversations designed around you — no clutter, just connection.",
      gradientColors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)],
      imagePath: 'assets/images/secure.png',
      accentColor: Color(0xFF60A5FA),
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
          // Auto-advance after countdown
          if (_currentPage < _pages.length - 1) {
            _nextPage();
          } else {
            _navigateToWelcome();
          }
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
      _navigateToWelcome();
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

  void _skipIntroduction() {
    _countdownTimer?.cancel();
    _navigateToWelcome();
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
          
          // Skip button (top right) with modern styling
          Positioned(
            top: 50,
            right: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: _skipIntroduction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation bubbles (bottom center)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildNavigationBubble(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBubble(int index) {
    bool isCurrentPage = index == _currentPage;
    bool isCompleted = index < _currentPage;
    
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrentPage ? 60 : 16,
          height: 16,
          decoration: BoxDecoration(
            color: isCurrentPage 
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Fill animation for current page
              if (isCurrentPage)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width: 60 * _fillProgress,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              // Completed pages
              if (isCompleted)
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroductionPage(IntroductionPage page) {
    // Determine if this is the middle page (index 1) for different layout
    bool isMiddlePage = _pages.indexOf(page) == 1;
    
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
              // Top spacing
              const SizedBox(height: 60),
              
              // For middle page: Text above image
              if (isMiddlePage) ...[
                // Content section (above image for middle page)
                Column(
                  children: [
                    // Title with modern typography
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Description with improved readability
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
              ],
              
              // Image section without borders - positioned at top for 1st and 3rd pages
              if (!isMiddlePage) ...[
                // Image at top for first and third pages - bigger size
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 320,
                        height: 320,
                        child: Image.asset(
                          page.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                color: page.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.image_not_supported,
                                size: 80,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
              ] else ...[
                // Image in middle for second page
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 300,
                            height: 300,
                            child: Image.asset(
                              page.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 300,
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: page.accentColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              
              // For first and last pages: Text below image with optimal spacing
              if (!isMiddlePage) ...[
                // Content section (below image for first and last pages)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title with modern typography
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Description with improved readability
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Bottom spacing - optimal distance from navigation bubbles
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
