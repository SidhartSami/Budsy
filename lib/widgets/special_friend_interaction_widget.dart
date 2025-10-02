// widgets/special_friend_interaction_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../models/interaction_model.dart';
import '../services/interaction_service.dart';
import '../views/interaction_detail_screen.dart';

class SpecialFriendInteractionWidget extends StatefulWidget {
  const SpecialFriendInteractionWidget({super.key});

  @override
  State<SpecialFriendInteractionWidget> createState() => _SpecialFriendInteractionWidgetState();
}

class _SpecialFriendInteractionWidgetState extends State<SpecialFriendInteractionWidget> {
  final InteractionService _interactionService = InteractionService();
  List<Map<String, dynamic>> _specialFriendsData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpecialFriendsData();
  }

  Future<void> _loadSpecialFriendsData() async {
    try {
      final data = await _interactionService.getSpecialFriendsWithCounts();
      if (mounted) {
        setState(() {
          _specialFriendsData = data;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_specialFriendsData.isEmpty) {
      return _buildEmptyWidget();
    }

    // For now, show the first special friend. Later can be expanded to show multiple
    final friendData = _specialFriendsData.first;
    final friend = friendData['friend'] as UserModel;
    final myCount = friendData['myCount'] as int;
    final theirCount = friendData['theirCount'] as int;

    return _buildInteractionCard(friend, myCount, theirCount);
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 21, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 25,
            offset: Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF60A5FA),
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 21, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 25,
            offset: Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No Special Friends Yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Add a special friend to start sharing moments',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionCard(UserModel friend, int myCount, int theirCount) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InteractionDetailScreen(friend: friend),
          ),
        );
      },
      child: Container(
        height: 207,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4FD),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 25,
              offset: Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                'Miss You',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E40AF),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Hearts Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Your Heart
                  _buildHeartWithCount('You', myCount, const Color(0xFF60A5FA)),
                  
                  // Their Heart  
                  _buildHeartWithCount('Them', theirCount, const Color(0xFFEC4899)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeartWithCount(String label, int count, Color color) {
    final maxHeartFill = 100;
    final heartFill = (count / maxHeartFill).clamp(0.0, 1.0);
    
    return Column(
      children: [
        // Heart with fill
        Container(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Heart outline
              Icon(
                Icons.favorite_border,
                size: 50,
                color: color.withOpacity(0.2),
              ),
              
              // Heart fill
              ClipPath(
                clipper: MiniHeartFillClipper(heartFill),
                child: Icon(
                  Icons.favorite,
                  size: 50,
                  color: color,
                ),
              ),
              
              // Count text
              Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Label
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E40AF),
          ),
        ),
      ],
    );
  }
}

// Custom clipper for mini heart fill animation
class MiniHeartFillClipper extends CustomClipper<Path> {
  final double fillLevel;

  MiniHeartFillClipper(this.fillLevel);

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
  bool shouldReclip(MiniHeartFillClipper oldClipper) {
    return oldClipper.fillLevel != fillLevel;
  }
}
