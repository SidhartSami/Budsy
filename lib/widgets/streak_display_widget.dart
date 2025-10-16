// widgets/streak_display_widget.dart
import 'package:flutter/material.dart';
import 'package:tutortyper_app/services/streak_service.dart';

class StreakDisplayWidget extends StatelessWidget {
  final String userId1;
  final String userId2;
  final bool compact; // For displaying in list vs chat header

  const StreakDisplayWidget({
    Key? key,
    required this.userId1,
    required this.userId2,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final streakService = StreakService();

    return StreamBuilder<Map<String, dynamic>>(
      stream: streakService.getStreakDisplayInfoStream(userId1, userId2),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final streakInfo = snapshot.data!;
        final hasStreak = streakInfo['hasStreak'] as bool;
        final streakCount = streakInfo['streakCount'] as int;
        final showHourglass = streakInfo['showHourglass'] as bool;
        final emoji = streakInfo['emoji'] as String;
        final timeRemaining = streakInfo['timeRemaining'] as String? ?? '';

        if (!hasStreak) {
          // Show progress towards streak (optional)
          final daysUntilStreak = streakInfo['daysUntilStreak'] as int? ?? 0;
          if (daysUntilStreak > 0 && daysUntilStreak < 3 && !compact) {
            return _buildStreakProgress(context, daysUntilStreak);
          }
          return const SizedBox.shrink();
        }

        if (compact) {
          return _buildCompactStreak(
            context,
            streakCount,
            emoji,
            showHourglass,
          );
        } else {
          return _buildFullStreak(
            context,
            streakCount,
            emoji,
            showHourglass,
            timeRemaining,
          );
        }
      },
    );
  }

  // In streak_display_widget.dart, temporarily modify _buildCompactStreak:

  Widget _buildCompactStreak(
    BuildContext context,
    int streakCount,
    String emoji,
    bool showHourglass,
  ) {
    // FOR TESTING: Always show even at 0
    final displayEmoji = streakCount == 0 ? '⚪' : (showHourglass ? '⌛' : emoji);
    final displayColor = streakCount == 0
        ? Colors.grey
        : (showHourglass ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: displayColor.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: displayColor.shade200, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(displayEmoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$streakCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: displayColor.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // Full version for chat header
  Widget _buildFullStreak(
    BuildContext context,
    int streakCount,
    String emoji,
    bool showHourglass,
    String timeRemaining,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: showHourglass
              ? [Colors.orange.shade100, Colors.orange.shade50]
              : [Colors.red.shade100, Colors.pink.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: showHourglass ? Colors.orange.shade300 : Colors.red.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: showHourglass
                ? Colors.orange.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji
          Text(
            showHourglass ? '⌛' : emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),

          // Streak count and info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '$streakCount Day Streak',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: showHourglass
                          ? Colors.orange.shade900
                          : Colors.red.shade900,
                    ),
                  ),
                  if (!showHourglass && emoji == '🔥') ...[
                    const SizedBox(width: 4),
                    Icon(Icons.whatshot, size: 18, color: Colors.red.shade700),
                  ],
                ],
              ),
              if (showHourglass && timeRemaining.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Send a message within $timeRemaining',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),

          // Info icon
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showStreakInfo(context, streakCount),
            child: Icon(
              Icons.info_outline,
              size: 18,
              color: showHourglass
                  ? Colors.orange.shade700
                  : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // Progress towards streak (before 3 days)
  Widget _buildStreakProgress(BuildContext context, int daysUntilStreak) {
    final daysCompleted = 3 - daysUntilStreak;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🔥',
            style: TextStyle(fontSize: 20, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$daysCompleted/3 days',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                'Keep messaging to start a streak!',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Show streak information dialog
  void _showStreakInfo(BuildContext context, int streakCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('🔥'),
            const SizedBox(width: 8),
            const Text('Streak Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have a $streakCount day streak!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'How Streaks Work:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildInfoPoint('📱', 'Message each other every day'),
            _buildInfoPoint('🔥', 'Streaks start after 3 consecutive days'),
            _buildInfoPoint('⏰', 'You have 24 hours to reply'),
            _buildInfoPoint('⌛', 'Hourglass appears when time is running out'),
            _buildInfoPoint('💯', 'Special emojis at milestone streaks'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Don\'t break the streak! Keep chatting every day.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// Widget for showing streak in friend list
class FriendStreakBadge extends StatelessWidget {
  final String userId1;
  final String userId2;

  const FriendStreakBadge({
    Key? key,
    required this.userId1,
    required this.userId2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreakDisplayWidget(
      userId1: userId1,
      userId2: userId2,
      compact: true,
    );
  }
}

// Widget for chat app bar
class ChatHeaderStreak extends StatelessWidget {
  final String userId1;
  final String userId2;

  const ChatHeaderStreak({
    Key? key,
    required this.userId1,
    required this.userId2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreakDisplayWidget(
      userId1: userId1,
      userId2: userId2,
      compact: false,
    );
  }
}

// Streak reminder notification widget
class StreakReminderWidget extends StatelessWidget {
  final String friendId;
  final String friendName;
  final int hoursRemaining;

  const StreakReminderWidget({
    Key? key,
    required this.friendId,
    required this.friendName,
    required this.hoursRemaining,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Text('⌛', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak Alert!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Send a message to $friendName within $hoursRemaining hours to keep your streak alive!',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}
