import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ModernNoteCard extends StatefulWidget {
  final String title;
  final String content;
  final DateTime? createdAt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ModernNoteCard({
    super.key,
    required this.title,
    required this.content,
    this.createdAt,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<ModernNoteCard> createState() => _ModernNoteCardState();
}

class _ModernNoteCardState extends State<ModernNoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  String _getPreviewText() {
    if (widget.content.isEmpty) return 'No content';
    
    // Remove extra whitespace and get first few lines
    String cleanContent = widget.content.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleanContent.length > 120) {
      return '${cleanContent.substring(0, 120)}...';
    }
    return cleanContent;
  }

  String _getFormattedDate() {
    if (widget.createdAt == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(widget.createdAt!);
    
    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(widget.createdAt!);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(widget.createdAt!);
    } else {
      return DateFormat('MMM d').format(widget.createdAt!);
    }
  }

  int _getWordCount() {
    if (widget.content.isEmpty) return 0;
    return widget.content.trim().split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [AppColors.surfaceDark, AppColors.surfaceDark.withOpacity(0.8)]
                    : AppColors.cardGradient,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : AppColors.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: isDark ? Colors.black12 : AppColors.shadowMedium,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
                border: isDark 
                  ? Border.all(color: AppColors.onSurfaceVariantDark.withOpacity(0.1))
                  : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title and delete button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: isDark 
                                  ? AppTextStyles.noteTitleDark 
                                  : AppTextStyles.noteTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: widget.onDelete,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Content preview
                        Text(
                          _getPreviewText(),
                          style: isDark 
                            ? AppTextStyles.notePreviewDark 
                            : AppTextStyles.notePreview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Footer with metadata
                        Row(
                          children: [
                            // Date
                            if (widget.createdAt != null) ...[
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: isDark 
                                  ? AppColors.onSurfaceVariantDark 
                                  : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getFormattedDate(),
                                style: isDark 
                                  ? AppTextStyles.noteDateDark 
                                  : AppTextStyles.noteDate,
                              ),
                            ],
                            
                            const Spacer(),
                            
                            // Word count
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_getWordCount()} words',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
