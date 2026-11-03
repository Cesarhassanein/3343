import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import 'reels_interactions_settings_screen.dart';
import 'reels_advanced_management_screen.dart';
import 'reels_content_preferences_screen.dart';
import 'reels_time_limit_screen.dart';
import 'reels_activity_center_screen.dart';

class ReelsMainSettingsScreen extends StatelessWidget {
  const ReelsMainSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: const Text(
          'إعدادات الريلز',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WadiqColors.primaryAmber.withValues(alpha: 0.25),
                  WadiqColors.cardSurface,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: WadiqColors.primaryAmber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        'التحكم الكامل بالريلز',
                        style: TextStyle(color: WadiqColors.primaryAmber, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'خصص الخصوصية، تفضيلات المحتوى، الأذونات الدقيقة لكل مقطع، وسجلات الأنشطة التفاعلية.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.video_library_rounded, color: WadiqColors.primaryAmber, size: 30),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Interactions
          _buildSettingsTile(
            context,
            title: '1_ التفاعلات والخصوصية',
            subtitle: 'التعليقات، الإشارة (@)، قائمة المتابعين، وفيديوهات أعجبتك',
            icon: Icons.chat_bubble_outline_rounded,
            badge: 'أساسي',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReelsInteractionsSettingsScreen()),
              );
            },
          ),

          // Section 2: Advanced Reels Management
          _buildSettingsTile(
            context,
            title: '2_ إدارة الريلز المعمق',
            subtitle: 'المحذوف مؤخراً (7 أيام)، إدارة الظهور، أذونات التعليق، وإعادة النشر',
            icon: Icons.admin_panel_settings_outlined,
            badge: 'متقدم',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReelsAdvancedManagementScreen()),
              );
            },
          ),

          // Section 3: Content Preferences
          _buildSettingsTile(
            context,
            title: '3_ تفضيلات المحتوى الخاصة بالريلز',
            subtitle: 'تصفية كلمات محددة، صفحة الدراسة، والحسابات المكتومة',
            icon: Icons.tune_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReelsContentPreferencesScreen()),
              );
            },
          ),

          // Section 4: Time Limit
          _buildSettingsTile(
            context,
            title: '4_ الوقت المحدد',
            subtitle: 'إدارة وقت الشاشة وتنبيهات أخذ استراحة (حالياً تجريبي)',
            icon: Icons.timer_outlined,
            trailingBadge: 'تجريبي',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReelsTimeLimitScreen()),
              );
            },
          ),

          // Section 5: Activity Center
          _buildSettingsTile(
            context,
            title: '5_ مركز الأنشطة',
            subtitle: 'سجل المشاهدة، سجل التعليقات، سجل البحث، وسجل الإشارات',
            icon: Icons.history_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReelsActivityCenterScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    String? badge,
    String? trailingBadge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: WadiqColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios, color: Colors.white24, size: 14),
                if (trailingBadge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: WadiqColors.primaryAmber.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      trailingBadge,
                      style: const TextStyle(color: WadiqColors.primaryAmber, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),
                Expanded(
                  flex: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (badge != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(badge, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                            ),
                          ],
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WadiqColors.obsidianBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Icon(icon, color: WadiqColors.primaryAmber, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
