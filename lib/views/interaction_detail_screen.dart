// views/interaction_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../models/interaction_model.dart';
import '../services/interaction_service.dart';

class InteractionDetailScreen extends StatefulWidget {
  final UserModel friend;

  const InteractionDetailScreen({super.key, required this.friend});

  @override
  State<InteractionDetailScreen> createState() =>
      _InteractionDetailScreenState();
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
    _heartAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: Curves.elasticOut,
      ),
    );
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

  Future<void> _sendInteraction(
    InteractionType type, {
    String? customMessage,
  }) async {
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
            content: Text(
              '${type.displayName} sent! ${type.emoji}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF0C3C2B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send interaction: $e',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFFAFAFA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark
                ? const Color(0xFF000000)
                : const Color(0xFFFAFAFA),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: isDark ? Colors.white : const Color(0xFF0C3C2B),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF0C3C2B), const Color(0xFF1A5C42)]
                        : [
                            const Color(0xFF0C3C2B).withOpacity(0.05),
                            const Color(0xFF1A5C42).withOpacity(0.05),
                          ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(60, 20, 20, 20),
                    child: Row(
                      children: [
                        // Friend Avatar with glow effect
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0C3C2B), Color(0xFF1A5C42)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0C3C2B).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF1C1C1E)
                                  : Colors.white,
                            ),
                            child: ClipOval(
                              child: widget.friend.predefinedAvatar != null
                                  ? Image.asset(
                                      widget.friend.predefinedAvatar!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return _buildDefaultAvatar(isDark);
                                          },
                                    )
                                  : _buildDefaultAvatar(isDark),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.friend.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0C3C2B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0C3C2B),
                                      Color(0xFF1A5C42),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '✨ Special Friend',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
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
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Heart Competition Section
                _buildHeartCompetitionSection(isDark),

                // Quick Send Section
                _buildQuickSendSection(isDark),

                // History Section
                _buildHistorySection(isDark),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isDark) {
    return Container(
      color: isDark
          ? const Color(0xFF1C1C1E)
          : const Color(0xFF0C3C2B).withOpacity(0.1),
      child: Icon(Icons.person, color: const Color(0xFF0C3C2B), size: 24),
    );
  }

  Widget _buildHeartCompetitionSection(bool isDark) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0C3C2B)),
        ),
      );
    }

    final myCount =
        _todaysCount?.getCountForUser(_interactionService.currentUserId!) ?? 0;
    final theirCount = _todaysCount?.getCountForUser(widget.friend.id) ?? 0;

    // Heart fill levels (max 100 interactions to fill a heart)
    final maxHeartFill = 100;
    final myHeartFill = (myCount / maxHeartFill).clamp(0.0, 1.0);
    final theirHeartFill = (theirCount / maxHeartFill).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF0C3C2B).withOpacity(0.3)
              : const Color(0xFF0C3C2B).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C3C2B), Color(0xFF1A5C42)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💕', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Heart Competition',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Fill your heart first to win today!',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Hearts Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Your Heart
              _buildCompetitiveHeart(
                'You',
                myCount,
                myHeartFill,
                const Color(0xFF0C3C2B),
                true,
                isDark,
              ),

              // VS Text
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0C3C2B).withOpacity(0.2)
                      : const Color(0xFF0C3C2B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF0C3C2B).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  'VS',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0C3C2B),
                    letterSpacing: 2,
                  ),
                ),
              ),

              // Their Heart
              _buildCompetitiveHeart(
                widget.friend.displayName,
                theirCount,
                theirHeartFill,
                const Color(0xFF1A5C42),
                false,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitiveHeart(
    String name,
    int count,
    double fillLevel,
    Color color,
    bool isMe,
    bool isDark,
  ) {
    return Column(
      children: [
        // Name
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0C3C2B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        // Heart with fill animation
        AnimatedBuilder(
          animation: _heartAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isMe ? _heartAnimation.value : 1.0,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Heart outline
                    Icon(
                      Icons.favorite_border,
                      size: 60,
                      color: color.withOpacity(0.3),
                    ),

                    // Heart fill
                    ClipPath(
                      clipper: HeartFillClipper(fillLevel),
                      child: Icon(Icons.favorite, size: 60, color: color),
                    ),

                    // Count badge
                    Positioned(
                      bottom: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _buildQuickSendSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF0C3C2B).withOpacity(0.3)
              : const Color(0xFF0C3C2B).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C3C2B), Color(0xFF1A5C42)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Send Love',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0C3C2B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Send Button
          GestureDetector(
            onTap: _isSending
                ? null
                : () => _sendInteraction(InteractionType.missYou),
            onLongPress: () {
              setState(() {
                _showMoreOptions = !_showMoreOptions;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: _isSending
                    ? LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[500]!],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF0C3C2B), Color(0xFF1A5C42)],
                      ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _isSending
                        ? Colors.grey.withOpacity(0.3)
                        : const Color(0xFF0C3C2B).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
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
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              'Tap to send • Long press for more options',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // More Options (shown on long press)
          if (_showMoreOptions) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0C3C2B).withOpacity(0.1)
                    : const Color(0xFF0C3C2B).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0C3C2B).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'More Options',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0C3C2B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: InteractionType.values
                        .where(
                          (type) =>
                              type != InteractionType.missYou &&
                              type != InteractionType.custom,
                        )
                        .map((type) => _buildQuickOptionChip(type, isDark))
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

  Widget _buildQuickOptionChip(InteractionType type, bool isDark) {
    return GestureDetector(
      onTap: _isSending
          ? null
          : () {
              _sendInteraction(type);
              setState(() {
                _showMoreOptions = false;
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0C3C2B).withOpacity(0.8),
              const Color(0xFF1A5C42).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0C3C2B).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              type.displayName,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(bool isDark) {
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
            margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF0C3C2B).withOpacity(0.3)
                    : const Color(0xFF0C3C2B).withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0C3C2B), Color(0xFF1A5C42)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.history,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s History',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0C3C2B),
                              ),
                            ),
                            Text(
                              '$interactionCount interaction${interactionCount != 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AnimatedRotation(
                      turns: _showHistory ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C3C2B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF0C3C2B),
                          size: 24,
                        ),
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
                    child: _buildHistoryContent(snapshot, isDark),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryContent(
    AsyncSnapshot<List<InteractionModel>> snapshot,
    bool isDark,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0C3C2B)),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Error loading interactions',
          style: GoogleFonts.inter(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final interactions = snapshot.data ?? [];

    if (interactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0C3C2B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_outline,
                size: 48,
                color: const Color(0xFF0C3C2B).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No interactions yet today',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Send your first interaction!',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
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
        final isFromMe =
            interaction.senderId == _interactionService.currentUserId;

        return _buildInteractionItem(interaction, isFromMe, isDark);
      },
    );
  }

  Widget _buildInteractionItem(
    InteractionModel interaction,
    bool isFromMe,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isFromMe) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C3C2B), Color(0xFF1A5C42)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C3C2B).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                ),
                child: ClipOval(
                  child: widget.friend.predefinedAvatar != null
                      ? Image.asset(
                          widget.friend.predefinedAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar(isDark);
                          },
                        )
                      : _buildDefaultAvatar(isDark),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isFromMe
                    ? const LinearGradient(
                        colors: [Color(0xFF0C3C2B), Color(0xFF1A5C42)],
                      )
                    : null,
                color: isFromMe
                    ? null
                    : (isDark
                          ? const Color(0xFF0C3C2B).withOpacity(0.2)
                          : const Color(0xFF0C3C2B).withOpacity(0.1)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isFromMe ? 16 : 4),
                  bottomRight: Radius.circular(isFromMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isFromMe
                        ? const Color(0xFF0C3C2B).withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isFromMe
                              ? Colors.white.withOpacity(0.2)
                              : const Color(0xFF0C3C2B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          interaction.displayEmoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          interaction.displayText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isFromMe
                                ? Colors.white
                                : (isDark
                                      ? Colors.white
                                      : const Color(0xFF0C3C2B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(interaction.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isFromMe
                          ? Colors.white.withOpacity(0.7)
                          : (isDark ? Colors.grey[500] : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromMe) ...[
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C3C2B), Color(0xFF1A5C42)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C3C2B).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
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
