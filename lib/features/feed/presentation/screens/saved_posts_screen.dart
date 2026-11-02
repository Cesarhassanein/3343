import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/post_service.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<PostModel> _savedPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    setState(() => _isLoading = true);
    final allPosts = await PostService.instance.fetchPosts();
    final saved = PostService.instance.fetchSavedPosts(allPosts);
    if (mounted) {
      setState(() {
        _savedPosts = saved;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Text(
          'المحفوظات',
          style: WadiqTypography.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: WadiqColors.textSecondary),
            onPressed: _loadSavedPosts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: WadiqColors.primaryAmber),
            )
          : _savedPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: WadiqColors.cardSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: WadiqColors.surfaceBorder),
                        ),
                        child: const Icon(
                          Icons.bookmark_border_rounded,
                          size: 48,
                          color: WadiqColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد منشورات محفوظة',
                        style: WadiqTypography.titleMedium.copyWith(color: WadiqColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'اضغط على أيقونة الحفظ في أي منشور لحفظه هنا والرجوع إليه لاحقاً.',
                          textAlign: TextAlign.center,
                          style: WadiqTypography.caption,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: WadiqColors.primaryAmber,
                  onRefresh: _loadSavedPosts,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _savedPosts.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: WadiqColors.surfaceBorder,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final post = _savedPosts[index];
                      return PostCard(
                        post: post,
                        onCommentTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(post: post),
                            ),
                          ).then((_) => _loadSavedPosts());
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
