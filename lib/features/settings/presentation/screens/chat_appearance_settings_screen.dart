import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/chat_settings_service.dart';
import 'chat_wallpaper_screen.dart';
import 'chat_color_theme_screen.dart';

class ChatAppearanceSettingsScreen extends StatefulWidget {
  const ChatAppearanceSettingsScreen({super.key});

  @override
  State<ChatAppearanceSettingsScreen> createState() => _ChatAppearanceSettingsScreenState();
}

class _ChatAppearanceSettingsScreenState extends State<ChatAppearanceSettingsScreen> {
  final _service = ChatSettingsService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = _service.activeTheme;
    final double radius = _service.bubbleRadius;
    final double fontSize = _service.fontSize;

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Text("تخصيص المحادثات", style: WadiqTypography.titleLarge),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Live Interactive Preview Card
          _buildSectionHeader("معاينة مظهر المحادثة المباشر"),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF111317),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: Column(
              children: [
                // Received bubble
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 270),
                    decoration: BoxDecoration(
                      color: theme.receiverBubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(radius),
                        topRight: Radius.circular(radius),
                        bottomLeft: Radius.circular(radius),
                        bottomRight: const Radius.circular(3),
                      ),
                      border: Border.all(color: WadiqColors.surfaceBorder, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "أحمد • زميل دراسة",
                          style: TextStyle(
                            fontSize: (fontSize - 3).clamp(10.0, 14.0),
                            color: theme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "مرحباً! هل اطلعت على ملخص المحاضرة الثالثة؟",
                          style: TextStyle(
                            fontSize: fontSize,
                            color: theme.receiverTextColor,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            "10:45 ص",
                            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sent bubble
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 270),
                    decoration: BoxDecoration(
                      color: theme.senderBubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(radius),
                        topRight: Radius.circular(radius),
                        bottomLeft: const Radius.circular(3),
                        bottomRight: Radius.circular(radius),
                      ),
                      border: Border.all(color: theme.borderColor.withValues(alpha: 0.5), width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "نعم، الملخص ممتاز جداً وجاهز للمراجعة 🎓✨",
                          style: TextStyle(
                            fontSize: fontSize,
                            color: theme.senderTextColor,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "10:46 ص",
                              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.done_all_rounded, size: 14, color: theme.accentColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Chat Font Size Slider
          _buildSectionHeader("حجم خط الرسائل"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("حجم الخط الخاص بالمحادثة:", style: WadiqTypography.bodyMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${fontSize.toStringAsFixed(0)} نقطة",
                        style: const TextStyle(
                          color: WadiqColors.primaryAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("A", style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: fontSize,
                        min: 12.0,
                        max: 24.0,
                        divisions: 12,
                        activeColor: WadiqColors.primaryAmber,
                        inactiveColor: Colors.white24,
                        label: fontSize.toStringAsFixed(0),
                        onChanged: (val) => _service.setFontSize(val),
                      ),
                    ),
                    const Text("A", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  "يتحكم هذا الخيار بحجم الخط داخل الرسائل والمحادثات فقط دون التأثير على باقي واجهات المنصة.",
                  style: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Chat Bubble Corner Radius Slider
          _buildSectionHeader("زاوية الرسالة (انحناء الفقاعة)"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("درجة استدارة زوايا الرسائل:", style: WadiqTypography.bodyMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${radius.toStringAsFixed(0)} px",
                        style: const TextStyle(
                          color: WadiqColors.primaryAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.crop_square_rounded, color: Colors.white60, size: 18),
                    Expanded(
                      child: Slider(
                        value: radius,
                        min: 4.0,
                        max: 28.0,
                        divisions: 24,
                        activeColor: WadiqColors.primaryAmber,
                        inactiveColor: Colors.white24,
                        label: "${radius.toStringAsFixed(0)} px",
                        onChanged: (val) => _service.setBubbleRadius(val),
                      ),
                    ),
                    const Icon(Icons.circle_outlined, color: Colors.white, size: 18),
                  ],
                ),
                Text(
                  "تحديد شكل حواف وزوايا فقاعة الرسالة بين المربعة والمنحنية الدائرية.",
                  style: WadiqTypography.caption.copyWith(color: WadiqColors.textMuted, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Wallpaper & Color Themes Navigation (Full Screen Routes)
          _buildSectionHeader("الخلفيات والألوان"),
          Container(
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wallpaper_rounded, color: WadiqColors.primaryAmber, size: 20),
                  ),
                  title: Text("تغيير خلفية المحادثة", style: WadiqTypography.bodyLarge),
                  subtitle: Text(
                    _service.wallpaper == null ? "الخلفية الافتراضية الداكنة" : "خلفية مخصصة مفعلة",
                    style: WadiqTypography.caption,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatWallpaperScreen()),
                    );
                  },
                ),
                const Divider(color: WadiqColors.surfaceBorder, height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.palette_rounded, color: theme.accentColor, size: 20),
                  ),
                  title: Text("تغيير لون الرسائل والسمة", style: WadiqTypography.bodyLarge),
                  subtitle: Text(theme.name, style: WadiqTypography.caption),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatColorThemeScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. Chat List Display Mode (3 Options)
          _buildSectionHeader("عرض قائمة المحادثات الرئيسية"),
          Container(
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: Column(
              children: [
                RadioListTile<int>(
                  value: 0,
                  groupValue: _service.listPreviewMode,
                  activeColor: WadiqColors.primaryAmber,
                  title: Text("اسم الحساب فقط بدون رسائل", style: WadiqTypography.bodyMedium),
                  subtitle: Text("عرض مضغوط ومبسط يظهر أسماء المحادثات فقط للخصوصية التامة", style: WadiqTypography.caption),
                  onChanged: (val) {
                    if (val != null) _service.setListPreviewMode(val);
                  },
                ),
                const Divider(color: WadiqColors.surfaceBorder, height: 1),
                RadioListTile<int>(
                  value: 1,
                  groupValue: _service.listPreviewMode,
                  activeColor: WadiqColors.primaryAmber,
                  title: Text("اسم الحساب مع رسالة واحدة (افتراضي)", style: WadiqTypography.bodyMedium),
                  subtitle: Text("عرض متوازن يوضح آخر رسالة مستلمة في سطر واحد", style: WadiqTypography.caption),
                  onChanged: (val) {
                    if (val != null) _service.setListPreviewMode(val);
                  },
                ),
                const Divider(color: WadiqColors.surfaceBorder, height: 1),
                RadioListTile<int>(
                  value: 2,
                  groupValue: _service.listPreviewMode,
                  activeColor: WadiqColors.primaryAmber,
                  title: Text("اسم الحساب مع رسالتين", style: WadiqTypography.bodyMedium),
                  subtitle: Text("عرض مفصل يتيح قراءة جزء أكبر من سياق المحادثة في سطرين", style: WadiqTypography.caption),
                  onChanged: (val) {
                    if (val != null) _service.setListPreviewMode(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: WadiqTypography.caption.copyWith(
          color: WadiqColors.primaryAmber,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
