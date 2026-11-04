import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'auth_service.dart';
import 'notification_service.dart';

enum MessageStatus { sending, sent, delivered, read }

class MessageModel {
  final String id;
  final String conversationId;
  final String senderUsername;
  final String? recipientUsername;
  final String content;
  final bool isVoice;
  final String? voiceDuration;
  final String? mediaUrl;
  final String? mediaType; // 'image', 'file', 'voice'
  final List<String> reactions;
  final bool isMe;
  final String time;
  final MessageStatus status;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderUsername,
    this.recipientUsername,
    required this.content,
    this.isVoice = false,
    this.voiceDuration,
    this.mediaUrl,
    this.mediaType,
    this.reactions = const [],
    required this.isMe,
    required this.time,
    this.status = MessageStatus.read,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String currentUsername) {
    final sender = (map['sender_username'] ?? map['sender_id'] ?? '').toString();
    final createdAt = DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now();
    String content = map['content']?.toString() ?? '';
    String? mediaUrl = map['media_url']?.toString();

    // Parse embedded media tag if media_url column is empty in table
    if ((mediaUrl == null || mediaUrl.isEmpty) && content.contains('[MEDIA: ')) {
      final match = RegExp(r'\[MEDIA:\s*([^\]]+)\]').firstMatch(content);
      if (match != null) {
        mediaUrl = match.group(1)?.trim();
        content = content.replaceAll(match.group(0)!, '').trim();
      }
    }

    final rawIsVoice = map['is_voice'] == true;
    final hasValidMedia = mediaUrl != null && mediaUrl.isNotEmpty;
    final isVoice = rawIsVoice && hasValidMedia;

    String? voiceDuration;
    if (isVoice) {
      final seconds = (map['voice_duration_seconds'] as num?)?.toInt() ?? 0;
      final mins = seconds ~/ 60;
      final remSecs = seconds % 60;
      voiceDuration = '$mins:${remSecs.toString().padLeft(2, '0')}';
    }

    final reactionsList = (map['reactions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final isMe = sender == currentUsername;

    MessageStatus stat = MessageStatus.read;
    final rawStatus = map['status']?.toString();
    if (rawStatus == 'sending') {
      stat = MessageStatus.sending;
    } else if (rawStatus == 'sent') {
      stat = MessageStatus.sent;
    } else if (rawStatus == 'delivered') {
      stat = MessageStatus.delivered;
    } else if (rawStatus == 'read') {
      stat = MessageStatus.read;
    }

    return MessageModel(
      id: map['id']?.toString() ?? '',
      conversationId: map['conversation_id']?.toString() ?? '',
      senderUsername: sender,
      recipientUsername: map['recipient_username']?.toString(),
      content: map['content']?.toString() ?? '',
      isVoice: isVoice,
      voiceDuration: voiceDuration,
      mediaUrl: mediaUrl,
      mediaType: map['media_type']?.toString(),
      reactions: reactionsList,
      isMe: isMe,
      time: '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
      status: stat,
      createdAt: createdAt,
    );
  }
}

class ConversationSummary {
  final String id;
  final String name;
  final String username;
  final String lastMessage;
  final String time;
  final bool isChannel;
  final bool isGroup;
  final String ownerUsername;
  final List<String> adminUsernames;
  final List<String> memberUsernames;
  final String? avatarUrl;
  final String? description;
  bool isMuted;

  ConversationSummary({
    required this.id,
    required this.name,
    required this.username,
    required this.lastMessage,
    required this.time,
    this.isChannel = false,
    this.isGroup = false,
    String? ownerUsername,
    List<String>? adminUsernames,
    List<String>? memberUsernames,
    this.avatarUrl,
    this.description,
    this.isMuted = false,
  })  : ownerUsername = ownerUsername ?? username,
        adminUsernames = adminUsernames ?? [],
        memberUsernames = memberUsernames ?? [];

  bool canUserPost(String currentUsername) {
    if (!isChannel) return true; // Direct & Groups allow members to post
    final clean = currentUsername.replaceAll('@', '').trim().toLowerCase();
    if (ownerUsername.toLowerCase() == clean) return true;
    return adminUsernames.map((u) => u.toLowerCase()).contains(clean);
  }
}

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  RealtimeChannel? _activeChannel;
  final List<ConversationSummary> _conversations = [];
  final Map<String, List<MessageModel>> _messagesByConv = {};

  List<ConversationSummary> get activeConversations => List.unmodifiable(_conversations);

  static String directConvId(String userA, String userB) {
    final cleanA = userA.replaceAll('@', '').trim().toLowerCase();
    final cleanB = userB.replaceAll('@', '').trim().toLowerCase();
    final list = [cleanA, cleanB]..sort();
    return 'direct_${list[0]}_${list[1]}';
  }

  void createOrOpenConversation({
    required String name,
    required String username,
    bool isChannel = false,
    bool isGroup = false,
    String? description,
    String? avatarUrl,
  }) {
    final cleanUsername = username.replaceAll('@', '').trim().toLowerCase();
    final myUsername = AuthService.instance.currentUser.username.replaceAll('@', '').trim().toLowerCase();
    final convId = isChannel
        ? 'channel_$cleanUsername'
        : isGroup
            ? 'group_$cleanUsername'
            : directConvId(myUsername, cleanUsername);

    final existingIndex = _conversations.indexWhere((c) => c.id == convId || c.username == cleanUsername);
    if (existingIndex == -1) {
      _conversations.insert(
        0,
        ConversationSummary(
          id: convId,
          name: name.trim(),
          username: cleanUsername,
          lastMessage: isChannel ? 'تم إنشاء القناة' : isGroup ? 'تم إنشاء المجموعة' : 'محادثة خاصة جديدة',
          time: 'الآن',
          isChannel: isChannel,
          isGroup: isGroup,
          ownerUsername: myUsername,
          description: description,
          avatarUrl: avatarUrl,
          memberUsernames: [myUsername],
        ),
      );
    }
  }

  ConversationSummary? getConversationById(String conversationId) {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) return _conversations[idx];
    return null;
  }

  void toggleMute(String conversationId) {
    final conv = getConversationById(conversationId);
    if (conv != null) {
      conv.isMuted = !conv.isMuted;
    }
  }

  void clearHistory(String conversationId) {
    _messagesByConv[conversationId]?.clear();
  }

  void promoteMember(String conversationId, String username) {
    final conv = getConversationById(conversationId);
    if (conv != null && !conv.adminUsernames.contains(username)) {
      conv.adminUsernames.add(username);
    }
  }

  void removeMember(String conversationId, String username) {
    final conv = getConversationById(conversationId);
    if (conv != null) {
      conv.memberUsernames.remove(username);
      conv.adminUsernames.remove(username);
    }
  }

  List<ConversationSummary> searchChannelsAndGroups(String query) {
    final clean = query.replaceAll('@', '').trim().toLowerCase();
    if (clean.isEmpty) return [];
    return _conversations.where((c) {
      if (!c.isChannel && !c.isGroup) return false;
      return c.name.toLowerCase().contains(clean) || c.username.toLowerCase().contains(clean);
    }).toList();
  }

  Future<List<ConversationSummary>> fetchUserConversations() async {
    final currentUsername = AuthService.instance.currentUser.username.replaceAll('@', '').trim().toLowerCase();
    final client = SupabaseConfig.client;
    final Map<String, ConversationSummary> convMap = {};

    for (final c in _conversations) {
      convMap[c.id] = c;
    }

    if (client != null) {
      try {
        final res = await client
            .from('messages')
            .select('*')
            .or('sender_username.eq.$currentUsername,recipient_username.eq.$currentUsername')
            .order('created_at', ascending: false)
            .limit(100);

        for (final item in res as List<dynamic>) {
          final convId = item['conversation_id']?.toString() ?? '';
          if (convId.isEmpty) continue;
          if (!convMap.containsKey(convId)) {
            final sender = (item['sender_username']?.toString() ?? '').toLowerCase();
            final recipient = (item['recipient_username']?.toString() ?? '').toLowerCase();
            final otherUser = (sender == currentUsername) ? recipient : sender;
            final isChan = convId.startsWith('channel_');
            final isGrp = convId.startsWith('group_');
            final name = isChan
                ? 'قناة ${convId.replaceFirst('channel_', '')}'
                : isGrp
                    ? 'مجموعة ${convId.replaceFirst('group_', '')}'
                    : (otherUser.isNotEmpty ? otherUser : 'محادثة خاصة');

            convMap[convId] = ConversationSummary(
              id: convId,
              name: name,
              username: otherUser,
              lastMessage: item['content']?.toString() ?? '',
              time: 'مؤخراً',
              isChannel: isChan,
              isGroup: isGrp,
              ownerUsername: sender,
            );
          }
        }

        // Fetch avatars & display names for direct conversations from profiles
        final usernamesToFetch = convMap.values
            .where((c) => !c.isChannel && !c.isGroup && c.username.isNotEmpty && (c.avatarUrl == null || c.avatarUrl!.isEmpty))
            .map((c) => c.username)
            .toSet()
            .toList();

        if (usernamesToFetch.isNotEmpty) {
          try {
            final profilesRes = await client
                .from('profiles')
                .select('username, avatar_url, full_name')
                .filter('username', 'in', usernamesToFetch);

            final Map<String, Map<String, dynamic>> profileMap = {};
            for (final p in (profilesRes as List<dynamic>)) {
              final un = p['username']?.toString().toLowerCase() ?? '';
              if (un.isNotEmpty) profileMap[un] = Map<String, dynamic>.from(p as Map);
            }

            for (final key in convMap.keys.toList()) {
              final c = convMap[key]!;
              final p = profileMap[c.username.toLowerCase()];
              if (p != null) {
                final av = p['avatar_url']?.toString();
                final fn = p['full_name']?.toString();
                convMap[key] = ConversationSummary(
                  id: c.id,
                  name: (fn != null && fn.isNotEmpty && !c.isChannel && !c.isGroup) ? fn : c.name,
                  username: c.username,
                  lastMessage: c.lastMessage,
                  time: c.time,
                  isChannel: c.isChannel,
                  isGroup: c.isGroup,
                  ownerUsername: c.ownerUsername,
                  adminUsernames: c.adminUsernames,
                  memberUsernames: c.memberUsernames,
                  avatarUrl: av,
                  description: c.description,
                  isMuted: c.isMuted,
                );
              }
            }
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('Error fetching conversations: $e');
      }
    }

    return convMap.values.toList();
  }

  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    final currentUsername = AuthService.instance.currentUser.username;
    final client = SupabaseConfig.client;

    if (client != null) {
      try {
        final res = await client
            .from('messages')
            .select('*')
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: true);

        final list = (res as List<dynamic>)
            .map((item) => MessageModel.fromMap(item as Map<String, dynamic>, currentUsername))
            .toList();

        if (list.isNotEmpty) return list;
      } catch (e) {
        debugPrint('Error fetching messages: $e');
      }
    }

    return List.from(_messagesByConv[conversationId] ?? []);
  }

  Future<bool> sendMessage({
    required String conversationId,
    required String content,
    String? recipientUsername,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final currentUsername = AuthService.instance.currentUser.username;
    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final newMsg = MessageModel(
      id: 'msg_${now.millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderUsername: currentUsername,
      recipientUsername: recipientUsername,
      content: content.trim(),
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      isMe: true,
      time: timeStr,
      status: MessageStatus.read, // Delivered & Read
      createdAt: now,
    );

    _messagesByConv.putIfAbsent(conversationId, () => []).add(newMsg);

    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final old = _conversations[idx];
      _conversations[idx] = ConversationSummary(
        id: old.id,
        name: old.name,
        username: old.username,
        lastMessage: content.trim().isNotEmpty ? content.trim() : (mediaType == 'image' ? '📷 صورة' : 'مرفق'),
        time: timeStr,
        isChannel: old.isChannel,
        isGroup: old.isGroup,
        ownerUsername: old.ownerUsername,
        adminUsernames: old.adminUsernames,
        memberUsernames: old.memberUsernames,
        avatarUrl: old.avatarUrl,
        description: old.description,
        isMuted: old.isMuted,
      );
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final contentToSave = (mediaUrl != null && mediaUrl.isNotEmpty)
            ? '$content [MEDIA: $mediaUrl]'
            : content.trim();

        await client.from('messages').insert({
          'conversation_id': conversationId,
          'sender_username': currentUsername,
          'recipient_username': recipientUsername,
          'content': contentToSave,
          'created_at': now.toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error saving message to Supabase: $e');
      }
    }

    if (recipientUsername != null && recipientUsername.isNotEmpty) {
      NotificationService.instance.sendNotificationToUser(
        targetUsername: recipientUsername,
        type: 'comment',
        title: 'رسالة خاصة من @$currentUsername',
        body: content.isNotEmpty ? content : 'أرسل لك صورة مرفقة 📷',
        targetType: 'chat',
        targetId: conversationId,
      );
    }

    return true;
  }

  Future<bool> sendVoiceMessage({
    required String conversationId,
    required String duration,
    String? recipientUsername,
  }) async {
    final currentUsername = AuthService.instance.currentUser.username;
    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final newVoiceMsg = MessageModel(
      id: 'voice_${now.millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderUsername: currentUsername,
      recipientUsername: recipientUsername,
      content: '[صوت] تسجيل صوتي ($duration)',
      isVoice: true,
      voiceDuration: duration,
      mediaUrl: 'voice_placeholder',
      isMe: true,
      time: timeStr,
      status: MessageStatus.read,
      createdAt: now,
    );

    _messagesByConv.putIfAbsent(conversationId, () => []).add(newVoiceMsg);

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('messages').insert({
          'conversation_id': conversationId,
          'sender_username': currentUsername,
          'recipient_username': recipientUsername,
          'content': '[صوت] تسجيل صوتي ($duration)',
          'is_voice': true,
          'voice_duration': duration,
          'created_at': now.toIso8601String(),
        });
      } catch (_) {}
    }

    return true;
  }

  void subscribeToMessages(String conversationId, void Function(MessageModel) onNewMessage) {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      _activeChannel?.unsubscribe();
      _activeChannel = client
          .channel('messages:$conversationId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) {
              final newRecord = payload.newRecord;
              final currentUsername = AuthService.instance.currentUser.username;
              final msg = MessageModel.fromMap(newRecord, currentUsername);
              if (!msg.isMe) {
                onNewMessage(msg);
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  void unsubscribe() {
    _activeChannel?.unsubscribe();
    _activeChannel = null;
  }
}
