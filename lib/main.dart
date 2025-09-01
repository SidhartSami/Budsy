import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:tutortyper_app/views/login_view.dart';
import 'package:tutortyper_app/views/register_view.dart';
import 'firebase_options.dart';
import 'package:tutortyper_app/views/welcome_screen.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/views/friends_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const WelcomeScreen(),
    ),
  );
}

enum MenuAction { logout }

// Replace your NotesView in main.dart with this

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    // Set user online when entering the app
    _userService.updateOnlineStatus(true);
  }

  @override
  void dispose() {
    // Set user offline when leaving the app
    _userService.updateOnlineStatus(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LeafNotes Chat'),
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendsListScreen(),
                ),
              );
            },
            tooltip: 'Friends',
          ),
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    barrierColor: const Color.fromARGB(255, 235, 222, 222),
                    builder: (context) {
                      return Center(
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Lottie.asset('assets/animations/Loading.json'),
                        ),
                      );
                    },
                  );

                  // Set user offline before logout
                  await _userService.updateOnlineStatus(false);
                  await Future.delayed(const Duration(seconds: 2));
                  await FirebaseAuth.instance.signOut();

                  if (mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginView(),
                      ),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(value: MenuAction.logout, child: Text('Logout')),
              ];
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Color.fromARGB(255, 104, 234, 243),
            ),
            SizedBox(height: 20),
            Text(
              "Welcome to LeafNotes!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 104, 234, 243),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Tap the friends icon to start chatting!",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FriendsListScreen()),
          );
        },
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
        child: const Icon(Icons.people, color: Colors.white),
      ),
    );
  }
}
