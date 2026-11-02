import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/wadiq_button.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/wadiq_api_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String? initialContent;

  const CreatePostScreen({super.key, this.initialContent});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late final TextEditingController _contentController;
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [];
  final ImagePicker _picker = ImagePicker();

  String? _selectedImageBase64;
  bool _isPollEnabled = false;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _pollOptionControllers.add(TextEditingController(text: "نعم / أوافق"));
    _pollOptionControllers.add(TextEditingController(text: "لا / أعارض"));
  }

  @override
  void dispose() {
    _contentController.dispose();
    _imageUrlController.dispose();
    _pollQuestionController.dispose();
    for (var c in _pollOptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      XFile? img;
      try {
        img = await _picker.pickImage(source: ImageSource.gallery);
      } catch (_) {
        img = await _picker.pickMedia();
      }
      if (img != null) {
        final bytes = await img.readAsBytes();
        final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _selectedImageBase64 = dataUrl;
          _imageUrlController.text = dataUrl;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر اختيار الصورة: $e'), backgroundColor: WadiqColors.alert),
      );
    }
  }

  void _addPollOption() {
    if (_pollOptionControllers.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الحد الأقصى لخيارات الاستطلاع هو 4")),
      );
      return;
    }
    setState(() {
      _pollOptionControllers.add(TextEditingController());
    });
  }

  void _publishPost() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى كتابة نص المنشور أولاً"), backgroundColor: WadiqColors.alert),
      );
      return;
    }

    setState(() => _isPublishing = true);

    List<String> mediaUrls = [];

    // Upload image via backend API → Telegram
    if (_selectedImageBase64 != null && _selectedImageBase64!.isNotEmpty) {
      final user = AuthService.instance.currentUser;
      final uploadedUrl = await WadiqApiService.instance.uploadBase64Image(
        _selectedImageBase64!,
        fileName: 'post_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ownerUsername: user.username,
      );
      if (uploadedUrl != null) {
        mediaUrls.add(uploadedUrl);
      } else {
        // Fallback: store Base64 directly if API upload fails
        mediaUrls.add(_selectedImageBase64!);
      }
    } else if (_imageUrlController.text.trim().isNotEmpty) {
      mediaUrls.add(_imageUrlController.text.trim());
    }

    String? pollQuestion;
    List<String> pollOptions = [];
    if (_isPollEnabled) {
      pollQuestion = _pollQuestionController.text.trim().isNotEmpty
          ? _pollQuestionController.text.trim()
          : "استطلاع رأي";
      pollOptions = _pollOptionControllers
          .map((c) => c.text.trim())
          .where((opt) => opt.isNotEmpty)
          .toList();
    }

    final success = await PostService.instance.createPost(
      content: text,
      mediaUrls: mediaUrls,
      pollQuestion: _isPollEnabled && pollOptions.length >= 2 ? pollQuestion : null,
      pollOptions: _isPollEnabled && pollOptions.length >= 2 ? pollOptions : [],
    );

    if (!mounted) return;
    setState(() => _isPublishing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم نشر منشورك بنجاح! سيظل نشطاً لمدة 10 أيام ⏳"),
          backgroundColor: WadiqColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("حدث خطأ أثناء النشر"), backgroundColor: WadiqColors.alert),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        title: Text("منشور أكاديمي جديد", style: WadiqTypography.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: WadiqButton(
              text: "نشر",
              isLoading: _isPublishing,
              onPressed: _publishPost,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 10-day retention notice banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: WadiqColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WadiqColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: WadiqColors.primaryAmber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "سيظهر منشورك لكافة زملائك لمدة 10 أيام مع إمكانية التجديد قبل الانتهاء.",
                      style: WadiqTypography.caption.copyWith(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main text area
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WadiqColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WadiqColors.surfaceBorder),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                decoration: InputDecoration(
                  hintText: "شارك أفكارك الأكاديمية أو سؤالك أو مستجداتك الدراسية هنا...",
                  hintStyle: WadiqTypography.bodyMedium.copyWith(color: WadiqColors.textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image preview
            if (_selectedImageBase64 != null) ...[
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: WadiqColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: WadiqColors.primaryAmber),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        _selectedImageBase64!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.image, size: 48, color: WadiqColors.primaryAmber),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                        onPressed: () => setState(() {
                          _selectedImageBase64 = null;
                          _imageUrlController.clear();
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Add Attachments Bar
            Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.image_outlined, color: WadiqColors.primaryAmber, size: 18),
                  label: Text(_selectedImageBase64 != null ? "تغيير الصورة" : "إرفاق صورة"),
                  backgroundColor: WadiqColors.cardSurface,
                  side: const BorderSide(color: WadiqColors.surfaceBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onPressed: _pickImage,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: Icon(
                    _isPollEnabled ? Icons.check_circle : Icons.poll_outlined,
                    color: _isPollEnabled ? WadiqColors.success : WadiqColors.primaryAmber,
                    size: 18,
                  ),
                  label: Text(_isPollEnabled ? "إلغاء الاستطلاع" : "إضافة استطلاع رأي"),
                  backgroundColor: WadiqColors.cardSurface,
                  side: const BorderSide(color: WadiqColors.surfaceBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onPressed: () => setState(() => _isPollEnabled = !_isPollEnabled),
                ),
              ],
            ),

            // Poll Section
            if (_isPollEnabled) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WadiqColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: WadiqColors.primaryAmber.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("سؤال استطلاع الرأي:", style: WadiqTypography.titleMedium.copyWith(fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: WadiqColors.elevatedSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _pollQuestionController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: "اكتب سؤال الاستطلاع...",
                          hintStyle: TextStyle(color: WadiqColors.textMuted),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text("خيارات التصويت:", style: WadiqTypography.titleMedium.copyWith(fontSize: 14)),
                    const SizedBox(height: 8),
                    ...List.generate(_pollOptionControllers.length, (idx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: WadiqColors.elevatedSurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextField(
                                  controller: _pollOptionControllers[idx],
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: "الخيار ${idx + 1}",
                                    hintStyle: const TextStyle(color: WadiqColors.textMuted),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            if (_pollOptionControllers.length > 2)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: WadiqColors.alert, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _pollOptionControllers.removeAt(idx);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    if (_pollOptionControllers.length < 4)
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16, color: WadiqColors.primaryAmber),
                        label: const Text("إضافة خيار آخر", style: TextStyle(color: WadiqColors.primaryAmber, fontSize: 13)),
                        onPressed: _addPollOption,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
