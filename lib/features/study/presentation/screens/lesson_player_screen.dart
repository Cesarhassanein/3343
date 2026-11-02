import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/wadiq_button.dart';

class LessonPlayerScreen extends StatefulWidget {
  final String courseTitle;
  final String lessonTitle;
  final String lessonDuration;

  const LessonPlayerScreen({
    super.key,
    required this.courseTitle,
    required this.lessonTitle,
    required this.lessonDuration,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  bool _isPlaying = true;
  double _playbackPosition = 0.35;
  String _speed = "1.0x";
  bool _isBookmarked = false;
  bool _isCompleted = false;

  final List<String> _speeds = ["0.75x", "1.0x", "1.25x", "1.5x", "2.0x"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        title: Text(
          widget.courseTitle,
          style: WadiqTypography.titleMedium.copyWith(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? WadiqColors.primaryAmber : Colors.white,
            ),
            onPressed: () {
              setState(() => _isBookmarked = !_isBookmarked);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isBookmarked ? "تم حفظ الدرس في المفضلة" : "تمت إزالة الحفظ",
                    style: WadiqTypography.bodyMedium,
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Simulated Video Player Frame
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Video Background / Poster
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          WadiqColors.primaryAmber.withValues(alpha: 0.15),
                          Colors.black,
                        ],
                        radius: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.code,
                            size: 48,
                            color: WadiqColors.primaryAmber.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.lessonTitle,
                            style: WadiqTypography.caption.copyWith(
                              color: WadiqColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center Play/Pause button
                  GestureDetector(
                    onTap: () => setState(() => _isPlaying = !_isPlaying),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: WadiqColors.primaryAmber.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  // Bottom Controls Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                              activeTrackColor: WadiqColors.primaryAmber,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: WadiqColors.primaryAmber,
                            ),
                            child: Slider(
                              value: _playbackPosition,
                              onChanged: (val) {
                                setState(() => _playbackPosition = val);
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "04:15 / ${widget.lessonDuration}",
                                style: WadiqTypography.caption.copyWith(color: Colors.white70),
                              ),
                              Row(
                                children: [
                                  // Speed selector
                                  PopupMenuButton<String>(
                                    initialValue: _speed,
                                    onSelected: (val) => setState(() => _speed = val),
                                    itemBuilder: (context) => _speeds
                                        .map((s) => PopupMenuItem(value: s, child: Text(s)))
                                        .toList(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _speed,
                                        style: WadiqTypography.caption.copyWith(
                                          color: WadiqColors.primaryAmber,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lesson Details & Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lessonTitle,
                            style: WadiqTypography.titleLarge.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "المدة: ${widget.lessonDuration} • جودة عالية 1080p",
                            style: WadiqTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                        color: _isCompleted ? WadiqColors.success : WadiqColors.textMuted,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() => _isCompleted = !_isCompleted);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isCompleted ? "تم تحديد الدرس كمكتمل!" : "تم إلغاء التحديد",
                              style: WadiqTypography.bodyMedium,
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: WadiqColors.divider),
                const SizedBox(height: 16),

                Text(
                  "ملخص الدرس وملاحظات المدرس",
                  style: WadiqTypography.titleMedium.copyWith(color: WadiqColors.primaryAmber),
                ),
                const SizedBox(height: 8),
                Text(
                  "في هذا الدرس، نقوم بفحص البنية الهيكلية المعتمدة في منصة ودق، وكيفية تنظيم الطبقات البرمجية لتحقيق أعلى كفاءة وفصل المهام (Separation of Concerns).\n\nسنركز على ربط الـ Realtime Engine مع واجهات المستخدم بسلاسة، مع الحفاظ على الأداء العالي ومعدل الإطارات 60fps.",
                  style: WadiqTypography.bodyMedium.copyWith(
                    color: WadiqColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),

                // Code Snippet Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: WadiqColors.darkCharcoal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WadiqColors.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "supabase_stream.dart",
                            style: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted),
                          ),
                          const Icon(Icons.copy, size: 14, color: WadiqColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "final stream = supabase\n  .from('messages')\n  .stream(primaryKey: ['id'])\n  .eq('conversation_id', convId);\n\nstream.listen((data) => updateUI(data));",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF80CBC4),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Resources & Downloads
                Text(
                  "المرفقات والمصادر",
                  style: WadiqTypography.titleMedium,
                ),
                const SizedBox(height: 10),
                _buildAttachmentCard(
                  title: "شرائح الدرس والرسومات البيانية (PDF)",
                  size: "4.2 MB",
                  icon: Icons.picture_as_pdf_outlined,
                ),
                const SizedBox(height: 8),
                _buildAttachmentCard(
                  title: "الكود المصدري للمشروع التوضيحي (ZIP)",
                  size: "1.8 MB",
                  icon: Icons.folder_zip_outlined,
                ),
              ],
            ),
          ),

          // Bottom Navigation (Previous / Next)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: WadiqColors.cardSurface,
              border: Border(top: BorderSide(color: WadiqColors.surfaceBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_forward_ios, size: 14),
                    label: const Text("الدرس السابق"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WadiqColors.textSecondary,
                      side: const BorderSide(color: WadiqColors.surfaceBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WadiqButton(
                    text: "الدرس التالي",
                    icon: Icons.arrow_back_ios,
                    height: 48,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("جاري تحميل الدرس التالي..."),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard({
    required String title,
    required String size,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WadiqColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WadiqColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: WadiqColors.primaryAmber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WadiqTypography.bodyMedium.copyWith(fontSize: 13)),
                Text(size, style: WadiqTypography.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: WadiqColors.primaryAmber),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("بدأ تحميل $title"),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
