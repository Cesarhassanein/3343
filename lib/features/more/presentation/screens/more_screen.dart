import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/post_service.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../../study/presentation/screens/study_screen.dart';
import '../../../study/presentation/screens/ai_tutor_screen.dart';
import '../../../feed/presentation/screens/saved_posts_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../../core/services/update_service.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  int _postsCount = 0;
  int _savedCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = AuthService.instance.currentUser;
    final allPosts = await PostService.instance.fetchPosts();
    final myPosts = allPosts.where((p) => p.authorUsername.toLowerCase() == user.username.toLowerCase()).toList();
    final saved = PostService.instance.fetchSavedPosts(allPosts);
    final following = PostService.instance.followedUsernames.length;

    if (mounted) {
      setState(() {
        _postsCount = myPosts.length;
        _savedCount = saved.length;
        _followingCount = following;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final avatarLetter = user.fullName.isNotEmpty ? user.fullName[0] : 'أ';

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Text(
          "المزيد",
          style: WadiqTypography.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: WadiqColors.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: WadiqColors.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: WadiqColors.primaryAmber,
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(
                        name: user.fullName,
                        role: user.role,
                        avatarChar: avatarLetter,
                        handle: '@${user.username}',
                      ),
                    ),
                  ).then((_) => _loadStats());
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WadiqColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: WadiqColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          gradient: WadiqColors.amberGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            avatarLetter,
                            style: WadiqTypography.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.fullName,
                                    style: WadiqTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user.role,
                                    style: WadiqTypography.badge.copyWith(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${user.username}',
                              style: WadiqTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: WadiqColors.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('منشوراتي', '$_postsCount', Icons.article_outlined),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard('أتابعهم', '$_followingCount', Icons.people_outline_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard('المحفوظات', '$_savedCount', Icons.bookmark_outline_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                'الخدمات والأقسام',
                style: WadiqTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              // Modular Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _buildGridTile(
                    title: 'المقررات الدراسية',
                    subtitle: 'المناهج الجامعية والأكاديمية',
                    icon: Icons.school_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudyScreen()),
                      );
                    },
                  ),
                  _buildGridTile(
                    title: 'مساعد ودق الذكي',
                    subtitle: 'شرح المقررات وحل المسائل (AI)',
                    icon: Icons.auto_awesome_rounded,
                    color: WadiqColors.primaryAmber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AiTutorScreen()),
                      );
                    },
                  ),
                  _buildGridTile(
                    title: 'المحفوظات',
                    subtitle: 'المنشورات التي قمت بحفظها',
                    icon: Icons.bookmark_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
                      ).then((_) => _loadStats());
                    },
                  ),
                  _buildGridTile(
                    title: 'الإشعارات والتنبيهات',
                    subtitle: 'التفاعلات والردود والمتابعات',
                    icon: Icons.notifications_active_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Settings & Tools section
              Container(
                decoration: BoxDecoration(
                  color: WadiqColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: WadiqColors.surfaceBorder),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'تعديل الملف الشخصي',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(
                              name: user.fullName,
                              role: user.role,
                              avatarChar: avatarLetter,
                              handle: '@${user.username}',
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(color: WadiqColors.surfaceBorder, height: 1, indent: 56),
                    _buildSettingsTile(
                      icon: Icons.settings_outlined,
                      title: 'الإعدادات والخصوصية',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                    const Divider(color: WadiqColors.surfaceBorder, height: 1, indent: 56),
                    _buildSettingsTile(
                      icon: Icons.security_rounded,
                      title: 'الأمان وإدارة الجلسات',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('جلسة الدخول آمنة ومحمية عبر خوادم سوبابيز.'),
                            backgroundColor: WadiqColors.cardSurface,
                          ),
                        );
                      },
                    ),
                    const Divider(color: WadiqColors.surfaceBorder, height: 1, indent: 56),
                    _buildSettingsTile(
                      icon: Icons.system_update_rounded,
                      title: 'التحقق من التحديثات (الإصدار ${UpdateService.currentVersionName})',
                      onTap: () {
                        UpdateService.instance.checkForUpdate(context, silent: false);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: WadiqColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WadiqColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: WadiqColors.primaryAmber),
          const SizedBox(height: 6),
          Text(
            value,
            style: WadiqTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: WadiqTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildGridTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: WadiqColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WadiqColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WadiqTypography.titleMedium.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: WadiqTypography.caption.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: WadiqColors.primaryAmber, size: 22),
      title: Text(title, style: WadiqTypography.bodyMedium),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: WadiqColors.textMuted),
      onTap: onTap,
    );
  }
}
