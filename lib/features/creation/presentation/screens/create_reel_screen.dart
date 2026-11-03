import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/wadiq_button.dart';
import '../../../../core/services/reel_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/wadiq_api_service.dart';

class CreateReelScreen extends StatefulWidget {
  final String? initialSoundTitle;
  const CreateReelScreen({super.key, this.initialSoundTitle});

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  final TextEditingController _captionController = TextEditingController();
  late final TextEditingController _soundController;
  final TextEditingController _videoUrlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedVideo;
  String? _selectedVideoName;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _soundController = TextEditingController(
      text: widget.initialSoundTitle?.isNotEmpty == true
          ? widget.initialSoundTitle!
          : "الصوت الأصلي • أكاديمي",
    );
  }

  final List<Map<String, String>> _sampleAcademicVideos = [
    {
      'title': 'شرح تجربة فيزياء الحركة الموجية',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    },
    {
      'title': 'تصور هندسي لحساب المثلثات',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    },
    {
      'title': 'مقدمة في الذكاء الاصطناعي والروبوتات',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    },
  ];

  @override
  void dispose() {
    _captionController.dispose();
    _soundController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      XFile? video;
      try {
        video = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5),
        );
      } catch (_) {
        video = await _picker.pickMedia();
      }

      final selected = video;
      if (selected != null) {
        setState(() {
          _selectedVideo = selected;
          _selectedVideoName = selected.name.isNotEmpty ? selected.name : 'فيديو من المعرض.mp4';
          _videoUrlController.text = selected.path;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم اختيار الفيديو بنجاح: $_selectedVideoName"),
            backgroundColor: WadiqColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تعذر فتح ملف الفيديو من المتصفح: $e. يمكنك اختيار أحد النماذج التعليمية أدناه."),
          backgroundColor: WadiqColors.alert,
        ),
      );
    }
  }

  void _publishReel() async {
    final effectiveUrl = _videoUrlController.text.trim();

    if (_selectedVideo == null && effectiveUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى اختيار مقطع فيديو من المعرض أو اختيار نموذج فيديو تعليمي أولاً"),
          backgroundColor: WadiqColors.alert,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    String videoUrl;

    // If user picked a local video, upload it via backend API → Telegram
    if (_selectedVideo != null && _selectedVideo!.path.isNotEmpty && !_selectedVideo!.path.startsWith('http')) {
      try {
        final bytes = await _selectedVideo!.readAsBytes();
        final user = AuthService.instance.currentUser;
        final uploadedUrl = await WadiqApiService.instance.uploadVideoBytes(
          bytes,
          fileName: _selectedVideoName ?? 'reel_${DateTime.now().millisecondsSinceEpoch}.mp4',
          ownerUsername: user.username,
        );
        if (uploadedUrl != null) {
          videoUrl = uploadedUrl;
        } else {
          if (mounted) {
            setState(() => _isPublishing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("تعذر رفع الفيديو إلى السيرفر. يرجى التحقق من الاتصال بالإنترنت والمحاولة مجدداً."),
                backgroundColor: WadiqColors.alert,
              ),
            );
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isPublishing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("خطأ أثناء تجهيز الفيديو: $e"),
              backgroundColor: WadiqColors.alert,
            ),
          );
        }
        return;
      }
    } else {
      // External URL (sample video or pasted URL)
      videoUrl = effectiveUrl.isNotEmpty
          ? effectiveUrl
          : 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
    }

    await ReelService.instance.createReel(
      videoUrl: videoUrl,
      caption: _captionController.text.trim().isNotEmpty ? _captionController.text.trim() : "مقطع ريلز تعليمي جديد",
      soundTitle: _soundController.text.trim().isNotEmpty ? _soundController.text.trim() : "الصوت الأصلي",
    );

    if (!mounted) return;
    setState(() => _isPublishing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم نشر مقطع الريلز بنجاح! يظهر الآن في قسم الريلز العام 🎬"),
        backgroundColor: WadiqColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Text("نشر مقطع ريلز جديد", style: WadiqTypography.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: WadiqButton(
              text: "نشر الريل",
              isLoading: _isPublishing,
              onPressed: _publishReel,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isPublishing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: WadiqColors.primaryAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WadiqColors.primaryAmber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: WadiqColors.primaryAmber),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "جاري رفع مقطع الفيديو عبر السيرفر بأقصى سرعة...",
                        style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Video picker box
            InkWell(
              onTap: _pickVideoFromGallery,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: WadiqColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedVideo != null || _videoUrlController.text.isNotEmpty
                        ? WadiqColors.primaryAmber
                        : WadiqColors.surfaceBorder,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _selectedVideo != null || _videoUrlController.text.isNotEmpty
                            ? Icons.check_circle_rounded
                            : Icons.video_library_rounded,
                        size: 40,
                        color: _selectedVideo != null || _videoUrlController.text.isNotEmpty
                            ? WadiqColors.success
                            : WadiqColors.primaryAmber,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _selectedVideoName ?? (_videoUrlController.text.isNotEmpty ? "تم تجهيز الفيديو للنشر ✓" : "اضغط لاختيار فيديو من المعرض"),
                      style: WadiqTypography.titleMedium.copyWith(
                        color: _selectedVideo != null || _videoUrlController.text.isNotEmpty
                            ? Colors.white
                            : WadiqColors.primaryAmber,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "يدعم صيغ MP4, WebM, MOV من جهازك",
                      style: WadiqTypography.caption,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Ready Educational Videos
            Text("أو اختر مقطعاً تعليمياً جاهزاً للتجربة السريعة:", style: WadiqTypography.caption.copyWith(color: Colors.white70)),
            const SizedBox(height: 8),
            ...List.generate(_sampleAcademicVideos.length, (idx) {
              final v = _sampleAcademicVideos[idx];
              final isChosen = _videoUrlController.text == v['url'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedVideo = null;
                      _selectedVideoName = v['title'];
                      _videoUrlController.text = v['url']!;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isChosen ? WadiqColors.primaryAmber.withValues(alpha: 0.15) : WadiqColors.cardSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isChosen ? WadiqColors.primaryAmber : WadiqColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isChosen ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 16,
                          color: isChosen ? WadiqColors.primaryAmber : WadiqColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            v['title']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isChosen ? Colors.white : WadiqColors.textSecondary,
                              fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Caption Field
            Text("وصف المقطع (Caption):", style: WadiqTypography.titleMedium.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: WadiqColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WadiqColors.surfaceBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _captionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "اكتب شرحاً أو ملخصاً أو سؤالاً حول هذا المقطع...",
                  hintStyle: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sound Title Field
            Text("اسم الصوت أو المحاضرة:", style: WadiqTypography.titleMedium.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: WadiqColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WadiqColors.surfaceBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _soundController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  icon: const Icon(Icons.music_note_rounded, color: WadiqColors.primaryAmber, size: 20),
                  hintText: "اسم الصوت (افتراضي: الصوت الأصلي)",
                  hintStyle: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
