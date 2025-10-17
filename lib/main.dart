import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:tutortyper_app/views/welcome_screen.dart';
import 'package:tutortyper_app/views/onboarding_screen.dart';
import 'package:tutortyper_app/views/profile_completion_screen.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/services/streak_service.dart';
import 'package:tutortyper_app/views/friends_list_screen.dart';
import 'package:tutortyper_app/views/mynotes.dart';
import 'package:tutortyper_app/views/create_notes.dart';
import 'package:tutortyper_app/views/setting_screen.dart';
import 'package:tutortyper_app/widgets/dashboard_birthday_widget.dart';
import 'package:tutortyper_app/widgets/dashboard_interaction_widget.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/theme/app_colors.dart';
import 'package:tutortyper_app/theme/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    WidgetsBinding.instance.addObserver(this);
    _initializeAppServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkStreaksOnResume();
    }
  }

  Future<void> _initializeAppServices() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      try {
        await StreakService().checkAndExpireStreaks();
      } catch (e) {
        print('ERROR: Failed to initialize app services: $e');
      }
    }
  }

  Future<void> _checkStreaksOnResume() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      try {
        await StreakService().checkAndExpireStreaks();
      } catch (e) {
        print('ERROR: Failed to check streaks on resume: $e');
      }
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void _toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeafNotes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C3C2B),
          brightness: Brightness.light,
          primary: const Color(0xFF0C3C2B),
          secondary: const Color(0xFF1A5C42),
          surface: Colors.white,
          background: const Color(0xFFFAFAFA),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C3C2B),
          brightness: Brightness.dark,
          primary: const Color(0xFF0C3C2B),
          secondary: const Color(0xFF1A5C42),
          surface: const Color(0xFF1C1C1E),
          background: const Color(0xFF000000),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF000000),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
      routes: {
        '/notes': (context) => const MyNotes(),
        '/create-note': (context) => const CreateNotes(),
        '/profile-completion': (context) => const ProfileCompletionScreen(),
      },
      builder: (context, child) {
        return NotesViewWrapper(onThemeChanged: _toggleTheme, child: child!);
      },
    );
  }
}

class NotesViewWrapper extends InheritedWidget {
  final ValueChanged<bool> onThemeChanged;

  const NotesViewWrapper({
    super.key,
    required this.onThemeChanged,
    required super.child,
  });

  static NotesViewWrapper? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NotesViewWrapper>();
  }

  @override
  bool updateShouldNotify(NotesViewWrapper oldWidget) {
    return onThemeChanged != oldWidget.onThemeChanged;
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isFirstTime = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    setState(() {
      _isFirstTime = isFirstTime;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isFirstTime) {
      return const OnboardingScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data!.emailVerified) {
          _initializeStreakCheckingForUser();
          return const ProfileCheckWrapper();
        }

        return const WelcomeScreen();
      },
    );
  }

  Future<void> _initializeStreakCheckingForUser() async {
    try {
      await StreakService().checkAndExpireStreaks();
    } catch (e) {
      print('ERROR: Failed to check streaks for authenticated user: $e');
    }
  }
}

class ProfileCheckWrapper extends StatelessWidget {
  const ProfileCheckWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return FutureBuilder<bool>(
      future: userService.isProfileCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your profile...',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !(snapshot.data ?? false)) {
          return const ProfileCompletionScreen();
        }

        return const NotesView();
      },
    );
  }
}

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  final UserService _userService = UserService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _userService.updateOnlineStatus(true);
    _checkStreaksOnEntry();
  }

  Future<void> _checkStreaksOnEntry() async {
    try {
      await StreakService().checkAndExpireStreaks();
    } catch (e) {
      print('ERROR: Failed to check streaks on entry: $e');
    }
  }

  @override
  void dispose() {
    _userService.updateOnlineStatus(false);
    super.dispose();
  }

  List<Widget> get _screens => [
    const DashboardScreen(),
    const MyNotes(),
    const FriendsListScreen(),
    SettingsScreen(
      onLogout: _handleLogout,
      onThemeChanged: NotesViewWrapper.of(context)?.onThemeChanged,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        selectedItemColor: const Color(0xFF0C3C2B),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_rounded),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset('assets/animations/Loading.json'),
          ),
        );
      },
    );

    await _userService.updateOnlineStatus(false);
    await Future.delayed(const Duration(seconds: 2));
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }
}

// Professional Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scrollController.addListener(_onScroll);
    _controller.forward();
    _loadCurrentUser();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if ((offset - _scrollOffset).abs() > 5) {
      setState(() => _scrollOffset = offset);
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userService = UserService();
      final user = await userService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFFAFAFA),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark
                ? const Color(0xFF000000)
                : const Color(0xFFFAFAFA),
            title: _isLoading
                ? _ShimmerBox(width: 120, height: 24)
                : Text(
                    'LeafNotes',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
            actions: [
              _NotificationButton(isDark: isDark),
              const SizedBox(width: 12),
            ],
          ),

          // Stats Cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _ModernStatCard(
                      icon: Icons.note_alt_outlined,
                      value: '24',
                      label: 'Notes',
                      color: const Color(0xFF0C3C2B),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModernStatCard(
                      icon: Icons.local_fire_department_rounded,
                      value: '7',
                      label: 'Day Streak',
                      color: const Color(0xFFFF6B35),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModernStatCard(
                      icon: Icons.people_outline,
                      value: '12',
                      label: 'Friends',
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Actions Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Quick Actions',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),

          // Quick Actions Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildListDelegate([
                _ActionCard(
                  icon: Icons.edit_note_rounded,
                  title: 'Create Note',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C3C2B), Color(0xFF1A5C42)],
                  ),
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateNotes()),
                    );
                  },
                ),
                _ActionCard(
                  icon: Icons.checklist_rounded,
                  title: 'To-Do List',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  isDark: isDark,
                  onTap: () => _showComingSoon('To-Do List'),
                ),
                _ActionCard(
                  icon: Icons.spa_outlined,
                  title: 'Bloom',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                  ),
                  isDark: isDark,
                  onTap: () => _showComingSoon('Bloom Counter'),
                ),
                _ActionCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Analytics',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                  ),
                  isDark: isDark,
                  onTap: () => _showComingSoon('Analytics'),
                ),
              ]),
            ),
          ),

          // Special Moments Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Special Moments',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),

          // Birthday Widget
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _ModernCard(
                child: const DashboardBirthdayWidget(),
                isDark: isDark,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Interaction Widget
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _ModernCard(
                child: const DashboardInteractionWidget(),
                isDark: isDark,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature coming soon!',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0C3C2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Notification Button
class _NotificationButton extends StatelessWidget {
  final bool isDark;

  const _NotificationButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.notifications_rounded,
            size: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF000000)
                      : const Color(0xFFFAFAFA),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Stat Card
class _ModernStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _ModernStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// Action Card
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Gradient gradient;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modern Card Wrapper
class _ModernCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _ModernCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
    );
  }
}

// Shimmer Loading Effect
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final bool isCircle;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.isCircle = false,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle ? null : BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [
                      const Color(0xFF1C1C1E),
                      const Color(0xFF2C2C2E),
                      const Color(0xFF1C1C1E),
                    ]
                  : [
                      Colors.grey.shade300,
                      Colors.grey.shade200,
                      Colors.grey.shade300,
                    ],
              stops: [0.0, _controller.value, 1.0],
            ),
          ),
        );
      },
    );
  }
}
