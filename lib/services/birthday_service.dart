// services/birthday_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/services/message_service.dart';

class BirthdayCountdown {
  final int days;
  final int hours;
  final int minutes;
  final bool isToday;
  final bool isThisMonth;

  BirthdayCountdown({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.isToday,
    required this.isThisMonth,
  });
}

class BirthdayNote {
  final String id;
  final String friendId;
  final String friendName;
  final String title;
  final String content;
  final DateTime scheduledDate;
  final DateTime createdAt;
  final bool isScheduled;
  final bool isSent;

  BirthdayNote({
    required this.id,
    required this.friendId,
    required this.friendName,
    required this.title,
    required this.content,
    required this.scheduledDate,
    required this.createdAt,
    required this.isScheduled,
    required this.isSent,
  });

  Map<String, dynamic> toMap() {
    return {
      'friendId': friendId,
      'friendName': friendName,
      'title': title,
      'content': content,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'isScheduled': isScheduled,
      'isSent': isSent,
    };
  }

  factory BirthdayNote.fromMap(String id, Map<String, dynamic> map) {
    return BirthdayNote(
      id: id,
      friendId: map['friendId'] ?? '',
      friendName: map['friendName'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isScheduled: map['isScheduled'] ?? false,
      isSent: map['isSent'] ?? false,
    );
  }
}

class BirthdayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MessageService _messageService = MessageService();

  // Generate chat ID between two users
  String _generateChatId(String friendId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return '';
    
    final participants = [currentUserId, friendId]..sort();
    return participants.join('_');
  }

  // Calculate countdown to next birthday
  BirthdayCountdown calculateBirthdayCountdown(DateTime birthDate) {
    final now = DateTime.now();
    final currentYear = now.year;
    
    // Calculate this year's birthday
    DateTime thisYearBirthday = DateTime(currentYear, birthDate.month, birthDate.day);
    
    // If birthday has passed this year, calculate for next year
    if (thisYearBirthday.isBefore(now)) {
      thisYearBirthday = DateTime(currentYear + 1, birthDate.month, birthDate.day);
    }
    
    final difference = thisYearBirthday.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    
    // Check if birthday is today
    final isToday = days == 0 && hours < 24;
    
    // Check if birthday is within next 365 days (1 year)
    final isThisMonth = days <= 365;
    
    return BirthdayCountdown(
      days: days,
      hours: hours,
      minutes: minutes,
      isToday: isToday,
      isThisMonth: isThisMonth,
    );
  }

  // Get special friends with upcoming birthdays (within next 365 days)
  Future<List<Map<String, dynamic>>> getSpecialFriendsWithUpcomingBirthdays() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      // Get current user to access special friends list
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data() as Map<String, dynamic>;
      final specialFriends = List<String>.from(userData['specialFriends'] ?? []);

      if (specialFriends.isEmpty) return [];

      List<Map<String, dynamic>> friendsWithBirthdays = [];

      // Get each special friend's data
      for (String friendId in specialFriends) {
        final friendDoc = await _firestore.collection('users').doc(friendId).get();
        if (friendDoc.exists) {
          final friendData = friendDoc.data() as Map<String, dynamic>;
          final birthDate = friendData['birthDate'];
          
          if (birthDate != null) {
            final DateTime friendBirthDate = (birthDate as Timestamp).toDate();
            final countdown = calculateBirthdayCountdown(friendBirthDate);
            
            if (countdown.isThisMonth) {
              friendsWithBirthdays.add({
                'user': UserModel.fromMap({...friendData, 'id': friendId}),
                'countdown': countdown,
              });
            }
          }
        }
      }

      // Sort by days remaining (closest first)
      friendsWithBirthdays.sort((a, b) => 
        (a['countdown'] as BirthdayCountdown).days.compareTo(
          (b['countdown'] as BirthdayCountdown).days
        )
      );

