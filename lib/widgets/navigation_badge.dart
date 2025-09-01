// widgets/navigation_badge.dart
import 'package:flutter/material.dart';
import 'package:tutortyper_app/services/user_service.dart';

class FriendRequestsBadge extends StatelessWidget {
  final Widget child;
  final UserService _userService = UserService();

  FriendRequestsBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _userService.getPendingRequestsCountStream(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;
        
        if (pendingCount == 0) {
          return child;
        }
        
        return Stack(
          children: [
            child,
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Example usage in a BottomNavigationBar or anywhere else:
class ExampleBottomNavigation extends StatefulWidget {
  const ExampleBottomNavigation({super.key});

  @override
  State<ExampleBottomNavigation> createState() => _ExampleBottomNavigationState();
}

class _ExampleBottomNavigationState extends State<ExampleBottomNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Your existing screens
          Container(), // Home screen
          Container(), // Friends screen
          Container(), // Profile screen
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: FriendRequestsBadge(
              child: const Icon(Icons.people),
            ),
            label: 'Friends',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}