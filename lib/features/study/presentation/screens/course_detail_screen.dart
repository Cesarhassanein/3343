import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/widgets/wadiq_button.dart';
import 'lesson_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String title;
  final String instructor;
  final double progress;
  final int lessonsCount;
  final IconData icon;

  const CourseDetailScreen({
    super.key,
    required this.title,
    required this.instructor,
    required this.progress,
    required this.lessonsCount,
    required this.icon,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _syllabus = [
    {
      'title': 'الوحدة الأولى: المفاهيم الأساسية والبيئة التطويرية',
      'duration': '1 ساعة 45 دقيقة',
      'lessons': [
        {
          'id': '1',
          'title': 'المقدمة وهندسة النظام في المنصة',
          'duration': '12:30',
          'isCompleted': true,
          'isFree': true,
        },
        {
          'id': '2',
          'title': 'تثبيت الأدوات وإعداد بيئة العمل',
          'duration': '18:15',
          'isCompleted': true,
          'isFree': true,
        },
        {
          'id': '3',
          'title': 'بنية المشروع ومبادئ Clean Architecture',
          'duration': '24:40',
          'isCompleted': true,
          'isFree': false,
        },
      ],
    },
    {
      'title': 'الوحدة الثانية: البرمجة المتقدمة وإدارة الحالة',
      'duration': '2 ساعة 30 دقيقة',
      'lessons': [
        {
          'id': '4',
          'title': 'إدارة الحالة الموزعة والتفاعل اللحظي',
          'duration': '22:10',
          'isCompleted': false,
          'isFree': false,
        },
        {
          'id': '5',
          'title': 'التعامل مع Realtime WebSockets و Supabase',
          'duration': '31:05',
          'isCompleted': false,
          'isFree': false,
        },
        {
          'id': '6',
          'title': 'تحسين الأداء والتخزين المؤقت LRU',
          'duration': '27:50',
          'isCompleted': false,
          'isFree': false,
        },
      ],
    },
    {
      'title': 'الوحدة الثالثة: المشروع التطبيقي والنشر النهائي',
      'duration': '3 ساعات 10 دقائق',
      'lessons': [
        {
          'id': '7',
          'title': 'بناء واجهات المستخدم التفاعلية RTL',
          'duration': '35:00',
          'isCompleted': false,
          'isFree': false,
        },
        {
          'id': '8',
          'title': 'اختبارات الوحدة والنشر متعدد المنصات',
          'duration': '40:20',
          'isCompleted': false,
          'isFree': false,
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            WadiqColors.obsidianBlack,
                            WadiqColors.darkCharcoal,
                            Color(0xFF201614),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          size: 80,
                          color: WadiqColors.primaryAmber.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: WadiqColors.primaryAmber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: WadiqColors.primaryAmber.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              "مسار تخصصي معتمد",
                              style: WadiqTypography.badge.copyWith(
                                color: WadiqColors.primaryAmber,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.title,
                            style: WadiqTypography.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instructor Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: WadiqColors.primaryAmber,
                          child: Text(
                            widget.instructor.isNotEmpty ? widget.instructor[0] : "م",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.instructor,
                                  style: WadiqTypography.titleMedium,
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: WadiqColors.primaryAmber,
                                ),
                              ],
                            ),
                            Text(
                              "مدرس معتمد • تقييم 4.9 (420 مراجعة)",
                              style: WadiqTypography.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Course Metrics Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: WadiqColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: WadiqColors.surfaceBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetric(Icons.video_collection_outlined,
                              "${widget.lessonsCount} درساً"),
                          _buildMetric(Icons.schedule_outlined, "7.5 ساعة"),
                          _buildMetric(Icons.people_outline, "1,420 طالباً"),
                          _buildMetric(Icons.workspace_premium_outlined, "شهادة"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Progress Header if enrolled
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("نسبة الإنجاز في المسار",
                                style: WadiqTypography.bodyMedium),
                            Text(
                              "${(widget.progress * 100).toInt()}% مكتمل",
                              style: WadiqTypography.badge.copyWith(
                                color: WadiqColors.primaryAmber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: widget.progress,
                            minHeight: 8,
                            backgroundColor: WadiqColors.surfaceBorder,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              WadiqColors.primaryAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabHeaderDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: WadiqColors.primaryAmber,
                  labelColor: WadiqColors.primaryAmber,
                  unselectedLabelColor: WadiqColors.textSecondary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: "المنهاج والدروس"),
                    Tab(text: "عن المسار"),
                    Tab(text: "المناقشات والأسئلة"),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Syllabus
            _buildSyllabusTab(),
            // Tab 2: About
            _buildAboutTab(),
            // Tab 3: Discussion
            _buildDiscussionTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: WadiqColors.cardSurface,
          border: Border(
            top: BorderSide(color: WadiqColors.surfaceBorder),
          ),
        ),
        child: SafeArea(
          child: WadiqButton(
            text: widget.progress > 0 ? "متابعة التعلم الآن" : "التسجيل في المسار مجاناً",
            icon: Icons.play_circle_fill,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LessonPlayerScreen(
                    courseTitle: widget.title,
                    lessonTitle: _syllabus.first['lessons'][0]['title'],
                    lessonDuration: _syllabus.first['lessons'][0]['duration'],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: WadiqColors.primaryAmber),
        const SizedBox(width: 6),
        Text(text, style: WadiqTypography.caption),
      ],
    );
  }

  Widget _buildSyllabusTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _syllabus.length,
      itemBuilder: (context, index) {
        final chapter = _syllabus[index];
        final List lessons = chapter['lessons'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: WadiqColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WadiqColors.surfaceBorder),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              title: Text(
                chapter['title'],
                style: WadiqTypography.titleMedium.copyWith(fontSize: 14),
              ),
              subtitle: Text(
                "${lessons.length} دروس • ${chapter['duration']}",
                style: WadiqTypography.caption,
              ),
              children: lessons.map((lesson) {
                final bool isDone = lesson['isCompleted'] == true;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: isDone
                        ? WadiqColors.success.withValues(alpha: 0.2)
                        : WadiqColors.elevatedSurface,
                    child: Icon(
                      isDone ? Icons.check : Icons.play_arrow,
                      size: 16,
                      color: isDone ? WadiqColors.success : WadiqColors.primaryAmber,
                    ),
                  ),
                  title: Text(
                    lesson['title'],
                    style: WadiqTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      color: isDone
                          ? WadiqColors.textSecondary
                          : WadiqColors.textPrimary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lesson['duration'],
                        style: WadiqTypography.caption.copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_left,
                        size: 18,
                        color: WadiqColors.textMuted,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonPlayerScreen(
                          courseTitle: widget.title,
                          lessonTitle: lesson['title'],
                          lessonDuration: lesson['duration'],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "نظرة عامة على المسار",
          style: WadiqTypography.titleLarge.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          "يقدم هذا المسار التعليمي الشامل أحدث المفاهيم البرمجية لتطوير تطبيقات تفاعلية متكاملة، بالاعتماد على أفضل الممارسات المتبعة في المشاريع الضخمة.\n\nيشمل المنهج دراسة الهندسة النظيفة (Clean Architecture)، التكامل اللحظي مع قواعد البيانات بدون قيود الاحتكار، ودمج الذكاء الاصطناعي لرفع كفاءة البرمجة.",
          style: WadiqTypography.bodyMedium.copyWith(
            color: WadiqColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "المتطلبات السابقة",
          style: WadiqTypography.titleLarge.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildRequirementItem("معرفة أساسية بمبادئ البرمجة كائنية التوجه (OOP)."),
        _buildRequirementItem("حاسوب متصل بالإنترنت ومجهز لتثبيت حزم التطوير."),
        _buildRequirementItem("الرغبة في بناء مشاريع عربية بمعايير عالمية."),
      ],
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: WadiqColors.primaryAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: WadiqTypography.bodyMedium.copyWith(
                color: WadiqColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: WadiqColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WadiqColors.surfaceBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.forum_outlined,
                  color: WadiqColors.primaryAmber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("مجتمع النقاش المباشر",
                        style: WadiqTypography.titleMedium.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text("اطرح أسئلتك على المدرس وزملائك في المسار",
                        style: WadiqTypography.caption),
                  ],
                ),
              ),
              WadiqButton(
                text: "سؤال جديد",
                height: 36,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildQuestionCard(
          author: "سجاد علي",
          timeAgo: "منذ 4 ساعات",
          question: "كيف يمكن تفادي مشاكل الاتصال أثناء الاشتراك في Realtime WebSocket؟",
          answersCount: 3,
        ),
        const SizedBox(height: 12),
        _buildQuestionCard(
          author: "فاطمة أحمد",
          timeAgo: "أمس",
          question: "هل يفضل استخدام BLoC أو Riverpod في تطبيقات الوسائط التفاعلية؟",
          answersCount: 7,
        ),
      ],
    );
  }

  Widget _buildQuestionCard({
    required String author,
    required String timeAgo,
    required String question,
    required int answersCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WadiqColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WadiqColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: WadiqColors.elevatedSurface,
                child: Text(
                  author[0],
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(author, style: WadiqTypography.titleMedium.copyWith(fontSize: 12)),
              const Spacer(),
              Text(timeAgo, style: WadiqTypography.caption.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(question, style: WadiqTypography.bodyMedium.copyWith(fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 14, color: WadiqColors.textMuted),
              const SizedBox(width: 4),
              Text("$answersCount إجابات", style: WadiqTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliverTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabHeaderDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: WadiqColors.obsidianBlack,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabHeaderDelegate oldDelegate) {
    return false;
  }
}
