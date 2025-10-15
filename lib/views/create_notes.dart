import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';

class CreateNotes extends StatefulWidget {
  const CreateNotes({super.key});

  @override
  State<CreateNotes> createState() => _CreateNotesState();
}

class _CreateNotesState extends State<CreateNotes>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _wordCount = 0;
  int _characterCount = 0;

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

    _contentController.addListener(_updateCounts);
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateCounts() {
    final text = _contentController.text;
    setState(() {
      _characterCount = text.length;
      _wordCount = text.trim().isEmpty
          ? 0
          : text.trim().split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      _showSnackBar('Please fill both title and content', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String userId = _auth.currentUser!.uid;

      await _firestore.collection('users').doc(userId).collection('notes').add({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Note saved successfully');

      // Small delay for better UX
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Failed to save note', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFFF3B30) : Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDiscardDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasContent =
        _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty;

    if (!hasContent) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Discard Note?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        content: Text(
          'Your note will not be saved.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close create notes screen
            },
            child: Text(
              'Discard',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: const Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      ),
    );
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
          onTap: _showDiscardDialog,
          child: Container(
            margin: const EdgeInsets.only(left: 12),
            child: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 28,
            ),
          ),
        ),
        title: Text(
          "New Note",
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white : const Color(0xFF0C3C2B),
                    ),
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _saveNote,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C3C2B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
        ],
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
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        autofocus: true,
                        maxLines: null,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.5,
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade400,
                            letterSpacing: -0.5,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Content field
                      TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        maxLines: null,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          height: 1.6,
                          color: isDark
                              ? Colors.grey.shade300
                              : const Color(0xFF3C3C43),
                          letterSpacing: -0.2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Start writing...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 16,
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade400,
                            letterSpacing: -0.2,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Bottom stats bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.grey.shade200,
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_wordCount words',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade500,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$_characterCount characters',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade500,
                          letterSpacing: -0.1,
                        ),
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
}
