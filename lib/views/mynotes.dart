import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_notes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/modern_note_card.dart';
import '../widgets/modern_empty_state.dart';

class MyNotes extends StatefulWidget {
  const MyNotes({super.key});

  @override
  State<MyNotes> createState() => _MyNotesState();
}

class _MyNotesState extends State<MyNotes> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  bool _isSearchVisible = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
    if (_isSearchVisible) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
      _searchController.clear();
      _searchQuery = '';
    }
  }

  void _navigateToCreateNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateNotes()),
    );
  }

  void _showNoteDialog(String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF000000),
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white : Colors.black,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
              height: 1,
              thickness: 0.5,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.6,
                    color: isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF3C3C43),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      String userId = _auth.currentUser!.uid;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Note deleted',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to delete note',
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser!.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFFAFAFA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 110,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: isDark
                    ? Brightness.dark
                    : Brightness.light,
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  "Notes",
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    letterSpacing: -1,
                  ),
                ),
              ),
              actions: [
                // Search button
                GestureDetector(
                  onTap: _toggleSearch,
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isSearchVisible
                          ? (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSearchVisible
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      color: isDark ? Colors.white : Colors.black,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: _isSearchVisible
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: AnimatedBuilder(
                        animation: _searchAnimation,
                        builder: (context, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.5),
                              end: Offset.zero,
                            ).animate(_searchAnimation),
                            child: FadeTransition(
                              opacity: _searchAnimation,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1C1C1E)
                                        : const Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value.toLowerCase();
                                      });
                                    },
                                    style: GoogleFonts.inter(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 16,
                                      letterSpacing: -0.3,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Search',
                                      hintStyle: GoogleFonts.inter(
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade600,
                                        fontSize: 16,
                                        letterSpacing: -0.3,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade600,
                                        size: 20,
                                      ),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? GestureDetector(
                                              onTap: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _searchQuery = '';
                                                });
                                              },
                                              child: Icon(
                                                Icons.cancel_rounded,
                                                color: isDark
                                                    ? Colors.grey.shade500
                                                    : Colors.grey.shade600,
                                                size: 18,
                                              ),
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : null,
            ),
          ];
        },
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(userId)
              .collection('notes')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF0C3C2B),
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Unable to load your notes',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(isDark);
            }

            var filteredDocs = snapshot.data!.docs.where((doc) {
              if (_searchQuery.isEmpty) return true;

              var noteData = doc.data() as Map<String, dynamic>;
              String title = (noteData['title'] ?? '').toLowerCase();
              String content = (noteData['content'] ?? '').toLowerCase();

              return title.contains(_searchQuery) ||
                  content.contains(_searchQuery);
            }).toList();

            if (filteredDocs.isEmpty && _searchQuery.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No results found',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: filteredDocs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                var noteData =
                    filteredDocs[index].data() as Map<String, dynamic>;
                var noteId = filteredDocs[index].id;

                String title = noteData['title'] ?? 'Untitled';
                String content = noteData['content'] ?? '';

                DateTime? createdAt;
                if (noteData['createdAt'] != null) {
                  createdAt = (noteData['createdAt'] as Timestamp).toDate();
                }

                return _buildNoteCard(
                  isDark: isDark,
                  title: title,
                  content: content,
                  createdAt: createdAt,
                  onTap: () => _showNoteDialog(title, content),
                  onDelete: () => _deleteNote(noteId),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateNotes,
        backgroundColor: const Color(0xFF0C3C2B),
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildNoteCard({
    required bool isDark,
    required String title,
    required String content,
    required DateTime? createdAt,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    String preview = content.length > 120
        ? '${content.substring(0, 120)}...'
        : content;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDark
                            ? const Color(0xFF1C1C1E)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          'Delete Note',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to delete this note?',
                          style: GoogleFonts.inter(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onDelete();
                            },
                            child: Text(
                              'Delete',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF3B30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                preview,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  letterSpacing: -0.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 12),
              Text(
                _formatDate(createdAt),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900.withOpacity(0.3)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.note_outlined,
              size: 56,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'No Notes Yet',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Tap the + button to create your first note',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // CTA Button
          GestureDetector(
            onTap: _navigateToCreateNotes,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0C3C2B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Create Note',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
