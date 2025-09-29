import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/constants/app_constants.dart';
import '../../../core/database/cosmos_db_service.dart';
import '../../../core/errors/api_exception.dart';
import '../../../shared/models/message_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final CosmosDbService _cosmosDb = CosmosDbService();
  io.Socket? _socket;
  final StreamController<List<MessageModel>> _messagesController = StreamController<List<MessageModel>>.broadcast();
  final StreamController<MessageModel> _newMessageController = StreamController<MessageModel>.broadcast();
  final StreamController<String> _connectionStatusController = StreamController<String>.broadcast();

  Stream<List<MessageModel>> get messagesStream => _messagesController.stream;
  Stream<MessageModel> get newMessageStream => _newMessageController.stream;
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void initialize() {
    _connectSocket();
  }

  void _connectSocket() {
    try {
      _socket = io.io(AppConstants.socketUrl, io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build());

      _socket!.onConnect((_) {
        _connectionStatusController.add('connected');
      });

      _socket!.onDisconnect((_) {
        _connectionStatusController.add('disconnected');
      });

      _socket!.onConnectError((error) {
        _connectionStatusController.add('error');
      });

      // Listen for new messages
      _socket!.on('new_message', (data) {
        try {
          final message = MessageModel.fromJson(data);
          _newMessageController.add(message);
        } catch (e) {
          // Handle error
        }
      });

      // Listen for room updates
      _socket!.on('room_update', (data) {
        // Handle room updates
      });

    } catch (e) {
      _connectionStatusController.add('error');
    }
  }

  Future<void> joinRoom(String roomId, String userId) async {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_room', {
        'roomId': roomId,
        'userId': userId,
      });
    }
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave_room', {
        'roomId': roomId,
        'userId': userId,
      });
    }
  }

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String content,
    MessageType messageType = MessageType.text,
    String? attachmentUrl,
    String? attachmentType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        receiverName: receiverName,
        message: content,
        type: messageType,
        timestamp: DateTime.now(),
        isRead: false,
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
        metadata: metadata,
      );

      // Save to database
      await _cosmosDb.createMessage(message.toJson());

      // Send via socket
      if (_socket != null && _socket!.connected) {
        _socket!.emit('send_message', message.toJson());
      }

      // Add to local stream
      _newMessageController.add(message);

    } catch (e) {
      throw ApiException('Failed to send message: ${e.toString()}');
    }
  }

  Future<List<MessageModel>> getMessages(String roomId, {int limit = 50}) async {
    try {
      final messages = await _cosmosDb.getMessages(roomId);
      
      // Sort by timestamp and limit
      messages.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] ?? DateTime.now().toIso8601String());
        final bTime = DateTime.parse(b['timestamp'] ?? DateTime.now().toIso8601String());
        return aTime.compareTo(bTime);
      });
      
      if (messages.length > limit) {
        messages.removeRange(0, messages.length - limit);
      }
      
      return messages.map((m) => MessageModel.fromJson(m)).toList();
    } catch (e) {
      throw ApiException('Failed to fetch messages: ${e.toString()}');
    }
  }

  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      final message = await _cosmosDb.getDocument('Messages', messageId);
      message['isRead'] = true;
      message['readBy'] = [...(message['readBy'] ?? []), userId];
      message['readAt'] = DateTime.now().toIso8601String();
      
      await _cosmosDb.updateDocument('Messages', messageId, message);
    } catch (e) {
      throw ApiException('Failed to mark message as read: ${e.toString()}');
    }
  }

  Future<void> deleteMessage(String messageId, String userId) async {
    try {
      // Verify user has permission to delete (sender or admin)
      final message = await _cosmosDb.getDocument('Messages', messageId);
      if (message['senderId'] != userId) {
        throw ApiException('Unauthorized to delete this message');
      }
      
      await _cosmosDb.deleteDocument('Messages', messageId);
    } catch (e) {
      throw ApiException('Failed to delete message: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getChatRooms(String userId) async {
    try {
      // Get rooms where user is a participant
      final rooms = await _cosmosDb.queryDocuments(
        'ChatRooms',
        'SELECT * FROM c WHERE ARRAY_CONTAINS(c.participants, @userId)',
        parameters: {'@userId': userId},
      );
      
      // Get last message for each room
      for (final room in rooms) {
        try {
          final lastMessages = await _cosmosDb.queryDocuments(
            'Messages',
            'SELECT TOP 1 * FROM c WHERE c.roomId = @roomId ORDER BY c.timestamp DESC',
            parameters: {'@roomId': room['id']},
          );
          
          room['lastMessage'] = lastMessages.isNotEmpty ? lastMessages.first : null;
          
          // Get unread count
          final unreadMessages = await _cosmosDb.queryDocuments(
            'Messages',
            'SELECT VALUE COUNT(1) FROM c WHERE c.roomId = @roomId AND c.senderId != @userId AND NOT ARRAY_CONTAINS(c.readBy, @userId)',
            parameters: {'@roomId': room['id'], '@userId': userId},
          );
          
          room['unreadCount'] = unreadMessages.isNotEmpty ? unreadMessages.first : 0;
        } catch (e) {
          room['lastMessage'] = null;
          room['unreadCount'] = 0;
        }
      }
      
      return rooms;
    } catch (e) {
      throw ApiException('Failed to fetch chat rooms: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createChatRoom({
    required String name,
    required List<String> participants,
    String? description,
    String? roomType,
  }) async {
    try {
      final room = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'description': description ?? '',
        'roomType': roomType ?? 'group',
        'participants': participants,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': participants.first,
        'isActive': true,
      };
      
      return await _cosmosDb.createDocument('ChatRooms', room);
    } catch (e) {
      throw ApiException('Failed to create chat room: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getOrCreateDirectChat({
    required String userId1,
    required String userId2,
  }) async {
    try {
      // Check if direct chat already exists
      final existingRooms = await _cosmosDb.queryDocuments(
        'ChatRooms',
        'SELECT * FROM c WHERE c.roomType = @roomType AND ARRAY_CONTAINS(c.participants, @user1) AND ARRAY_CONTAINS(c.participants, @user2)',
        parameters: {
          '@roomType': 'direct',
          '@user1': userId1,
          '@user2': userId2,
        },
      );
      
      if (existingRooms.isNotEmpty) {
        return existingRooms.first;
      }
      
      // Create new direct chat room
      final roomName = 'Direct Chat'; // In real app, you might want to use user names
      return await createChatRoom(
        name: roomName,
        participants: [userId1, userId2],
        roomType: 'direct',
      );
    } catch (e) {
      throw ApiException('Failed to get or create direct chat: ${e.toString()}');
    }
  }

  Future<void> addParticipantToRoom(String roomId, String userId) async {
    try {
      final room = await _cosmosDb.getDocument('ChatRooms', roomId);
      final participants = List<String>.from(room['participants'] ?? []);
      
      if (!participants.contains(userId)) {
        participants.add(userId);
        room['participants'] = participants;
        await _cosmosDb.updateDocument('ChatRooms', roomId, room);
      }
    } catch (e) {
      throw ApiException('Failed to add participant: ${e.toString()}');
    }
  }

  Future<void> removeParticipantFromRoom(String roomId, String userId) async {
    try {
      final room = await _cosmosDb.getDocument('ChatRooms', roomId);
      final participants = List<String>.from(room['participants'] ?? []);
      
      participants.remove(userId);
      room['participants'] = participants;
      await _cosmosDb.updateDocument('ChatRooms', roomId, room);
    } catch (e) {
      throw ApiException('Failed to remove participant: ${e.toString()}');
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _messagesController.close();
    _newMessageController.close();
    _connectionStatusController.close();
  }
}
