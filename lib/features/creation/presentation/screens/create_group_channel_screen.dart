import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/wadiq_button.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/wadiq_api_service.dart';

class CreateGroupOrChannelScreen extends StatefulWidget {
  final bool isChannel;

  const CreateGroupOrChannelScreen({super.key, required this.isChannel});

  @override
  State<CreateGroupOrChannelScreen> createState() => _CreateGroupOrChannelScreenState();
}

class _CreateGroupOrChannelScreenState extends State<CreateGroupOrChannelScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _avatarBase64;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      XFile? img;
      try {
        img = await _picker.pickImage(source: ImageSource.gallery);
      } catch (_) {
        img = await _picker.pickMedia();
      }
      if (img != null) {
        final bytes = await img.readAsBytes();
        setState(() {
          _avatarBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر اختيار الصورة: $e'), backgroundColor: WadiqColors.alert),
      );
    }
  }

  void _create() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.replaceAll('@', '').trim().toLowerCase();
    final desc = _descController.text.trim();

    if (name.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى إدخال الاسم واسم المعرف @"),
          backgroundColor: WadiqColors.alert,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if handle is already taken
      final existingConv = ChatService.instance.getConversationById(username);
      final isTakenUser = await AuthService.instance.isUsernameTaken(username);

      if (existingConv != null || isTakenUser) {
        throw StateError('معرف @$username مستخدم بالفعل. يرجى اختيار معرف آخر.');
      }

      // Upload avatar via backend API → Telegram
      String? finalAvatarUrl = _avatarBase64;
      if (_avatarBase64 != null && _avatarBase64!.startsWith('data:image')) {
        final uploadedUrl = await WadiqApiService.instance.uploadBase64Image(
          _avatarBase64!,
          fileName: '${widget.isChannel ? "channel" : "group"}_${username}_avatar.jpg',
          ownerUsername: AuthService.instance.currentUser.username,
        );
        if (uploadedUrl != null) {
          finalAvatarUrl = uploadedUrl;
        }
      }

      ChatService.instance.createOrOpenConversation(
        name: name,
        username: username,
        isChannel: widget.isChannel,
        isGroup: !widget.isChannel,
        description: desc.isNotEmpty
            ? desc
            : (widget.isChannel ? 'قناة للبث الأكاديمي المباشر' : 'مجموعة دراسية'),
        avatarUrl: finalAvatarUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم إنشاء ${widget.isChannel ? 'القناة' : 'المجموعة'} بنجاح!"),
          backgroundColor: WadiqColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('StateError: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: WadiqColors.alert),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isChannel ? "إنشاء قناة جديدة" : "إنشاء مجموعة جديدة";

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Text(title, style: WadiqTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: InkWell(
              onTap: _pickPhoto,
              borderRadius: BorderRadius.circular(46),
              child: Stack(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: WadiqColors.cardSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _avatarBase64 != null ? WadiqColors.primaryAmber : WadiqColors.surfaceBorder,
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: _avatarBase64 != null
                          ? Image.network(
                              _avatarBase64!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.check_circle_rounded,
                                color: WadiqColors.success,
                                size: 36,
                              ),
                            )
                          : Center(
                              child: Icon(
                                widget.isChannel ? Icons.campaign_rounded : Icons.group_rounded,
                                size: 40,
                                color: WadiqColors.primaryAmber,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: WadiqColors.primaryAmber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_a_photo_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _avatarBase64 != null ? "تم اختيار الصورة ✓" : "اضغط لإضافة صورة",
              style: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted),
            ),
          ),
          const SizedBox(height: 24),

          // Name field
          _buildField(
            controller: _nameController,
            hint: widget.isChannel ? "اسم القناة (مثل: قناة الرياضيات العامة)" : "اسم المجموعة (مثل: قروب مناقشة الفيزياء)",
            icon: widget.isChannel ? Icons.campaign_outlined : Icons.group_outlined,
          ),
          const SizedBox(height: 14),

          // Username handle
          _buildField(
            controller: _usernameController,
            hint: "المعرف الفريد (مثل: math_univ)",
            icon: Icons.alternate_email_rounded,
            prefixText: "@",
          ),
          const SizedBox(height: 14),

          // Description
          Container(
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _descController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.isChannel ? "نبذة عن القناة والقوانين..." : "وصف المجموعة وأهدافها الدراسية...",
                hintStyle: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 28),

          WadiqButton(
            text: widget.isChannel ? "تأكيد وإنشاء القناة" : "تأكيد وإنشاء المجموعة",
            width: double.infinity,
            height: 50,
            isLoading: _isLoading,
            onPressed: _create,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? prefixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: WadiqColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WadiqColors.surfaceBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          icon: Icon(icon, color: WadiqColors.textMuted, size: 20),
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
          hintText: hint,
          hintStyle: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
