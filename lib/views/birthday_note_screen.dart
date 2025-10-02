// views/birthday_note_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/services/birthday_service.dart';
import 'package:tutortyper_app/widgets/user_avatar_widget.dart';

class BirthdayNoteScreen extends StatefulWidget {
  final UserModel friend;
  final BirthdayCountdown countdown;

  const BirthdayNoteScreen({
    super.key,
    required this.friend,
    required this.countdown,
  });

  @override
  State<BirthdayNoteScreen> createState() => _BirthdayNoteScreenState();
}

class _BirthdayNoteScreenState extends State<BirthdayNoteScreen> {
  final BirthdayService _birthdayService = BirthdayService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  bool _isLoading = false;
  List<BirthdayNote> _existingNotes = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadExistingNotes();
    _setDefaultScheduleDate();
  }

  void _setDefaultScheduleDate() {
    if (widget.friend.birthDate != null) {
      final now = DateTime.now();
      final currentYear = now.year;
      DateTime nextBirthday = DateTime(
        currentYear,
        widget.friend.birthDate!.month,
        widget.friend.birthDate!.day,
      );
      
      // If birthday has passed this year, set for next year
      if (nextBirthday.isBefore(now)) {
        nextBirthday = DateTime(
          currentYear + 1,
          widget.friend.birthDate!.month,
          widget.friend.birthDate!.day,
        );
      }
      
      _selectedDate = nextBirthday;
    }
  }

  Future<void> _loadExistingNotes() async {
    _birthdayService.getBirthdayNotesForFriend(widget.friend.id).listen((notes) {
      setState(() {
        _existingNotes = notes;
      });
    });
  }

  Future<void> _createBirthdayNote() async {
    if (_titleController.text.trim().isEmpty || 
        _contentController.text.trim().isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final noteId = await _birthdayService.createBirthdayNote(
        friendId: widget.friend.id,
        friendName: widget.friend.displayName,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        scheduledDate: _selectedDate!,
      );

      if (noteId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Birthday note scheduled successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        _titleController.clear();
        _contentController.clear();
      } else {
        throw Exception('Failed to create note');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF9800),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this birthday note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _birthdayService.deleteBirthdayNote(noteId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Birthday note deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _sendNoteNow(String noteId, String friendName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Note Now'),
        content: Text('Send this birthday note to $friendName immediately?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF9800)),
            child: const Text('Send Now'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _birthdayService.sendBirthdayNoteImmediately(noteId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Birthday note sent to $friendName!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send birthday note'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkAndSendDueNotes() async {
    final sentNotes = await _birthdayService.checkAndSendDueBirthdayNotes();
    if (sentNotes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent ${sentNotes.length} birthday note(s)!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No due birthday notes to send'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        title: Text(
          'Birthday Note',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _checkAndSendDueNotes,
            icon: const Icon(Icons.send),
            tooltip: 'Check & Send Due Notes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Friend Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  UserAvatarWidget(
                    user: widget.friend,
                    radius: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.friend.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (widget.countdown.isToday)
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
                            '${widget.countdown.days} days, ${widget.countdown.hours}h ${widget.countdown.minutes}m left',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF757575),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Create New Note Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule Birthday Note',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title Field
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Note Title',
                      hintText: 'Happy Birthday ${widget.friend.displayName}!',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFFCC80)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF9800), width: 2),
                      ),
                      prefixIcon: const Icon(Icons.title, color: Color(0xFFFF9800)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Content Field
                  TextField(
                    controller: _contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Birthday Message',
                      hintText: 'Write a heartfelt birthday message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFFCC80)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF9800), width: 2),
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.message, color: Color(0xFFFF9800)),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date Selection
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFFFCC80)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFFFF9800)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? 'Send on: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Select date to send',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: _selectedDate != null 
                                    ? const Color(0xFF424242)
                                    : const Color(0xFF757575),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createBirthdayNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Schedule Note',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Existing Notes Section
            if (_existingNotes.isNotEmpty) ...[
              Text(
                'Scheduled Notes',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 12),
              ..._existingNotes.map((note) => _buildNoteCard(note)).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(BirthdayNote note) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: note.isSent ? Colors.green : const Color(0xFFFFCC80),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF424242),
                  ),
                ),
              ),
              if (note.isSent)
                const Icon(Icons.check_circle, color: Colors.green, size: 20)
              else
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteNote(note.id);
                    } else if (value == 'send_now') {
                      _sendNoteNow(note.id, note.friendName);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'send_now',
                      child: Row(
                        children: [
                          Icon(Icons.send, color: Color(0xFFFF9800), size: 20),
                          SizedBox(width: 8),
                          Text('Send Now'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, color: Color(0xFF757575)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: note.isSent ? Colors.green : const Color(0xFFFF9800),
              ),
              const SizedBox(width: 4),
              Text(
                note.isSent 
                    ? 'Sent on ${note.scheduledDate.day}/${note.scheduledDate.month}/${note.scheduledDate.year}'
                    : 'Scheduled for ${note.scheduledDate.day}/${note.scheduledDate.month}/${note.scheduledDate.year}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: note.isSent ? Colors.green : const Color(0xFFFF9800),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
