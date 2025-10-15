// widgets/dashboard_birthday_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutortyper_app/services/birthday_service.dart';
import 'package:tutortyper_app/models/user_model.dart';

class DashboardBirthdayWidget extends StatefulWidget {
  const DashboardBirthdayWidget({super.key});

  @override
  State<DashboardBirthdayWidget> createState() =>
      _DashboardBirthdayWidgetState();
}

class _DashboardBirthdayWidgetState extends State<DashboardBirthdayWidget> {
  final BirthdayService _birthdayService = BirthdayService();
  List<Map<String, dynamic>> _upcomingBirthdays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpcomingBirthdays();
  }

  Future<void> _loadUpcomingBirthdays() async {
    try {
      final birthdays = await _birthdayService
          .getSpecialFriendsWithUpcomingBirthdays();

      if (mounted) {
        setState(() {
          _upcomingBirthdays = birthdays;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading birthdays: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C3C2B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cake_rounded,
                  color: Color(0xFF0C3C2B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Birthdays',
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (!_isLoading && _upcomingBirthdays.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C3C2B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_upcomingBirthdays.length}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Upcoming celebrations',
                      style: GoogleFonts.inter(
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF0C3C2B),
                  ),
                ),
              ),
            )
          else if (_upcomingBirthdays.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800.withOpacity(0.3)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.celebration_outlined,
                        size: 32,
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No upcoming birthdays',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add special friends to see their birthdays',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade500,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Horizontal scrolling birthday cards
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _upcomingBirthdays.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final data = _upcomingBirthdays[index];
                      final friend = data['user'] as UserModel;
                      final countdown = data['countdown'] as BirthdayCountdown;
                      return _buildBirthdayCard(
                        friend,
                        countdown,
                        isDark,
                        index,
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBirthdayCard(
    UserModel friend,
    BirthdayCountdown countdown,
    bool isDark,
    int index,
  ) {
    String daysText;
    Color accentColor;

    if (countdown.isToday) {
      daysText = 'Today';
      accentColor = const Color(0xFFFF6B6B);
    } else if (countdown.days == 1) {
      daysText = 'Tomorrow';
      accentColor = const Color(0xFFFFA500);
    } else if (countdown.days <= 7) {
      daysText = '${countdown.days}d';
      accentColor = const Color(0xFF4ECDC4);
    } else if (countdown.days <= 30) {
      daysText = '${countdown.days}d';
      accentColor = const Color(0xFF0C3C2B);
    } else {
      final months = (countdown.days / 30).round();
      daysText = '${months}mo';
      accentColor = const Color(0xFF0C3C2B);
    }

    return Container(
      width: 85,
      margin: EdgeInsets.only(
        right: index == _upcomingBirthdays.length - 1 ? 0 : 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with ring
          Stack(
            alignment: Alignment.center,
            children: [
              // Gradient ring
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: countdown.isToday
                        ? [const Color(0xFFFF6B6B), const Color(0xFFFFD93D)]
                        : [accentColor.withOpacity(0.8), accentColor],
                  ),
                ),
              ),
              // White border
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    width: 2,
                  ),
                ),
              ),
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                  image: friend.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(friend.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: friend.photoUrl == null
                    ? Center(
                        child: Text(
                          friend.displayName[0].toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
              // Today badge
              if (countdown.isToday)
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text('🎉', style: TextStyle(fontSize: 9)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Name
          Text(
            friend.displayName.split(' ')[0],
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          // Days until
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              daysText,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
