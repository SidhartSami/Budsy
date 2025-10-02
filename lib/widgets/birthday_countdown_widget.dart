// widgets/birthday_countdown_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/services/birthday_service.dart';
import 'package:tutortyper_app/views/birthday_note_screen.dart';
import 'package:tutortyper_app/widgets/user_avatar_widget.dart';

// Add this method to check for due notes from the widget
class BirthdayHelper {
  static final BirthdayService _birthdayService = BirthdayService();
  
  static Future<void> checkAndSendDueNotes(BuildContext context) async {
    final sentNotes = await _birthdayService.checkAndSendDueBirthdayNotes();
    if (sentNotes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎂 Sent ${sentNotes.length} birthday note(s)!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No due birthday notes to send'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class BirthdayCountdownWidget extends StatefulWidget {
  const BirthdayCountdownWidget({super.key});

  @override
  State<BirthdayCountdownWidget> createState() => _BirthdayCountdownWidgetState();
}

class _BirthdayCountdownWidgetState extends State<BirthdayCountdownWidget> {
  final BirthdayService _birthdayService = BirthdayService();
  List<Map<String, dynamic>> _friendsWithBirthdays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendsWithBirthdays();
  }

  Future<void> _loadFriendsWithBirthdays() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _birthdayService.getSpecialFriendsWithUpcomingBirthdays();
      setState(() {
        _friendsWithBirthdays = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading friends with birthdays: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 25,
              offset: Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF9800),
          ),
        ),
      );
    }

    if (_friendsWithBirthdays.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 25,
              offset: Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cake,
                size: 48,
                color: Color(0xFFFF9800),
              ),
              const SizedBox(height: 8),
              Text(
                'No upcoming birthdays',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFE65100),
                ),
              ),
              Text(
                'Your special friends\' birthdays within the year will appear here',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFFE65100).withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 25,
            offset: Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.cake,
                  color: Color(0xFFE65100),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Birthdays',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
          
          // Birthday List
          ...(_friendsWithBirthdays.take(3).map((friendData) {
            final UserModel friend = friendData['user'] as UserModel;
            final BirthdayCountdown countdown = friendData['countdown'] as BirthdayCountdown;
            
            return _buildBirthdayCard(friend, countdown);
          }).toList()),
          
          // View All Button (if more than 3)
          if (_friendsWithBirthdays.length > 3)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to full birthday list screen
                    // You can implement this later
                  },
                  child: Text(
                    'View All (${_friendsWithBirthdays.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBirthdayCard(UserModel friend, BirthdayCountdown countdown) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFFCC80),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Friend Avatar
          UserAvatarWidget(
            user: friend,
            radius: 25,
          ),
          const SizedBox(width: 12),
          
          // Friend Info and Countdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 4),
                if (countdown.isToday)
                  Row(
                    children: [
                      const Icon(
                        Icons.celebration,
                        size: 16,
                        color: Color(0xFFFF5722),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Birthday Today! 🎉',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    _formatCountdown(countdown),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF757575),
                    ),
                  ),
              ],
            ),
          ),
          
          // Action Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BirthdayNoteScreen(
                    friend: friend,
                    countdown: countdown,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_note,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCountdown(BirthdayCountdown countdown) {
    if (countdown.days > 0) {
      return '${countdown.days} days, ${countdown.hours}h ${countdown.minutes}m left';
    } else if (countdown.hours > 0) {
      return '${countdown.hours}h ${countdown.minutes}m left';
    } else {
      return '${countdown.minutes}m left';
    }
  }
}
