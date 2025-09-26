// lib/services/chat_settings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutortyper_app/models/chat_settings_model.dart';
import 'package:tutortyper_app/services/user_service.dart';

class ChatSettingsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate unique settings ID
  static String _generateSettingsId(String chatId, String userId) {
    return '${chatId}_$userId';
  }

  // Get chat settings for current user
  Future<ChatSettingsModel?> getChatSettings(String chatId) async {
    final currentUserId = UserService.currentUserId;
    if (currentUserId == null) return null;

    try {
      final settingsId = _generateSettingsId(chatId, currentUserId);
      final doc = await _firestore
          .collection('chatSettings')
          .doc(settingsId)
          .get();

      if (doc.exists) {
        return ChatSettingsModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting chat settings: $e');
      return null;
    }
  }

  // Stream chat settings for current user
  Stream<ChatSettingsModel?> getChatSettingsStream(String chatId) {
    final currentUserId = UserService.currentUserId;
    if (currentUserId == null) return Stream.value(null);

    final settingsId = _generateSettingsId(chatId, currentUserId);
    return _firestore
        .collection('chatSettings')
        .doc(settingsId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return ChatSettingsModel.fromMap(doc.data()!);
          }
          return null;
        });
  }

  // Create or update chat settings
  Future<void> updateChatSettings({
    required String chatId,
    String? nickname,
    bool? isMuted,
    bool? isBlocked,
    String? chatTheme,
    DateTime? mutedUntil,
  }) async {
    final currentUserId = UserService.currentUserId;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final settingsId = _generateSettingsId(chatId, currentUserId);
      final now = DateTime.now();

      // Get existing settings or create new ones
      final existingDoc = await _firestore
          .collection('chatSettings')
          .doc(settingsId)
          .get();

      ChatSettingsModel settings;
      if (existingDoc.exists) {
        // Update existing settings
        final existing = ChatSettingsModel.fromMap(existingDoc.data()!);
        settings = existing.copyWith(
          nickname: nickname,
          isMuted: isMuted,
          isBlocked: isBlocked,
          chatTheme: chatTheme,
          mutedUntil: mutedUntil,
          updatedAt: now,
        );
      } else {
        // Create new settings
        settings = ChatSettingsModel(
          id: settingsId,
          chatId: chatId,
          userId: currentUserId,
          nickname: nickname,
          isMuted: isMuted ?? false,
          isBlocked: isBlocked ?? false,
          chatTheme: chatTheme ?? 'default',
          mutedUntil: mutedUntil,
          createdAt: now,
          updatedAt: now,
        );
      }

      await _firestore
          .collection('chatSettings')
          .doc(settingsId)
          .set(settings.toMap());

      print('Chat settings updated successfully');
    } catch (e) {
      print('Error updating chat settings: $e');
      rethrow;
    }
  }

  // Set nickname for a friend in a chat
  Future<void> setNickname(String chatId, String nickname) async {
    await updateChatSettings(
      chatId: chatId,
      nickname: nickname.trim().isEmpty ? null : nickname.trim(),
    );
  }

  // Mute/unmute chat
  Future<void> toggleMute(String chatId, {DateTime? mutedUntil}) async {
    final currentSettings = await getChatSettings(chatId);
    final isCurrentlyMuted = currentSettings?.isMuted ?? false;

    await updateChatSettings(
      chatId: chatId,
      isMuted: !isCurrentlyMuted,
      mutedUntil: !isCurrentlyMuted ? mutedUntil : null,
    );
  }

  // Block/unblock user
  Future<void> toggleBlock(String chatId) async {
    final currentSettings = await getChatSettings(chatId);
    final isCurrentlyBlocked = currentSettings?.isBlocked ?? false;

    await updateChatSettings(chatId: chatId, isBlocked: !isCurrentlyBlocked);
  }

  Future<void> clearChatHistory(String chatId) async {
    final currentUserId = UserService.currentUserId;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      // Start a batch operation for atomic updates
      final batch = _firestore.batch();

      // Get all messages in the chat
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      print('Found ${messagesQuery.docs.length} messages to delete');

      // Delete each message document
      for (final doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Update chat document to reflect cleared state
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': null,
        'lastMessageTime': null,
        'messageCount': 0,
        'clearedAt': FieldValue.serverTimestamp(),
        'clearedBy': currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reset chat statistics for current user
      final statsId = _generateSettingsId(chatId, currentUserId);
      final statsRef = _firestore.collection('chatStats').doc(statsId);

      // Check if stats document exists before updating
      final statsDoc = await statsRef.get();
      if (statsDoc.exists) {
        batch.update(statsRef, {
          'messagesSent': 0,
          'messagesReceived': 0,
          'firstMessageDate': null,
          'lastMessageDate': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit all changes atomically
      await batch.commit();

      print('Chat history cleared successfully for chat: $chatId');
    } catch (e) {
      print('Error clearing chat history: $e');
      rethrow;
    }
  }

  // Change chat theme
  Future<void> setChatTheme(String chatId, String theme) async {
    await updateChatSettings(chatId: chatId, chatTheme: theme);
  }

  // Get chat statistics
  Future<ChatStatsModel?> getChatStats(String chatId) async {
    final currentUserId = UserService.currentUserId;
    if (currentUserId == null) return null;

    try {
      final statsId = _generateSettingsId(chatId, currentUserId);
      final doc = await _firestore.collection('chatStats').doc(statsId).get();

      if (doc.exists) {
        return ChatStatsModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting chat stats: $e');
      return null;
    }
  }

  // Update chat statistics (called when messages are sent/received)
  Future<void> updateChatStats({
    required String chatId,
    required bool isMessageSent, // true if current user sent, false if received
    required DateTime messageTime,
  }) async {
    final currentUserId = UserService.currentUserId;
    if (currentUserId == null) return;

    try {
      final statsId = _generateSettingsId(chatId, currentUserId);
      final now = DateTime.now();

      // Get existing stats or create new ones
      final existingDoc = await _firestore
          .collection('chatStats')
          .doc(statsId)
          .get();

      ChatStatsModel stats;
      if (existingDoc.exists) {
        final existing = ChatStatsModel.fromMap(existingDoc.data()!);
        stats = existing.copyWith(
          messagesSent: isMessageSent
              ? existing.messagesSent + 1
              : existing.messagesSent,
          messagesReceived: !isMessageSent
              ? existing.messagesReceived + 1
              : existing.messagesReceived,
          firstMessageDate: existing.firstMessageDate ?? messageTime,
          lastMessageDate: messageTime,
          updatedAt: now,
        );
      } else {
        stats = ChatStatsModel(
          id: statsId,
          chatId: chatId,
          userId: currentUserId,
          messagesSent: isMessageSent ? 1 : 0,
          messagesReceived: isMessageSent ? 0 : 1,
          firstMessageDate: messageTime,
          lastMessageDate: messageTime,
          createdAt: now,
          updatedAt: now,
        );
      }

      await _firestore.collection('chatStats').doc(statsId).set(stats.toMap());
    } catch (e) {
      print('Error updating chat stats: $e');
    }
  }

  // Search messages in a chat
  Future<List<Map<String, dynamic>>> searchMessages(
    String chatId,
    String query,
  ) async {
    if (query.trim().isEmpty) return [];

    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that gets all messages and filters locally
      // For production, consider using Algolia, Elasticsearch, or similar

      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1000) // Limit to prevent excessive data transfer
          .get();

      final results = <Map<String, dynamic>>[];
      final searchQuery = query.toLowerCase().trim();

      for (var doc in messagesSnapshot.docs) {
        final messageData = doc.data();
        final messageText = (messageData['text'] ?? '')
            .toString()
            .toLowerCase();

        if (messageText.contains(searchQuery)) {
          results.add({
            'messageId': doc.id,
            'text': messageData['text'],
            'senderId': messageData['senderId'],
            'timestamp': messageData['timestamp'],
            'messageType': messageData['messageType'] ?? 'text',
          });
        }
      }

      return results;
    } catch (e) {
      print('Error searching messages: $e');
      return [];
    }
  }

  // Get available chat themes
  static List<Map<String, dynamic>> getChatThemes() {
    return [
      {
        'id': 'default',
        'name': 'Default',
        'primaryColor': 0xFF68EAFF, // Your current theme color
        'secondaryColor': 0xFFF5F5F5,
        'backgroundColor': 0xFFF5F5F5,
      },
      {
        'id': 'dark',
        'name': 'Dark',
        'primaryColor': 0xFF2196F3,
        'secondaryColor': 0xFF424242,
        'backgroundColor': 0xFF121212,
      },
      {
        'id': 'ocean',
        'name': 'Ocean',
        'primaryColor': 0xFF006064,
        'secondaryColor': 0xFF4DD0E1,
        'backgroundColor': 0xFFE0F2F1,
      },
      {
        'id': 'sunset',
        'name': 'Sunset',
        'primaryColor': 0xFFFF7043,
        'secondaryColor': 0xFFFFAB91,
        'backgroundColor': 0xFFFFF3E0,
      },
      {
        'id': 'forest',
        'name': 'Forest',
        'primaryColor': 0xFF388E3C,
        'secondaryColor': 0xFF81C784,
        'backgroundColor': 0xFFE8F5E8,
      },
      {
        'id': 'purple',
        'name': 'Purple',
        'primaryColor': 0xFF7B1FA2,
        'secondaryColor': 0xFFBA68C8,
        'backgroundColor': 0xFFF3E5F5,
      },
    ];
  }

  // Delete all chat settings and stats (used when removing friend)
  Future<void> deleteChatData(String chatId) async {
    final currentUserId = UserService.currentUserId;
    if (currentUserId == null) return;

    try {
      final settingsId = _generateSettingsId(chatId, currentUserId);

      await Future.wait([
        _firestore.collection('chatSettings').doc(settingsId).delete(),
        _firestore.collection('chatStats').doc(settingsId).delete(),
      ]);

      print('Chat data deleted successfully');
    } catch (e) {
      print('Error deleting chat data: $e');
    }
  }
}
