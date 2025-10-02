// services/message_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutortyper_app/models/message_model.dart';

class MessageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  // Send a text message
  Future<void> sendMessage({
    required String chatId,
    required String text,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (text.trim().isEmpty && imageUrl == null && fileUrl == null) {
      throw Exception('Message cannot be empty');
    }

    try {
      print('DEBUG: Sending message to chat: $chatId');
      print('DEBUG: Message text: $text');
      print('DEBUG: Sender ID: $currentUserId');

      // Generate message ID
      final messageId = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc()
          .id;

      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: currentUserId!,
        text: text.trim(),
        timestamp: DateTime.now(),
        isRead: false,
        imageUrl: imageUrl,
        fileUrl: fileUrl,
        fileName: fileName,
      );

      // Use a transaction to send message and update chat metadata
      await _firestore.runTransaction((transaction) async {
        final messageRef = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId);

        final chatRef = _firestore.collection('chats').doc(chatId);

        // Add the message
        transaction.set(messageRef, message.toMap());

        // Update chat with last message info
        transaction.update(chatRef, {
          'lastMessage': text.trim(),
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': currentUserId,
        });
      });

      print('DEBUG: Message sent successfully');
    } catch (e) {
      print('DEBUG: Error sending message: $e');
      rethrow;
    }
  }

  // Get messages stream for a chat
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    print('DEBUG: Getting messages stream for chat: $chatId');

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          print('DEBUG: Received ${snapshot.docs.length} messages');
          final allMessages = snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList();
          
          // Filter out messages deleted by current user
          final visibleMessages = allMessages
              .where((message) => !message.deletedBy.contains(currentUserId))
              .toList();
          
          print('DEBUG: Filtered to ${visibleMessages.length} visible messages for user $currentUserId');
          return visibleMessages;
        });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(
    String chatId,
    List<String> messageIds,
  ) async {
    if (currentUserId == null || messageIds.isEmpty) return;

    try {
      final batch = _firestore.batch();

      for (final messageId in messageIds) {
        final messageRef = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId);

        batch.update(messageRef, {'isRead': true});
      }

      await batch.commit();
      print('DEBUG: Marked ${messageIds.length} messages as read');
    } catch (e) {
      print('DEBUG: Error marking messages as read: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      print('DEBUG: Message deleted successfully');
    } catch (e) {
      print('DEBUG: Error deleting message: $e');
      rethrow;
    }
  }

  // Clear all messages in a chat (for current user only)
  Future<void> clearChatMessages(String chatId) async {
    if (currentUserId == null) return;

    try {
      // Get all messages
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      // Mark messages as deleted for current user (in batches)
      final batch = _firestore.batch();

      for (final doc in messagesSnapshot.docs) {
        final messageData = doc.data();
        final deletedBy = List<String>.from(messageData['deletedBy'] ?? []);
        
        // Add current user to deletedBy list if not already present
        if (!deletedBy.contains(currentUserId)) {
          deletedBy.add(currentUserId!);
          batch.update(doc.reference, {'deletedBy': deletedBy});
        }
      }

      await batch.commit();

      print('DEBUG: Chat cleared successfully for user $currentUserId');
    } catch (e) {
      print('DEBUG: Error clearing chat: $e');
      rethrow;
    }
  }
}
