import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/wadiq_button.dart';
import '../../../../core/services/auth_service.dart';
import 'ai_tutor_screen.dart';
import 'course_detail_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class AcademicCourse {
  final String title;
  final String instructor;
  final double progress;
  final int lessonsCount;
  final IconData icon;
  final String faculty;

  const AcademicCourse({
    required this.title,
    required this.instructor,
    required this.progress,
    required this.lessonsCount,
    required this.icon,
    required this.faculty,
  });
}

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final List<AcademicCourse> _allCourses = const [
    AcademicCourse(
      title: "الرياضيات المتقدمة والتفاضل والتكامل الأكاديمي",
      instructor: "أ.د. هيثم السعدي",
      progress: 0.65,
      lessonsCount: 18,
      icon: Icons.calculate_outlined,
      faculty: "كلية العلوم والهندسة",
    ),
    AcademicCourse(
      title: "الفيزياء الجامعية العامة والكهرومغناطيسية",
      instructor: "د. رؤوف الجادرجي",
      progress: 0.40,
      lessonsCount: 24,
      icon: Icons.science_outlined,
      faculty: "قسم العلوم الأساسية",
    ),
    AcademicCourse(
      title: "أصول البحث العلمي ومناهج التحليل الأكاديمي",
      instructor: "د. سناء البغدادي",
      progress: 0.85,
      lessonsCount: 12,
      icon: Icons.menu_book_rounded,
      faculty: "الدراسات الجامعية المشتركة",
    ),
    AcademicCourse(
      title: "الإحصاء الأكاديمي ونظرية الاحتمالات الجامعية",
      instructor: "د. عمار الجبوري",
      progress: 0.30,
      lessonsCount: 16,
      icon: Icons.insights_rounded,
      faculty: "كلية العلوم التطبيقية",
    ),
    AcademicCourse(
      title: "الكيمياء العامة والتحليلية للمرحلة الأولى",
      instructor: "أ.د. مريم العبيدي",
      progress: 0.50,
      lessonsCount: 20,
      icon: Icons.biotech_outlined,
      faculty: "كلية العلوم الصرفة",
    ),
    AcademicCourse(
      title: "المنطق واللغة العربية للجامعات الأكاديمية",
      instructor: "د. طه الشمري",
      progress: 0.90,
      lessonsCount: 14,
      icon: Icons.auto_stories_outlined,
      faculty: "قسم المتطلبات العامة",
    ),
  ];

  void _showAllCoursesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WadiqColors.obsidianBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: WadiqColors.surfaceBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "كافة المقررات الأكاديمية الجامعية",
                        style: WadiqTypography.titleLarge.copyWith(fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: WadiqColors.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "المقررات الدراسية المعتمدة للفصل الدراسي الأكاديمي",
                    style: WadiqTypography.caption,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _allCourses.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final c = _allCourses[idx];
                        return _buildCourseCard(
                          context: context,
                          title: c.title,
                          instructor: '${c.instructor} • ${c.faculty}',
                          progress: c.progress,
                          lessonsCount: c.lessonsCount,
                          icon: c.icon,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final initial = user.fullName.isNotEmpty ? user.fullName.substring(0, 1) : 'ط';

    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        title: Text(
          "الملف الشخصي والدراسة",
          style: WadiqTypography.displayMedium.copyWith(fontSize: 22),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              setState(() {});
            },
            icon: const Icon(Icons.settings_outlined, size: 22),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: WadiqColors.primaryAmber,
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Header Card with Real User Data
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: WadiqColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WadiqColors.surfaceBorder, width: 0.9),
                  gradient: WadiqColors.cardGlowGradient,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            gradient: WadiqColors.amberGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: WadiqColors.amberGlow,
                                blurRadius: 12,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 26,
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
                                style: WadiqTypography.titleLarge.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "@${user.username} • ${user.role}",
                                style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber),
                              ),
                              if (user.bio != null && user.bio!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  user.bio!,
                                  style: WadiqTypography.caption.copyWith(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Counters
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProfileCounter("منشورات", "${user.postsCount}"),
                        Container(width: 1, height: 26, color: WadiqColors.divider),
                        _buildProfileCounter("متابعون", "${user.followersCount}"),
                        Container(width: 1, height: 26, color: WadiqColors.divider),
                        _buildProfileCounter("إعجابات", "${user.likesCount}"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Wadiq AI Assistant Hero Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2E170E),
                      Color(0xFF1E1410),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  border: Border.all(color: WadiqColors.primaryAmber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: WadiqColors.amberGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "مساعد ودق الذكي (AI)",
                            style: WadiqTypography.titleMedium.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "اسأل عن أي مسألة أو لخص محاضراتك فوراً",
                            style: WadiqTypography.caption.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    WadiqButton(
                      text: "ابدأ الآن",
                      height: 36,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiTutorScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: My Courses / Study Modules
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "مقرراتي الدراسية",
                    style: WadiqTypography.titleLarge,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 13, color: WadiqColors.primaryAmber),
                    onPressed: _showAllCoursesModal,
                    label: Text(
                      "عرض الكل",
                      style: WadiqTypography.badge.copyWith(color: WadiqColors.primaryAmber),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // University Academic Course Cards
              ..._allCourses.take(3).map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCourseCard(
                      context: context,
                      title: c.title,
                      instructor: c.instructor,
                      progress: c.progress,
                      lessonsCount: c.lessonsCount,
                      icon: c.icon,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCounter(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: WadiqTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: WadiqColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: WadiqTypography.caption,
        ),
      ],
    );
  }

  Widget _buildCourseCard({
    required BuildContext context,
    required String title,
    required String instructor,
    required double progress,
    required int lessonsCount,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDetailScreen(
              title: title,
              instructor: instructor,
              progress: progress,
              lessonsCount: lessonsCount,
              icon: icon,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WadiqColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WadiqColors.surfaceBorder, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: WadiqColors.elevatedSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WadiqColors.primaryAmber.withValues(alpha: 0.2)),
              ),
              child: Icon(
                icon,
                color: WadiqColors.primaryAmber,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WadiqTypography.titleMedium.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    instructor,
                    style: WadiqTypography.caption.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: WadiqColors.surfaceBorder,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              WadiqColors.primaryAmber,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: WadiqTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_left,
              color: WadiqColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
