// lib/views/message_search_screen.dart
import 'package:flutter/material.dart';
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

class _MessageSearchScreenState extends State<MessageSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatSettingsService _settingsService = ChatSettingsService();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        foregroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Search Messages',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Search Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for messages...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color.fromARGB(255, 104, 234, 243),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults.clear();
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
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

          // Search Results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color.fromARGB(255, 104, 234, 243),
            ),
            SizedBox(height: 16),
            Text('Searching messages...'),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search Messages',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type to search for specific messages\nin your chat history',
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
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
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Messages Found',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try using different keywords',
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildMessageResultItem(result);
      },
    );
  }

  Widget _buildMessageResultItem(Map<String, dynamic> result) {
    final text = result['text'] ?? '';
    final senderId = result['senderId'] ?? '';
    final timestamp = result['timestamp'];
    final isFromMe = senderId == widget.otherUser.id ? false : true;

    DateTime? messageTime;
    if (timestamp != null) {
      if (timestamp is int) {
        messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp.toString().contains('Timestamp')) {
        // Handle Firestore Timestamp
        messageTime = timestamp.toDate();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: isFromMe
                      ? const Color.fromARGB(255, 104, 234, 243)
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isFromMe ? 'You' : widget.otherUser.displayName,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isFromMe
                      ? const Color.fromARGB(255, 104, 234, 243)
                      : Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (messageTime != null)
                Text(
                  _formatMessageTime(messageTime),
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.nunito(fontSize: 14, color: Colors.black87),
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
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days - show date and time
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching messages: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
