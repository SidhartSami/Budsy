// lib/views/message_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/services/chat_settings_service.dart';

class MessageSearchScreen extends StatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const MessageSearchScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends State<MessageSearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ChatSettingsService _settingsService = ChatSettingsService();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 12),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 22,
            ),
          ),
        ),
        title: Text(
          'Search Messages',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 0.5,
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF000000) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C1E)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search for messages...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade500,
                      letterSpacing: -0.2,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade500,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults.clear();
                                _hasSearched = false;
                              });
                            },
                            child: Icon(
                              Icons.cancel_rounded,
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade500,
                              size: 20,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.trim().isNotEmpty) {
                      _performSearch(value);
                    } else {
                      setState(() {
                        _searchResults.clear();
                        _hasSearched = false;
                      });
                    }
                  },
                  textInputAction: TextInputAction.search,
                  onSubmitted: _performSearch,
                ),
              ),
            ),

            // Search Results
            Expanded(child: _buildSearchResults(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.white : const Color(0xFF0C3C2B),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Searching messages...',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade900
                    : const Color(0xFF0C3C2B).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                size: 48,
                color: isDark ? Colors.grey.shade700 : const Color(0xFF0C3C2B),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Search Messages',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Type to search for specific messages\nin your chat history',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade900
                    : const Color(0xFF0C3C2B).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: isDark ? Colors.grey.shade700 : const Color(0xFF0C3C2B),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Messages Found',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Try using different keywords\nor check your spelling',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 20,
        endIndent: 20,
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildMessageResultItem(result, isDark);
      },
    );
  }

  Widget _buildMessageResultItem(Map<String, dynamic> result, bool isDark) {
    final text = result['text'] ?? '';
    final senderId = result['senderId'] ?? '';
    final timestamp = result['timestamp'];
    final isFromMe = senderId == widget.otherUser.id ? false : true;

    DateTime? messageTime;
    if (timestamp != null) {
      if (timestamp is int) {
        messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp.toString().contains('Timestamp')) {
        messageTime = timestamp.toDate();
      }
    }

    return Container(
      color: isDark ? const Color(0xFF000000) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: isFromMe
                      ? const Color(0xFF0C3C2B)
                      : (isDark ? Colors.grey.shade700 : Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isFromMe ? 'You' : widget.otherUser.displayName,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isFromMe
                      ? const Color(0xFF0C3C2B)
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              if (messageTime != null)
                Text(
                  _formatMessageTime(messageTime),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                    letterSpacing: -0.1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.grey.shade300 : Colors.black87,
              letterSpacing: -0.2,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      // Today - show time only
      final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
      final hourStr = hour == 0 ? '12' : hour.toString();
      final period = timestamp.hour >= 12 ? 'PM' : 'AM';
      return '$hourStr:${timestamp.minute.toString().padLeft(2, '0')} $period';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (messageDate.isAfter(today.subtract(const Duration(days: 7)))) {
      // This week - show day name
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[messageDate.weekday - 1];
    } else {
      // Other days - show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year.toString().substring(2)}';
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = await _settingsService.searchMessages(
        widget.chatId,
        query.trim(),
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching messages: $e');
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to search messages',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
