import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ModernButtonStyle style;
  final double? width;
  final double height;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.style = ModernButtonStyle.primary,
    this.width,
    this.height = 56,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
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
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  Color _getBackgroundColor() {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    switch (widget.style) {
      case ModernButtonStyle.primary:
        return isEnabled ? AppColors.primary : AppColors.primary.withOpacity(0.5);
      case ModernButtonStyle.secondary:
        return isEnabled ? AppColors.secondary : AppColors.secondary.withOpacity(0.5);
      case ModernButtonStyle.outline:
        return Colors.transparent;
      case ModernButtonStyle.ghost:
        return _isPressed 
            ? AppColors.primary.withOpacity(0.1) 
            : Colors.transparent;
    }
  }

  Color _getTextColor() {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    switch (widget.style) {
      case ModernButtonStyle.primary:
      case ModernButtonStyle.secondary:
        return Colors.white;
      case ModernButtonStyle.outline:
      case ModernButtonStyle.ghost:
        return isEnabled ? AppColors.primary : AppColors.primary.withOpacity(0.5);
    }
  }

  Border? _getBorder() {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    switch (widget.style) {
      case ModernButtonStyle.outline:
        return Border.all(
          color: isEnabled ? AppColors.primary : AppColors.primary.withOpacity(0.5),
          width: 2,
        );
      default:
        return null;
    }
  }

  List<BoxShadow>? _getShadows() {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    if (!isEnabled || widget.style == ModernButtonStyle.ghost) {
      return null;
    }
    
    return [
      BoxShadow(
        color: _getBackgroundColor().withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: _getBackgroundColor().withOpacity(0.1),
        blurRadius: 40,
        offset: const Offset(0, 16),
        spreadRadius: 0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onPressed,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: widget.style == ModernButtonStyle.primary
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.primaryGradient,
                      )
                    : widget.style == ModernButtonStyle.secondary
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.secondaryGradient,
                          )
                        : null,
                color: widget.style != ModernButtonStyle.primary && 
                       widget.style != ModernButtonStyle.secondary
                    ? _getBackgroundColor()
                    : null,
                borderRadius: BorderRadius.circular(16),
                border: _getBorder(),
                boxShadow: _getShadows(),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.onPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading) ...[
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getTextColor(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ] else if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: _getTextColor(),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.text,
                            style: AppTextStyles.buttonLarge.copyWith(
                              color: _getTextColor(),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
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

enum ModernButtonStyle {
  primary,
  secondary,
  outline,
  ghost,
}
