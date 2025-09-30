// widgets/user_avatar_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/widgets/avatar_selection_widget.dart';

class UserAvatarWidget extends StatelessWidget {
  final UserModel user;
  final double radius;
  final bool showOnlineStatus;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  const UserAvatarWidget({
    super.key,
    required this.user,
    this.radius = 20,
    this.showOnlineStatus = false,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;

    // Check if user has a predefined avatar
    if (user.predefinedAvatar != null && 
        AvatarManager.isPredefinedAvatar(user.predefinedAvatar)) {
      avatarWidget = ClipOval(
        child: SvgPicture.asset(
          user.predefinedAvatar!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        ),
      );
    }
    // Check if user has a custom photo
    else if (user.photoUrl != null) {
      avatarWidget = CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? const Color(0xFF68EAFF),
        backgroundImage: CachedNetworkImageProvider(user.photoUrl!),
      );
    }
    // Default to initials
    else {
      avatarWidget = CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? const Color(0xFF68EAFF),
        child: Text(
          user.displayName.isNotEmpty
              ? user.displayName[0].toUpperCase()
              : 'U',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: radius * 0.6,
          ),
        ),
      );
    }

    // Add border if specified
    if (borderWidth > 0) {
      avatarWidget = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? Colors.grey,
            width: borderWidth,
          ),
        ),
        child: avatarWidget,
      );
    }

    // Add online status indicator if requested
    if (showOnlineStatus && user.isOnline) {
      return Stack(
        children: [
          avatarWidget,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return avatarWidget;
  }
}