      return friendsWithBirthdays;
    } catch (e) {
      print('Error getting special friends with upcoming birthdays: $e');
      return [];
    }
  }

  // Get friends with birthdays today
  Future<List<UserModel>> getFriendsWithBirthdaysToday() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      // Get current user to access friends list
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data() as Map<String, dynamic>;
      final friends = List<String>.from(userData['friends'] ?? []);

      if (friends.isEmpty) return [];

      List<UserModel> friendsWithBirthdaysToday = [];
      final now = DateTime.now();

      // Get each friend's data
      for (String friendId in friends) {
        final friendDoc = await _firestore.collection('users').doc(friendId).get();
        if (friendDoc.exists) {
          final friendData = friendDoc.data() as Map<String, dynamic>;
          final birthDate = friendData['birthDate'];
          
          if (birthDate != null) {
            final DateTime friendBirthDate = (birthDate as Timestamp).toDate();
            
            // Check if birthday is today
            if (friendBirthDate.month == now.month && friendBirthDate.day == now.day) {
              friendsWithBirthdaysToday.add(
                UserModel.fromMap({...friendData, 'id': friendId})
              );
            }
          }
        }
      }

      return friendsWithBirthdaysToday;
    } catch (e) {
      print('Error getting friends with birthdays today: $e');
      return [];
    }
  }

  // Create a scheduled birthday note
  Future<String?> createBirthdayNote({
    required String friendId,
    required String friendName,
    required String title,
    required String content,
    required DateTime scheduledDate,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      final birthdayNote = BirthdayNote(
        id: '',
        friendId: friendId,
        friendName: friendName,
        title: title,
        content: content,
        scheduledDate: scheduledDate,
        createdAt: DateTime.now(),
        isScheduled: true,
        isSent: false,
      );

      final docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('birthday_notes')
          .add(birthdayNote.toMap());

      return docRef.id;
    } catch (e) {
      print('Error creating birthday note: $e');
      return null;
    }
  }

  // Get scheduled birthday notes for a specific friend
  Stream<List<BirthdayNote>> getBirthdayNotesForFriend(String friendId) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('birthday_notes')
        .where('friendId', isEqualTo: friendId)
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BirthdayNote.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get all scheduled birthday notes
  Stream<List<BirthdayNote>> getAllBirthdayNotes() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('birthday_notes')
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BirthdayNote.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Update a birthday note
  Future<bool> updateBirthdayNote({
    required String noteId,
    required String title,
    required String content,
    required DateTime scheduledDate,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('birthday_notes')
          .doc(noteId)
          .update({
        'title': title,
        'content': content,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
      });

      return true;
    } catch (e) {
      print('Error updating birthday note: $e');
      return false;
    }
  }

  // Delete a birthday note
  Future<bool> deleteBirthdayNote(String noteId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('birthday_notes')
          .doc(noteId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting birthday note: $e');
      return false;
    }
  }

  // Mark birthday note as sent
  Future<bool> markBirthdayNoteAsSent(String noteId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('birthday_notes')
          .doc(noteId)
          .update({
        'isSent': true,
      });

      return true;
    } catch (e) {
      print('Error marking birthday note as sent: $e');
      return false;
    }
  }

  // Send birthday note as message
  Future<bool> sendBirthdayNote(BirthdayNote note) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Generate chat ID
      final chatId = _generateChatId(note.friendId);
      if (chatId.isEmpty) return false;

      // Create the birthday message text
      final messageText = '🎂 ${note.title}\n\n${note.content}';

      // Send the message using MessageService
      await _messageService.sendMessage(
        chatId: chatId,
        text: messageText,
      );

      // Mark the birthday note as sent
      await markBirthdayNoteAsSent(note.id);

      print('Birthday note sent successfully to ${note.friendName}');
      return true;
    } catch (e) {
      print('Error sending birthday note: $e');
      return false;
    }
  }

  // Check and send due birthday notes (this could be called periodically)
  Future<List<String>> checkAndSendDueBirthdayNotes() async {
    List<String> sentNotes = [];
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return sentNotes;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('birthday_notes')
          .where('isScheduled', isEqualTo: true)
          .where('isSent', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        final note = BirthdayNote.fromMap(doc.id, doc.data());
        final scheduledDay = DateTime(
          note.scheduledDate.year,
          note.scheduledDate.month,
          note.scheduledDate.day,
        );

        if (scheduledDay.isAtSameMomentAs(today) || scheduledDay.isBefore(today)) {
          final success = await sendBirthdayNote(note);
          if (success) {
            sentNotes.add('${note.friendName}: ${note.title}');
          }
        }
      }
    } catch (e) {
      print('Error checking and sending due birthday notes: $e');
    }
    return sentNotes;
  }

  // Send a specific birthday note immediately (for testing)
  Future<bool> sendBirthdayNoteImmediately(String noteId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('birthday_notes')
          .doc(noteId)
          .get();

      if (!doc.exists) return false;

      final note = BirthdayNote.fromMap(doc.id, doc.data()!);
      return await sendBirthdayNote(note);
    } catch (e) {
      print('Error sending birthday note immediately: $e');
      return false;
    }
  }
}
