// views/interaction_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../models/interaction_model.dart';
import '../services/interaction_service.dart';

class InteractionDetailScreen extends StatefulWidget {
  final UserModel friend;

  const InteractionDetailScreen({
    super.key,
    required this.friend,
  });

  @override
  State<InteractionDetailScreen> createState() => _InteractionDetailScreenState();
}

class _InteractionDetailScreenState extends State<InteractionDetailScreen>
    with TickerProviderStateMixin {
  final InteractionService _interactionService = InteractionService();
  late AnimationController _heartAnimationController;
  late Animation<double> _heartAnimation;
  DailyInteractionCount? _todaysCount;
  bool _isLoading = true;
  bool _isSending = false;
  bool _showMoreOptions = false;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _heartAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _heartAnimationController,
      curve: Curves.elasticOut,
    ));
    _loadTodaysCount();
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadTodaysCount() async {
    try {
      final count = await _interactionService.getTodaysCount(widget.friend.id);
      if (mounted) {
        setState(() {
          _todaysCount = count;
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

  Future<void> _sendInteraction(InteractionType type, {String? customMessage}) async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Animate heart
      _heartAnimationController.forward().then((_) {
        _heartAnimationController.reverse();
      });

      await _interactionService.sendInteraction(
        receiverId: widget.friend.id,
        type: type,
        customMessage: customMessage,
      );

      // Refresh today's count
      await _loadTodaysCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.displayName} sent! ${type.emoji}'),
            backgroundColor: const Color(0xFF60A5FA),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send interaction: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E40AF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Friend Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF60A5FA),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: widget.friend.predefinedAvatar != null
                    ? Image.asset(
                        widget.friend.predefinedAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friend.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                  Text(
                    '✨ Special Friend',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF60A5FA),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Heart Competition Section
            _buildHeartCompetitionSection(),
            
            // Quick Send Section
            _buildQuickSendSection(),
            
            // History Section
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF60A5FA).withOpacity(0.1),
      child: const Icon(
        Icons.person,
        color: Color(0xFF60A5FA),
        size: 20,
      ),
    );
  }

  Widget _buildHeartCompetitionSection() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final myCount = _todaysCount?.getCountForUser(_interactionService.currentUserId!) ?? 0;
    final theirCount = _todaysCount?.getCountForUser(widget.friend.id) ?? 0;
    
    // Heart fill levels (max 100 interactions to fill a heart)
    final maxHeartFill = 100;
    final myHeartFill = (myCount / maxHeartFill).clamp(0.0, 1.0);
    final theirHeartFill = (theirCount / maxHeartFill).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F4FD),
            Color(0xFFD1E9F6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
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
        children: [
          Text(
            'Heart Competition 💕',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fill your heart first to win today!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Hearts Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Your Heart
              _buildCompetitiveHeart(
                'You',
                myCount,
                myHeartFill,
                const Color(0xFF60A5FA),
                true,
              ),
              
              // VS Text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'VS',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ),
              
              // Their Heart
              _buildCompetitiveHeart(
                widget.friend.displayName,
                theirCount,
                theirHeartFill,
                const Color(0xFFEC4899),
                false,
              ),
            ],
          ),
          
        ],
      ),
    );
  }

  Widget _buildCompetitiveHeart(String name, int count, double fillLevel, Color color, bool isMe) {
    return Column(
      children: [
        // Name
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(height: 8),
        
        // Heart with fill animation
        AnimatedBuilder(
          animation: _heartAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isMe ? _heartAnimation.value : 1.0,
              child: Container(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Heart outline
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: color.withOpacity(0.3),
                    ),
                    
                    // Heart fill
                    ClipPath(
                      clipper: HeartFillClipper(fillLevel),
                      child: Icon(
                        Icons.favorite,
                        size: 80,
                        color: color,
                      ),
                    ),
                    
                  ],
                ),
              ),
            );
          },
        ),
        
      ],
    );
  }


  Widget _buildQuickSendSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            'Send Love ❤️',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick Send Button
          GestureDetector(
            onTap: _isSending ? null : () => _sendInteraction(InteractionType.missYou),
            onLongPress: () {
              setState(() {
                _showMoreOptions = !_showMoreOptions;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isSending 
                      ? [Colors.grey[300]!, Colors.grey[400]!]
                      : [const Color(0xFF60A5FA), const Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF60A5FA).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSending) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    _isSending ? 'Sending...' : 'Miss You ❤️',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Tap to send • Long press for more options',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          // More Options (shown on long press)
          if (_showMoreOptions) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'More Options',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: InteractionType.values
                        .where((type) => type != InteractionType.missYou && type != InteractionType.custom)
                        .map((type) => _buildQuickOptionChip(type))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickOptionChip(InteractionType type) {
    return GestureDetector(
      onTap: _isSending ? null : () {
        _sendInteraction(type);
        setState(() {
          _showMoreOptions = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF60A5FA).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              type.displayName,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E40AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return StreamBuilder<List<InteractionModel>>(
      stream: _interactionService.getTodaysInteractions(widget.friend.id),
      builder: (context, snapshot) {
        final interactions = snapshot.data ?? [];
        final interactionCount = interactions.length;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _showHistory = !_showHistory;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                // Header row with title and expand icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s History',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$interactionCount interaction${interactionCount != 1 ? 's' : ''} today',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    AnimatedRotation(
                      turns: _showHistory ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: const Color(0xFF1E40AF),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                
                // Expandable content
                if (_showHistory) ...[
                  const SizedBox(height: 20),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: interactions.isEmpty ? 150 : 300,
                    child: _buildHistoryContent(snapshot),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryContent(AsyncSnapshot<List<InteractionModel>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Error loading interactions',
          style: GoogleFonts.poppins(color: Colors.red),
        ),
      );
    }

    final interactions = snapshot.data ?? [];

    if (interactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No interactions yet today',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Send your first interaction!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: interactions.length,
      itemBuilder: (context, index) {
        final interaction = interactions[index];
        final isFromMe = interaction.senderId == _interactionService.currentUserId;
        
        return _buildInteractionItem(interaction, isFromMe);
      },
    );
  }


  Widget _buildInteractionItem(InteractionModel interaction, bool isFromMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF60A5FA), width: 1),
              ),
              child: ClipOval(
                child: widget.friend.predefinedAvatar != null
                    ? Image.asset(
                        widget.friend.predefinedAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromMe ? const Color(0xFF60A5FA) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        interaction.displayEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          interaction.displayText,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isFromMe ? Colors.white : const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(interaction.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isFromMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF60A5FA).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF60A5FA),
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

// Custom clipper for heart fill animation
class HeartFillClipper extends CustomClipper<Path> {
  final double fillLevel;

  HeartFillClipper(this.fillLevel);

  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Calculate the fill height (from bottom to top)
    final fillHeight = size.height * fillLevel;
    final startY = size.height - fillHeight;
    
    // Create a rectangle that clips from the bottom up
    path.addRect(Rect.fromLTWH(0, startY, size.width, fillHeight));
    
    return path;
  }

  @override
  bool shouldReclip(HeartFillClipper oldClipper) {
    return oldClipper.fillLevel != fillLevel;
  }
}
