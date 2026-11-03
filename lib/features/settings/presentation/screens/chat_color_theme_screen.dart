import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/chat_settings_service.dart';

class ChatColorThemeScreen extends StatefulWidget {
  const ChatColorThemeScreen({super.key});

  @override
  State<ChatColorThemeScreen> createState() => _ChatColorThemeScreenState();
}

class _ChatColorThemeScreenState extends State<ChatColorThemeScreen> {
  final _service = ChatSettingsService.instance;

  @override
  Widget build(BuildContext context) {
    final activeTheme = _service.activeTheme;
    final double radius = _service.bubbleRadius;
    final double fontSize = _service.fontSize;

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Text("ألوان وسمات الرسائل", style: WadiqTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live Preview of Selected Theme
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF101216),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("معاينة السمة: ${activeTheme.name}", style: WadiqTypography.caption.copyWith(color: activeTheme.accentColor, fontWeight: FontWeight.bold)),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: activeTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Receiver bubble preview
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 260),
                    decoration: BoxDecoration(
                      color: activeTheme.receiverBubbleColor,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      "نموذج لون الرسائل الواردة من الآخرين",
                      style: TextStyle(color: activeTheme.receiverTextColor, fontSize: fontSize - 1),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Sender bubble preview
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 260),
                    decoration: BoxDecoration(
                      color: activeTheme.senderBubbleColor,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: activeTheme.borderColor.withValues(alpha: 0.7), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            "نموذج لون الرسائل الصادرة الخاصة بك",
                            style: TextStyle(color: activeTheme.senderTextColor, fontSize: fontSize - 1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.done_all_rounded, size: 14, color: activeTheme.accentColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            "اختر السمة اللونية لفقاعات المحادثة:",
            style: WadiqTypography.titleMedium.copyWith(color: WadiqColors.primaryAmber),
          ),
          const SizedBox(height: 12),

          // Themes List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ChatSettingsService.availableThemes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final theme = ChatSettingsService.availableThemes[i];
              final isSelected = activeTheme.id == theme.id;

              return InkWell(
                onTap: () async {
                  await _service.setColorTheme(theme.id);
                  if (context.mounted) setState(() {});
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: WadiqColors.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? theme.accentColor : WadiqColors.surfaceBorder,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Dual Color preview dots
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.accentColor, width: 2),
                          gradient: LinearGradient(
                            colors: [theme.senderBubbleColor, theme.accentColor],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme.name,
                              style: TextStyle(
                                color: isSelected ? theme.accentColor : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "فقاعة مرسلة • فقاعة مستلمة • إضاءة جانبية",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: theme.accentColor, size: 24)
                      else
                        const Icon(Icons.circle_outlined, color: Colors.white24, size: 22),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
