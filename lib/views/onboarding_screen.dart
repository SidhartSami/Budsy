import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutortyper_app/views/introduction_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _slideAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isVideoInitialized = false;
  bool _hasVideoEnded = false;
  double _slideProgress = 0.0;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnimations();
  }

  void _initializeVideo() {
    // You'll need to add your video file to assets/videos/ directory
    // For now, using a placeholder - replace with your actual video path
    _videoController = VideoPlayerController.asset('assets/videos/welcome.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        // Set up video completion listener before playing
        _videoController.addListener(_videoListener);
        
        // Start playing the video
        _videoController.play();
      }).catchError((error) {
        // Handle video loading error - show placeholder
        setState(() {
          _isVideoInitialized = true;
          _hasVideoEnded = true; // Skip video for placeholder
        });
      });
  }

  void _videoListener() {
    if (_videoController.value.position >= _videoController.value.duration && 
        _videoController.value.duration.inMilliseconds > 0) {
      if (!_hasVideoEnded) {
        setState(() {
          _hasVideoEnded = true;
        });
        // Don't pause, let it show the last frame
        _videoController.removeListener(_videoListener);
      }
    }
  }

  void _initializeAnimations() {
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start fade animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fadeAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _slideAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _onSlideUpdate(DragUpdateDetails details) {
    if (!_isSliding) return;
    
    setState(() {
      _slideProgress = (details.localPosition.dx / MediaQuery.of(context).size.width).clamp(0.0, 1.0);
    });
  }

  void _onSlideEnd(DragEndDetails details) {
    if (!_isSliding) return;
    
    if (_slideProgress > 0.7) {
      // Complete the slide and navigate
      _slideAnimationController.forward().then((_) async {
        // Mark onboarding as completed
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isFirstTime', false);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const IntroductionScreen()),
          );
        }
      });
    } else {
      // Reset slide progress
      setState(() {
        _slideProgress = 0.0;
      });
    }
    setState(() {
      _isSliding = false;
    });
  }

  void _onSlideStart(DragStartDetails details) {
    setState(() {
      _isSliding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Video Section (Top Half)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              color: Colors.white,
              child: _isVideoInitialized
                  ? Stack(
                      children: [
                        // Video Player or Placeholder
                        if (_videoController.value.isInitialized)
                          Stack(
                            children: [
                              // Video Player that fills the container
                              Positioned.fill(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoController.value.size.width,
                                    height: _videoController.value.size.height,
                                    child: VideoPlayer(_videoController),
                                  ),
                                ),
                              ),
                              // Play button overlay only if video is paused AND hasn't ended
                              if (!_videoController.value.isPlaying && !_hasVideoEnded)
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      _videoController.play();
                                    },
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        else
                          // Beautiful placeholder when video is not available
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_circle_outline,
                                    size: 80,
                                    color: Color(0xFF68EAF3),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Welcome Video',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add your video to assets/videos/welcome.mp4',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF68EAF3),
                      ),
                    ),
            ),
          ),

          // Content Section (Bottom Half)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Main Text
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Unleash the power\nof conversation',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Subtitle
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Connect, chat, and share your thoughts\nwith friends in a beautiful, intuitive way',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Slide to Open Section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            
                            // Slide Bar
                            GestureDetector(
                              onPanStart: _onSlideStart,
                              onPanUpdate: _onSlideUpdate,
                              onPanEnd: _onSlideEnd,
                                child: Container(
                                  width: double.infinity,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(35),
                                    border: Border.all(
                                      color: Colors.grey[400]!,
                                      width: 1,
                                    ),
                                  ),
                                child: Stack(
                                  children: [
                                    // Progress fill
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: _slideProgress > 0 ? _slideProgress * (MediaQuery.of(context).size.width - 64) + 32 : 0,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF68EAF3),
                                            Color(0xFF4FC3F7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(35),
                                      ),
                                    ),
                                    
                                    // Sliding handle
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 200),
                                      left: _slideProgress * (MediaQuery.of(context).size.width - 64) - 2,
                                      top: 3,
                                      child: Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(32),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: _slideProgress > 0.1 
                                                  ? const Color(0xFF68EAF3).withOpacity(0.6)
                                                  : Colors.grey[400],
                                              size: 12,
                                            ),
                                            const SizedBox(width: 2),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: _slideProgress > 0.1 
                                                  ? const Color(0xFF68EAF3)
                                                  : Colors.grey[600],
                                              size: 14,
                                            ),
                                            const SizedBox(width: 2),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: _slideProgress > 0.1 
                                                  ? const Color(0xFF68EAF3).withOpacity(0.6)
                                                  : Colors.grey[400],
                                              size: 12,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    // Center text
                                    Center(
                                      child: Text(
                                        _slideProgress > 0.7 ? 'Release to open' : 'Slide to continue',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _slideProgress > 0.1 
                                              ? Colors.white
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
