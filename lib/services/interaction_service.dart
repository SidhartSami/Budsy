// services/interaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/interaction_model.dart';
import '../models/user_model.dart';

class InteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _interactionsCollection => 
      _firestore.collection('interactions');
  CollectionReference get _dailyCountsCollection => 
      _firestore.collection('daily_interaction_counts');
  CollectionReference get _usersCollection => 
      _firestore.collection('users');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Send an interaction to a special friend
  Future<void> sendInteraction({
    required String receiverId,
    required InteractionType type,
    String? customMessage,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final interaction = InteractionModel(
      id: '', // Will be set by Firestore
      senderId: currentUserId!,
      receiverId: receiverId,
      type: type,
      customMessage: customMessage,
      createdAt: now,
    );

    // Add interaction to Firestore
    final docRef = await _interactionsCollection.add(interaction.toMap());
    
    // Update daily count
    await _updateDailyCount(currentUserId!, receiverId, now);
    
    // TODO: Send push notification to receiver
  }

  // Update daily interaction count
  Future<void> _updateDailyCount(String senderId, String receiverId, DateTime date) async {
    final today = DateTime(date.year, date.month, date.day);
    final countId = DailyInteractionCount.generateId(senderId, receiverId, today);
    
    final countDoc = _dailyCountsCollection.doc(countId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(countDoc);
      
      if (snapshot.exists) {
        // Update existing count
        final existingCount = DailyInteractionCount.fromFirestore(snapshot);
        
        int newUser1Count = existingCount.user1Count;
        int newUser2Count = existingCount.user2Count;
        
        // Determine which user is sending and increment their count
        if (senderId == existingCount.user1Id) {
          newUser1Count++;
        } else if (senderId == existingCount.user2Id) {
          newUser2Count++;
        }
        
        final updatedCount = existingCount.copyWith(
          user1Count: newUser1Count,
          user2Count: newUser2Count,
          lastUpdated: DateTime.now(),
        );
        
        transaction.update(countDoc, updatedCount.toMap());
      } else {
        // Create new count document
        final users = [senderId, receiverId]..sort();
        final isUser1Sender = senderId == users[0];
        
        final newCount = DailyInteractionCount(
          id: countId,
          user1Id: users[0],
          user2Id: users[1],
          date: today,
          user1Count: isUser1Sender ? 1 : 0,
          user2Count: isUser1Sender ? 0 : 1,
          lastUpdated: DateTime.now(),
        );
        
        transaction.set(countDoc, newCount.toMap());
      }
    });
  }

  // Get today's interaction count between current user and a special friend
  Future<DailyInteractionCount?> getTodaysCount(String friendId) async {
    if (currentUserId == null) return null;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final countId = DailyInteractionCount.generateId(currentUserId!, friendId, todayDate);
    
    final doc = await _dailyCountsCollection.doc(countId).get();
    
    if (doc.exists) {
      return DailyInteractionCount.fromFirestore(doc);
    }
    
    return null;
  }

  // Get interaction history between current user and a friend
  Stream<List<InteractionModel>> getInteractionHistory(String friendId, {int limit = 50}) {
    if (currentUserId == null) return Stream.value([]);
    
    return _interactionsCollection
        .where('senderId', whereIn: [currentUserId!, friendId])
        .where('receiverId', whereIn: [currentUserId!, friendId])
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InteractionModel.fromFirestore(doc))
            .where((interaction) => 
                (interaction.senderId == currentUserId! && interaction.receiverId == friendId) ||
                (interaction.senderId == friendId && interaction.receiverId == currentUserId!))
            .toList());
  }

  // Get today's interactions between current user and a friend
  Stream<List<InteractionModel>> getTodaysInteractions(String friendId) {
    if (currentUserId == null) return Stream.value([]);
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _interactionsCollection
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InteractionModel.fromFirestore(doc))
            .where((interaction) => 
                (interaction.senderId == currentUserId! && interaction.receiverId == friendId) ||
                (interaction.senderId == friendId && interaction.receiverId == currentUserId!))
            .toList());
  }

  // Mark interaction as read
  Future<void> markAsRead(String interactionId) async {
    await _interactionsCollection.doc(interactionId).update({
      'isRead': true,
      'readAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Respond to an interaction
  Future<void> respondToInteraction(String interactionId, String response) async {
    await _interactionsCollection.doc(interactionId).update({
      'response': response,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Get user's special friends with their interaction counts for today
  Future<List<Map<String, dynamic>>> getSpecialFriendsWithCounts() async {
    if (currentUserId == null) return [];
    
    // Get current user data
    final userDoc = await _usersCollection.doc(currentUserId!).get();
    if (!userDoc.exists) return [];
    
    final user = UserModel.fromFirestore(userDoc);
    final specialFriends = user.specialFriends;
    
    if (specialFriends.isEmpty) return [];
    
    // Get user data for all special friends
    final friendsData = <Map<String, dynamic>>[];
    
    for (String friendId in specialFriends) {
      final friendDoc = await _usersCollection.doc(friendId).get();
      if (friendDoc.exists) {
        final friend = UserModel.fromFirestore(friendDoc);
        final todaysCount = await getTodaysCount(friendId);
        
        friendsData.add({
          'friend': friend,
          'count': todaysCount,
          'myCount': todaysCount?.getCountForUser(currentUserId!) ?? 0,
          'theirCount': todaysCount?.getCountForUser(friendId) ?? 0,
          'totalCount': todaysCount?.totalCount ?? 0,
        });
      }
    }
    
    return friendsData;
  }

  // Get unread interactions for current user
  Stream<List<InteractionModel>> getUnreadInteractions() {
    if (currentUserId == null) return Stream.value([]);
    
    return _interactionsCollection
        .where('receiverId', isEqualTo: currentUserId!)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InteractionModel.fromFirestore(doc))
            .toList());
  }

  // Clean up old interactions (older than 30 days)
  Future<void> cleanupOldInteractions() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final oldInteractions = await _interactionsCollection
        .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();
    
    final batch = _firestore.batch();
    for (var doc in oldInteractions.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // Clean up old daily counts (older than 30 days)
  Future<void> cleanupOldDailyCounts() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final oldCounts = await _dailyCountsCollection
        .where('date', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();
    
    final batch = _firestore.batch();
    for (var doc in oldCounts.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // Get interaction statistics for a user
  Future<Map<String, int>> getInteractionStats(String friendId, {int days = 7}) async {
    if (currentUserId == null) return {};
    
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    final interactions = await _interactionsCollection
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
    
    int sent = 0;
    int received = 0;
    
    for (var doc in interactions.docs) {
      final interaction = InteractionModel.fromFirestore(doc);
      
      if ((interaction.senderId == currentUserId! && interaction.receiverId == friendId) ||
          (interaction.senderId == friendId && interaction.receiverId == currentUserId!)) {
        if (interaction.senderId == currentUserId!) {
          sent++;
        } else {
          received++;
        }
      }
    }
    
    return {
      'sent': sent,
      'received': received,
      'total': sent + received,
    };
  }
}
