import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/auth_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'chat_appearance_settings_screen.dart';
import 'chat_folders_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _retentionAlerts = true;
  bool _soundEnabled = true;
  bool _mediaAutoDownload = false;
  String _cacheSize = "42.5 MB";

  void _showEditProfileDialog() {
    final user = AuthService.instance.currentUser;
    final nameController = TextEditingController(text: user.fullName);
    final bioController = TextEditingController(text: user.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WadiqColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("تعديل الملف الشخصي", style: WadiqTypography.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close, color: WadiqColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text("الاسم الكامل الأكاديمي:", style: WadiqTypography.caption),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: WadiqColors.elevatedSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              Text("نبذة / الكلية والتخصص:", style: WadiqTypography.caption),
              const SizedBox(height: 6),
              TextField(
                controller: bioController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "مثال: طالب علوم الحاسوب • جامعة بغداد",
                  hintStyle: const TextStyle(color: WadiqColors.textMuted),
                  filled: true,
                  fillColor: WadiqColors.elevatedSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WadiqColors.primaryAmber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("حفظ التغييرات", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    final newBio = bioController.text.trim();
                    if (newName.isNotEmpty) {
                      await AuthService.instance.updateProfile(fullName: newName, bio: newBio);
                      if (mounted) setState(() {});
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("تم تحديث الملف الشخصي بنجاح!"),
                          backgroundColor: WadiqColors.success,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WadiqColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("تسجيل الخروج", style: WadiqTypography.titleLarge),
        content: Text(
          "هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟",
          style: WadiqTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            child: const Text("إلغاء", style: TextStyle(color: WadiqColors.textSecondary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WadiqColors.alert,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("خروج"),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final initial = user.fullName.isNotEmpty ? user.fullName.substring(0, 1) : 'م';

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        title: Text(
          "الإعدادات والخصوصية",
          style: WadiqTypography.displayMedium.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: WadiqColors.surfaceBorder),
              gradient: WadiqColors.cardGlowGradient,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    gradient: WadiqColors.amberGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: WadiqTypography.titleLarge.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "@${user.username} • ${user.role}",
                        style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: WadiqColors.primaryAmber),
                  tooltip: "تعديل الملف الشخصي",
                  onPressed: _showEditProfileDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Content Lifecycle & 10-Day Retention
          _buildSectionHeader("سياسة بقاء المحتوى والتجديد (10 أيام)"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.surfaceBorder),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.hourglass_bottom, color: WadiqColors.primaryAmber, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("قاعدة الـ 10 أيام للمنشورات",
                              style: WadiqTypography.titleMedium.copyWith(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            "يختفي كل منشور تلقائياً بعد مرور 10 أيام، ويمكن تجديده لمدة 10 أيام إضافية فقط خلال آخر 24 ساعة من صلاحيته.",
                            style: WadiqTypography.caption.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: WadiqColors.divider, height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: WadiqColors.primaryAmber,
                  title: Text("تنبيهات اقتراب الحذف", style: WadiqTypography.bodyMedium),
                  subtitle: Text("إشعارك قبل 24 ساعة لتجديد منشوراتك قبل أرشفتها", style: WadiqTypography.caption),
                  value: _retentionAlerts,
                  onChanged: (val) => setState(() => _retentionAlerts = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: قسم المراسلات
          _buildSectionHeader("قسم المراسلات"),
          _buildCardGroup([
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_outlined, color: WadiqColors.primaryAmber, size: 20),
              ),
              title: Text("1_ المحادثات", style: WadiqTypography.bodyLarge),
              subtitle: Text("حجم الخط، الخلفيات، الألوان، زاوية الرسالة، عرض القائمة", style: WadiqTypography.caption),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatAppearanceSettingsScreen()),
                );
              },
            ),
            const Divider(color: WadiqColors.divider, height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WadiqColors.primaryAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.folder_copy_outlined, color: WadiqColors.primaryAmber, size: 20),
              ),
              title: Text("2_ مجلدات المحادثات", style: WadiqTypography.bodyLarge),
              subtitle: Text("إنشاء مجلدات مخصصة، تغيير الترتيب، تصنيف المحادثات", style: WadiqTypography.caption),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatFoldersSettingsScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),

          // Section 2: Notifications & Chat
          _buildSectionHeader("الإشعارات والتواصل"),
          _buildCardGroup([
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: WadiqColors.primaryAmber,
              title: Text("أصوات الإشعارات والتنبيهات", style: WadiqTypography.bodyMedium),
              subtitle: Text("نغمات مميزة للرسائل والقنوات الأكاديمية", style: WadiqTypography.caption),
              value: _soundEnabled,
              onChanged: (val) => setState(() => _soundEnabled = val),
            ),
            const Divider(color: WadiqColors.divider, height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: WadiqColors.primaryAmber,
              title: Text("التحميل التلقائي للوسائط", style: WadiqTypography.bodyMedium),
              subtitle: Text("تنزيل الملازم والصور عبر الشبكة", style: WadiqTypography.caption),
              value: _mediaAutoDownload,
              onChanged: (val) => setState(() => _mediaAutoDownload = val),
            ),
          ]),
          const SizedBox(height: 20),

          // Section 3: Appearance & Language
          _buildSectionHeader("المظهر والأداء"),
          _buildCardGroup([
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language, color: WadiqColors.primaryAmber),
              title: Text("اللغة", style: WadiqTypography.bodyMedium),
              trailing: Text(
                "العربية (RTL)",
                style: WadiqTypography.badge.copyWith(color: WadiqColors.primaryAmber),
              ),
            ),
            const Divider(color: WadiqColors.divider, height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dark_mode_outlined, color: WadiqColors.primaryAmber),
              title: Text("السمة البصرية", style: WadiqTypography.bodyMedium),
              trailing: Text("Obsidian Dark", style: WadiqTypography.caption),
            ),
            const Divider(color: WadiqColors.divider, height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cleaning_services_outlined, color: WadiqColors.primaryAmber),
              title: Text("تفريغ الذاكرة المؤقتة", style: WadiqTypography.bodyMedium),
              trailing: Text(_cacheSize, style: WadiqTypography.caption),
              onTap: () {
                setState(() => _cacheSize = "0 MB");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم تفريغ الذاكرة المؤقتة بنجاح")),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),

          // Section 4: Security & Logout
          _buildSectionHeader("الحساب والأمان"),
          _buildCardGroup([
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_user_outlined, color: WadiqColors.success),
              title: Text("حالة التوثيق الأكاديمي", style: WadiqTypography.bodyMedium),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: WadiqColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text("موثق", style: TextStyle(color: WadiqColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            const Divider(color: WadiqColors.divider, height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded, color: WadiqColors.alert),
              title: Text(
                "تسجيل الخروج",
                style: WadiqTypography.bodyMedium.copyWith(color: WadiqColors.alert, fontWeight: FontWeight.bold),
              ),
              onTap: _confirmLogout,
            ),
          ]),
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
          color: WadiqColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: WadiqColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WadiqColors.surfaceBorder),
      ),
      child: Column(children: children),
    );
  }
}
