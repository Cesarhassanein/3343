import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/chat_settings_service.dart';

class ChatWallpaperScreen extends StatefulWidget {
  const ChatWallpaperScreen({super.key});

  @override
  State<ChatWallpaperScreen> createState() => _ChatWallpaperScreenState();
}

class _ChatWallpaperScreenState extends State<ChatWallpaperScreen> {
  final _service = ChatSettingsService.instance;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (img != null) {
        final bytes = await img.readAsBytes();
        final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await _service.setWallpaper(dataUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("تم تطبيق خلفية المعرض بنجاح على كافة المحادثات! 🖼️"),
              backgroundColor: WadiqColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تعذر اختيار الصورة: $e"), backgroundColor: WadiqColors.alert),
        );
      }
    }
  }

  void _resetToDefault() async {
    await _service.setWallpaper(null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تمت إعادة تعيين خلفية المحادثة إلى الوضع الافتراضي."),
          backgroundColor: WadiqColors.primaryAmber,
        ),
      );
    }
  }

  Widget _buildPreviewBox() {
    final wallpaper = _service.wallpaper;
    final theme = _service.activeTheme;

    Decoration decoration;
    if (wallpaper == null) {
      decoration = const BoxDecoration(
        color: Color(0xFF0F1115),
      );
    } else if (wallpaper.startsWith('data:image')) {
      try {
        final comma = wallpaper.indexOf(',');
        final base64Str = comma != -1 ? wallpaper.substring(comma + 1) : wallpaper;
        final bytes = base64Decode(base64Str);
        decoration = BoxDecoration(
          image: DecorationImage(
            image: MemoryImage(bytes),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.35), BlendMode.darken),
          ),
        );
      } catch (_) {
        decoration = const BoxDecoration(color: Color(0xFF0F1115));
      }
    } else {
      // Preset gradient
      final preset = ChatSettingsService.presetWallpapers.firstWhere(
        (p) => p['id'] == wallpaper,
        orElse: () => ChatSettingsService.presetWallpapers[0],
      );
      final colors = preset['colors']!.split(',').map((c) => Color(int.parse(c.trim()))).toList();
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      );
    }

    return Container(
      height: 220,
      width: double.infinity,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Simulated conversation bubbles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.receiverBubbleColor.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      "معاينة الخلفية مع فقاعة الرسالة المستلمة",
                      style: TextStyle(fontSize: _service.fontSize - 1, color: theme.receiverTextColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.senderBubbleColor.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      "ممتازة جداً ومريحة للقراءة! ✨",
                      style: TextStyle(fontSize: _service.fontSize - 1, color: theme.senderTextColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("معاينة حية للمحادثة", style: TextStyle(color: Colors.white70, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentWallpaper = _service.wallpaper;

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Text("خلفية المحادثة", style: WadiqTypography.titleLarge),
        actions: [
          if (currentWallpaper != null)
            TextButton.icon(
              onPressed: _resetToDefault,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: WadiqColors.alert),
              label: const Text("إعادة تعيين", style: TextStyle(color: WadiqColors.alert, fontSize: 13)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Preview Card
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _buildPreviewBox(),
          ),
          const SizedBox(height: 20),

          // Action 1: Gallery picker button
          Container(
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: WadiqColors.primaryAmber, size: 22),
              ),
              title: Text("اختيار صورة من المعرض", style: WadiqTypography.bodyLarge),
              subtitle: Text("اختر أي صورة أو تصميم مفضل من هاتفك أو حاسوبك", style: WadiqTypography.caption),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              onTap: _pickFromGallery,
            ),
          ),
          const SizedBox(height: 20),

          // Action 2: Presets Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "الخلفيات والتدرجات الجاهزة",
                style: WadiqTypography.titleMedium.copyWith(color: WadiqColors.primaryAmber),
              ),
              if (currentWallpaper == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text("الافتراضي مفعل", style: TextStyle(color: Colors.white70, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Presets Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ChatSettingsService.presetWallpapers.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, i) {
              final preset = ChatSettingsService.presetWallpapers[i];
              final isSelected = currentWallpaper == preset['id'];
              final colors = preset['colors']!.split(',').map((c) => Color(int.parse(c.trim()))).toList();

              return InkWell(
                onTap: () async {
                  await _service.setWallpaper(preset['id']);
                  if (context.mounted) setState(() {});
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    border: Border.all(
                      color: isSelected ? WadiqColors.primaryAmber : WadiqColors.surfaceBorder,
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: WadiqColors.primaryAmber.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            preset['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (isSelected)
                            const CircleAvatar(
                              radius: 10,
                              backgroundColor: WadiqColors.primaryAmber,
                              child: Icon(Icons.check, size: 14, color: Colors.black),
                            ),
                        ],
                      ),
                      Text(
                        preset['desc']!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Action 3: Reset Default Option Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: WadiqColors.surfaceBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.restart_alt_rounded, color: Colors.white70),
            label: const Text("استعادة الخلفية الأصلية الافتراضية", style: TextStyle(color: Colors.white)),
            onPressed: _resetToDefault,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
