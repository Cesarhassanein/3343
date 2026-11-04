import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/chat_settings_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/wadiq_api_service.dart';
import 'channel_info_screen.dart';
import 'call_screen.dart';
import '../../../../core/widgets/wadiq_avatar.dart';

class ChatRoomScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isChannel;
  final String avatarChar;
  final String? avatarUrl;
  final String conversationId;
  final String? recipientUsername;

  const ChatRoomScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.isChannel = false,
    required this.avatarChar,
    this.avatarUrl,
    this.conversationId = 'conv_1',
    this.recipientUsername,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  String get _effectiveRecipientUsername {
    if (widget.recipientUsername != null && widget.recipientUsername!.isNotEmpty) {
      return widget.recipientUsername!.replaceAll('@', '').trim().toLowerCase();
    }
    if (widget.conversationId.startsWith('direct_')) {
      final parts = widget.conversationId.replaceFirst('direct_', '').split('_');
      final myUsername = AuthService.instance.currentUser.username.replaceAll('@', '').trim().toLowerCase();
      if (parts.length >= 2) {
        if (parts[0] == myUsername) return parts[1];
        if (parts[1] == myUsername) return parts[0];
        return parts[0];
      }
    }
    return widget.title.replaceAll('@', '').trim().toLowerCase();
  }

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _searchQuery;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    ChatSettingsService.instance.addListener(_onSettingsChanged);
    _loadMessages();
    _subscribeToLiveMessages();
    _textController.addListener(() => setState(() {}));
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ChatSettingsService.instance.removeListener(_onSettingsChanged);
    ChatService.instance.unsubscribe();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ChatService.instance.fetchMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _subscribeToLiveMessages() {
    ChatService.instance.subscribeToMessages(widget.conversationId, (newMsg) {
      if (!mounted) return;
      setState(() {
        _messages.add(newMsg);
      });
      _scrollToBottom();
    });
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);

    final sent = await ChatService.instance.sendMessage(
      conversationId: widget.conversationId,
      content: text,
      recipientUsername: _effectiveRecipientUsername,
    );

    if (!mounted) return;
    setState(() => _isSending = false);
    if (!sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إرسال الرسالة.'), backgroundColor: WadiqColors.alert),
      );
      return;
    }
    _textController.clear();
    await _loadMessages();
  }

  Future<void> _pickAndSendImage() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img != null) {
        setState(() => _isSending = true);
        final bytes = await img.readAsBytes();
        final user = AuthService.instance.currentUser;

        // Upload via backend API → Telegram
        String mediaUrl;
        final uploadedUrl = await WadiqApiService.instance.uploadImageBytes(
          bytes,
          fileName: 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ownerUsername: user.username,
        );
        if (uploadedUrl != null) {
          mediaUrl = uploadedUrl;
        } else {
          // Fallback to Base64 data URL if API upload fails
          final base64String = base64Encode(bytes);
          mediaUrl = 'data:image/jpeg;base64,$base64String';
        }

        await ChatService.instance.sendMessage(
          conversationId: widget.conversationId,
          content: '📷 صورة مرفقة',
          mediaUrl: mediaUrl,
          mediaType: 'image',
          recipientUsername: _effectiveRecipientUsername,
        );
        if (!mounted) return;
        setState(() => _isSending = false);
        await _loadMessages();
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search, color: WadiqColors.primaryAmber),
              title: Text("البحث في رسائل المحادثة", style: WadiqTypography.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _isSearching = true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined, color: Colors.white70),
              title: Text("كتم التنبيهات", style: WadiqTypography.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                ChatService.instance.toggleMute(widget.conversationId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم تحديث حالة كتم التنبيهات")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white70),
              title: Text("معلومات ${widget.isChannel ? 'القناة' : 'المحادثة'}", style: WadiqTypography.bodyLarge),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChannelInfoScreen(
                      title: widget.title,
                      subtitle: widget.subtitle,
                      isChannel: widget.isChannel,
                      avatarChar: widget.avatarChar,
                      targetId: widget.conversationId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.orangeAccent),
              title: Text("مسح سجل الرسائل", style: WadiqTypography.bodyLarge.copyWith(color: Colors.orangeAccent)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  ChatService.instance.clearHistory(widget.conversationId);
                  _messages.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم مسح سجل الرسائل")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaImage(String url, {double? height, BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:image')) {
      try {
        final comma = url.indexOf(',');
        final base64Data = comma != -1 ? url.substring(comma + 1) : url;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
          ),
        );
      } catch (_) {}
    }
    return Image.network(
      url,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
      ),
    );
  }

  void _openImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                color: WadiqColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WadiqColors.surfaceBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildMediaImage(imagePath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUsername = AuthService.instance.currentUser.username;
    final conv = ChatService.instance.getConversationById(widget.conversationId);
    final bool canPost = conv == null || conv.canUserPost(myUsername);
    final settings = ChatSettingsService.instance;
    final wallpaper = settings.wallpaper;

    Decoration backgroundDecoration;
    if (wallpaper == null) {
      backgroundDecoration = const BoxDecoration(color: WadiqColors.obsidianBlack);
    } else if (wallpaper.startsWith('data:image')) {
      try {
        final comma = wallpaper.indexOf(',');
        final base64Str = comma != -1 ? wallpaper.substring(comma + 1) : wallpaper;
        final bytes = base64Decode(base64Str);
        backgroundDecoration = BoxDecoration(
          image: DecorationImage(
            image: MemoryImage(bytes),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.35), BlendMode.darken),
          ),
        );
      } catch (_) {
        backgroundDecoration = const BoxDecoration(color: WadiqColors.obsidianBlack);
      }
    } else {
      final preset = ChatSettingsService.presetWallpapers.firstWhere(
        (p) => p['id'] == wallpaper,
        orElse: () => ChatSettingsService.presetWallpapers[0],
      );
      final colors = preset['colors']!.split(',').map((c) => Color(int.parse(c.trim()))).toList();
      backgroundDecoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      );
    }

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        titleSpacing: 0,
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "ابحث في الرسائل...",
                  hintStyle: const TextStyle(color: WadiqColors.textMuted),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                    onPressed: () => setState(() {
                      _isSearching = false;
                      _searchQuery = null;
                    }),
                  ),
                ),
                onChanged: (q) => setState(() => _searchQuery = q.trim()),
              )
            : InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChannelInfoScreen(
                        title: widget.title,
                        subtitle: widget.subtitle,
                        isChannel: widget.isChannel,
                        avatarChar: widget.avatarChar,
                        targetId: widget.conversationId,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    WadiqAvatar(
                      avatarUrl: widget.avatarUrl,
                      fallbackInitial: widget.avatarChar,
                      radius: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: WadiqTypography.titleMedium.copyWith(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.subtitle,
                            style: WadiqTypography.caption.copyWith(
                              color: WadiqColors.success,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        actions: [
          if (!widget.isChannel && !_isSearching) ...[
            IconButton(
              tooltip: "مكالمة صوتية",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CallScreen(
                      targetName: widget.title,
                      targetUsername: _effectiveRecipientUsername,
                      avatarChar: widget.avatarChar,
                      isVideo: false,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.call_outlined, size: 22, color: WadiqColors.primaryAmber),
            ),
            IconButton(
              tooltip: "مكالمة فيديو",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CallScreen(
                      targetName: widget.title,
                      targetUsername: _effectiveRecipientUsername,
                      avatarChar: widget.avatarChar,
                      isVideo: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.videocam_outlined, size: 24, color: WadiqColors.primaryAmber),
            ),
          ],
          IconButton(
            tooltip: "خيارات",
            onPressed: _showMoreMenu,
            icon: const Icon(Icons.more_vert, size: 22),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: backgroundDecoration,
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: WadiqColors.primaryAmber))
                  : _messages.isEmpty
                      ? Center(
                          child: Text(
                            widget.isChannel
                                ? "هذه القناة جديدة. لم يتم نشر أي رسائل أو ملازم بعد."
                                : "لا توجد رسائل سابقة. ابدأ المحادثة الآن!",
                            style: WadiqTypography.caption.copyWith(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          itemCount: _filteredMessages.length,
                          itemBuilder: (context, index) {
                            final msg = _filteredMessages[index];
                            return _buildMessageItem(msg);
                          },
                        ),
            ),

            // Composer or Channel restriction banner
            if (canPost)
              _buildComposer()
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: WadiqColors.cardSurface,
                child: Center(
                  child: Text(
                    "القناة مخصصة للبث من قبل المالك فقط",
                    style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<MessageModel> get _filteredMessages {
    if (_searchQuery == null || _searchQuery!.isEmpty) return _messages;
    return _messages.where((m) => m.content.toLowerCase().contains(_searchQuery!.toLowerCase())).toList();
  }

  Widget _buildMessageItem(MessageModel msg) {
    final bool isMe = msg.isMe;
    final settings = ChatSettingsService.instance;
    final theme = settings.activeTheme;
    final double radius = settings.bubbleRadius;
    final double fontSize = settings.fontSize;

    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? theme.senderBubbleColor : theme.receiverBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
            bottomLeft: Radius.circular(isMe ? 3 : radius),
            bottomRight: Radius.circular(isMe ? radius : 3),
          ),
          border: Border.all(
            color: isMe ? theme.borderColor.withValues(alpha: 0.6) : WadiqColors.surfaceBorder,
            width: isMe ? 1.0 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe && (widget.isChannel || (conv?.isGroup == true)))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "@${msg.senderUsername}",
                  style: TextStyle(
                    fontSize: (fontSize - 4).clamp(10.0, 13.0),
                    color: theme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Image attachment preview
            if (msg.mediaType == 'image' && msg.mediaUrl != null)
              GestureDetector(
                onTap: () => _openImageDialog(msg.mediaUrl!),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMediaImage(msg.mediaUrl!, height: 160, fit: BoxFit.cover),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 14),
                              SizedBox(width: 2),
                              Text("تكبير", style: TextStyle(color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Text(
              msg.content,
              style: TextStyle(
                fontSize: fontSize,
                color: isMe ? theme.senderTextColor : theme.receiverTextColor,
                height: 1.38,
              ),
            ),
            const SizedBox(height: 4),

            // Time and delivery ticks
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  msg.time,
                  style: WadiqTypography.caption.copyWith(fontSize: 10, color: Colors.white38),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusTick(msg.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  ConversationSummary? get conv => ChatService.instance.getConversationById(widget.conversationId);

  Widget _buildStatusTick(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
      case MessageStatus.sent:
        // إذا لم تصل له الرسالة: صح واحدة بلون أبيض
        return const Icon(Icons.check, size: 13, color: Colors.white70);
      case MessageStatus.delivered:
        // إذا كان عنده إنترنت ووصلت له الرسالة: صح واحدة بلون برتقالي
        return const Icon(Icons.check, size: 13, color: WadiqColors.primaryAmber);
      case MessageStatus.read:
        // إذا وصلت وشاهدها: صحين بلون برتقالي
        return const Icon(Icons.done_all, size: 14, color: WadiqColors.primaryAmber);
    }
  }

  Widget _buildComposer() {
    final bool hasText = _textController.text.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: WadiqColors.darkCharcoal,
        border: Border(top: BorderSide(color: WadiqColors.surfaceBorder, width: 0.8)),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 10,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file_rounded, color: WadiqColors.textSecondary, size: 22),
            onPressed: _pickAndSendImage,
          ),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: WadiqColors.elevatedSurface,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: WadiqColors.surfaceBorder, width: 0.8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "اكتب رسالة مشفرة...",
                  hintStyle: WadiqTypography.caption.copyWith(fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: hasText ? WadiqColors.primaryAmber : WadiqColors.elevatedSurface,
            radius: 20,
            child: IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: hasText ? Colors.black : WadiqColors.textMuted,
                size: 18,
              ),
              onPressed: hasText ? _sendMessage : null,
            ),
          ),
        ],
      ),
    );
  }
}
