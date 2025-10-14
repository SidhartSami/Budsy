// widgets/special_friend_interaction_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../models/interaction_model.dart';
import '../services/interaction_service.dart';
import '../views/interaction_detail_screen.dart';

class SpecialFriendInteractionWidget extends StatefulWidget {
  const SpecialFriendInteractionWidget({super.key});

  @override
  State<SpecialFriendInteractionWidget> createState() =>
      _SpecialFriendInteractionWidgetState();
}

class _SpecialFriendInteractionWidgetState
    extends State<SpecialFriendInteractionWidget> {
  final InteractionService _interactionService = InteractionService();
  List<Map<String, dynamic>> _specialFriendsData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpecialFriendsData();
  }

  Future<void> _loadSpecialFriendsData() async {
    try {
      final data = await _interactionService.getSpecialFriendsWithCounts();
      if (mounted) {
        setState(() {
          _specialFriendsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
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

    if (_isLoading) {
      return _buildLoadingWidget(isDark);
    }

    if (_specialFriendsData.isEmpty) {
      return _buildEmptyWidget(isDark);
    }

    final friendData = _specialFriendsData.first;
    final friend = friendData['friend'] as UserModel;
    final myCount = friendData['myCount'] as int;
    final theirCount = friendData['theirCount'] as int;

    return _buildInteractionCard(friend, myCount, theirCount, isDark);
  }

  Widget _buildLoadingWidget(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: CircularProgressIndicator(
          color: isDark ? const Color(0xFF1A5C42) : const Color(0xFF0C3C2B),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF0C3C2B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_outline,
                size: 32,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Special Friends Yet',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a special friend to start sharing moments',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionCard(
    UserModel friend,
    int myCount,
    int theirCount,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InteractionDetailScreen(friend: friend),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Friend info section
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0C3C2B).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child:
                        friend.photoUrl != null && friend.photoUrl!.isNotEmpty
                        ? Image.network(
                            friend.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildAvatarFallback(
                                friend.displayName,
                                isDark,
                              );
                            },
                          )
                        : _buildAvatarFallback(friend.displayName, isDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to view interactions',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Connection strength visualization
            Row(
              children: [
                Expanded(
                  child: _buildHeartProgress(
                    'You',
                    myCount,
                    const Color(0xFF0C3C2B),
                    isDark,
                    isLeft: true,
                  ),
                ),
                const SizedBox(width: 20),
                // Center heart icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C3C2B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFF0C3C2B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildHeartProgress(
                    'Them',
                    theirCount,
                    const Color(0xFF1A5C42),
                    isDark,
                    isLeft: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name, bool isDark) {
    return Container(
      color: const Color(0xFF0C3C2B).withOpacity(0.1),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0C3C2B),
          ),
        ),
      ),
    );
  }

  Widget _buildHeartProgress(
    String label,
    int count,
    Color color,
    bool isDark, {
    required bool isLeft,
  }) {
    final maxCount = 100;
    final progress = (count / maxCount).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: isLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        // Label and count
        Row(
          mainAxisAlignment: isLeft
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            if (!isLeft) ...[
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            if (isLeft) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                  begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                  end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Progress percentage
        Text(
          '${(progress * 100).toInt()}%',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
