// lib/views/chat_theme_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutortyper_app/services/chat_settings_service.dart';

class ChatThemeSelectorScreen extends StatefulWidget {
  final String chatId;
  final String currentTheme;
  final Function(String) onThemeSelected;

  const ChatThemeSelectorScreen({
    super.key,
    required this.chatId,
    required this.currentTheme,
    required this.onThemeSelected,
  });

  @override
  State<ChatThemeSelectorScreen> createState() =>
      _ChatThemeSelectorScreenState();
}

class _ChatThemeSelectorScreenState extends State<ChatThemeSelectorScreen> {
  final ChatSettingsService _settingsService = ChatSettingsService();
  String _selectedTheme = '';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    final themes = ChatSettingsService.getChatThemes();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        foregroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Chat Themes',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _selectedTheme != widget.currentTheme
                  ? _saveTheme
                  : null,
              child: Text(
                'Save',
                style: GoogleFonts.nunito(
                  color: _selectedTheme != widget.currentTheme
                      ? Colors.white
                      : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Preview Section
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: _buildThemePreview(),
            ),
          ),

          // Theme Selection Grid
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Theme',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: themes.length,
                      itemBuilder: (context, index) {
                        final theme = themes[index];
                        final isSelected = theme['id'] == _selectedTheme;

                        return _buildThemeOption(theme, isSelected);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreview() {
    final themes = ChatSettingsService.getChatThemes();
    final selectedThemeData = themes.firstWhere(
      (t) => t['id'] == _selectedTheme,
      orElse: () => themes.first,
    );

    final primaryColor = Color(selectedThemeData['primaryColor']);
    final backgroundColor = Color(selectedThemeData['backgroundColor']);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Mock App Bar
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 16, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Text(
                  'Preview Chat',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Mock Messages
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Received message
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.5,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        'Hey! How are you?',
                        style: GoogleFonts.nunito(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sent message
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.5,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'I\'m doing great, thanks!',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Another received message
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.5,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        'That\'s awesome! 🎉',
                        style: GoogleFonts.nunito(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(Map<String, dynamic> theme, bool isSelected) {
    final primaryColor = Color(theme['primaryColor']);
    final backgroundColor = Color(theme['backgroundColor']);
    final secondaryColor = Color(
      theme['secondaryColor'] ?? theme['backgroundColor'],
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = theme['id'];
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 4,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Theme preview header
              Expanded(
                flex: 1,
                child: Container(
                  color: primaryColor,
                  width: double.infinity,
                  child: Center(
                    child: Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              // Theme preview body
              Expanded(
                flex: 2,
                child: Container(
                  color: backgroundColor,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 8,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          height: 8,
                          width: 30,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        theme['name'],
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTheme() async {
    if (_selectedTheme == widget.currentTheme) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Save theme to database using the service
      await _settingsService.setChatTheme(widget.chatId, _selectedTheme);

      // Notify parent widget about theme change
      widget.onThemeSelected(_selectedTheme);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme updated successfully!'),
          backgroundColor: Color.fromARGB(255, 104, 234, 243),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update theme: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}
