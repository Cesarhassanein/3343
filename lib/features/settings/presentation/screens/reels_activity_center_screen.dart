import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/services/reels_settings_service.dart';

class ReelsActivityCenterScreen extends StatefulWidget {
  const ReelsActivityCenterScreen({super.key});

  @override
  State<ReelsActivityCenterScreen> createState() => _ReelsActivityCenterScreenState();
}

class _ReelsActivityCenterScreenState extends State<ReelsActivityCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = ReelsSettingsService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: WadiqColors.obsidianBlack,
          appBar: AppBar(
            backgroundColor: WadiqColors.obsidianBlack,
            elevation: 0,
            title: const Text(
              'مركز الأنشطة',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: WadiqColors.primaryAmber,
              labelColor: WadiqColors.primaryAmber,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'سجل المشاهدة', icon: Icon(Icons.history, size: 20)),
                Tab(text: 'سجل التعليقات', icon: Icon(Icons.comment_outlined, size: 20)),
                Tab(text: 'سجل البحث', icon: Icon(Icons.search, size: 20)),
                Tab(text: 'سجل الإشارات (@)', icon: Icon(Icons.alternate_email, size: 20)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildWatchHistoryTab(),
              _buildCommentsHistoryTab(),
              _buildSearchHistoryTab(),
              _buildMentionsHistoryTab(),
            ],
          ),
        );
      },
    );
  }

  // 1. Watch History Tab
  Widget _buildWatchHistoryTab() {
    final list = _service.watchHistory;
    return Column(
      children: [
        if (list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: WadiqColors.cardSurface,
                        title: const Text('مسح سجل المشاهدة', style: TextStyle(color: Colors.white), textAlign: TextAlign.right),
                        content: const Text('هل أنت متأكد من رغبتك في حذف كامل سجل المشاهدة؟', style: TextStyle(color: Colors.white70), textAlign: TextAlign.right),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () {
                              _service.clearWatchHistory();
                              Navigator.pop(ctx);
                            },
                            child: const Text('مسح الكل', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 18),
                  label: const Text('مسح السجل', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
                Text('${list.length} مقطع تمت مشاهدته', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState(
                  icon: Icons.history,
                  title: 'لا يوجد سجل مشاهدة بعد',
                  subtitle: 'ستظهر هنا مقاطع الريلز التي شاهدتها مؤخراً',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                  itemBuilder: (ctx, idx) {
                    final item = list[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: WadiqColors.primaryAmber, size: 28),
                      ),
                      title: Text(
                        item['title'] ?? 'مقطع ريلز',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'من: @${item['creator'] ?? 'مستخدم'}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                      trailing: const Icon(Icons.arrow_back_ios, color: Colors.white24, size: 14),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 2. Comments History Tab
  Widget _buildCommentsHistoryTab() {
    final list = _service.commentsHistory;
    return list.isEmpty
        ? _buildEmptyState(
            icon: Icons.comment_outlined,
            title: 'لا توجد تعليقات سابقة',
            subtitle: 'ستظهر هنا التعليقات التي قمت بكتابتها على مقاطع الريلز',
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10),
            itemBuilder: (ctx, idx) {
              final item = list[idx];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WadiqColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: WadiqColors.primaryAmber, size: 16),
                        Text(
                          'على ريلز: ${item['reelTitle'] ?? 'مقطع'}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['comment'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              );
            },
          );
  }

  // 3. Search History Tab
  Widget _buildSearchHistoryTab() {
    final list = _service.searchHistory;
    return Column(
      children: [
        if (list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _service.clearSearchHistory(),
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 18),
                  label: const Text('مسح سجل البحث', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
                Text('${list.length} عمليات بحث', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'سجل البحث فارغ',
                  subtitle: 'عمليات البحث الأخيرة في الريلز ستظهر هنا',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                  itemBuilder: (ctx, idx) {
                    final query = list[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                        onPressed: () {
                          final current = List<String>.from(list)..remove(query);
                          _service.clearSearchHistory().then((_) {
                            for (var q in current.reversed) {
                              _service.recordSearchQuery(q);
                            }
                          });
                        },
                      ),
                      title: Text(
                        query,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
                      trailing: const Icon(Icons.history, color: WadiqColors.primaryAmber, size: 20),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 4. Mentions History Tab
  Widget _buildMentionsHistoryTab() {
    final list = _service.mentionsHistory;
    return list.isEmpty
        ? _buildEmptyState(
            icon: Icons.alternate_email,
            title: 'لا توجد إشارات لك',
            subtitle: 'عندما يقوم أحد بالإشارة إليك في ريلز أو تعليق، ستظهر هنا',
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10),
            itemBuilder: (ctx, idx) {
              final item = list[idx];
              return ListTile(
                title: Text(item['title'] ?? 'إشارة جديدة', style: const TextStyle(color: Colors.white), textAlign: TextAlign.right),
                subtitle: Text(item['sender'] ?? '', style: const TextStyle(color: Colors.white54), textAlign: TextAlign.right),
              );
            },
          );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
