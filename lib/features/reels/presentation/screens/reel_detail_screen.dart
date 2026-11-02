import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/reel_service.dart';
import '../widgets/reel_video_player_widget.dart';

class ReelDetailScreen extends StatefulWidget {
  final ReelModel reel;

  const ReelDetailScreen({super.key, required this.reel});

  @override
  State<ReelDetailScreen> createState() => _ReelDetailScreenState();
}

class _ReelDetailScreenState extends State<ReelDetailScreen> {
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    ReelService.instance.incrementViews(widget.reel);
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          reel.creatorName,
          style: WadiqTypography.titleMedium.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => setState(() => _isPlaying = !_isPlaying),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Player
            ReelVideoPlayerWidget(
              videoUrl: reel.videoUrl,
              isPlaying: _isPlaying,
            ),

            // Play/Pause Overlay indicator
            if (!_isPlaying)
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
                ),
              ),

            // Bottom Overlay Details
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "@${reel.creatorUsername}",
                        style: WadiqTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        reel.timeAgo,
                        style: WadiqTypography.caption.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  if (reel.caption != null && reel.caption!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      reel.caption!,
                      style: WadiqTypography.bodyMedium.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.music_note_rounded, size: 16, color: WadiqColors.primaryAmber),
                      const SizedBox(width: 4),
                      Text(
                        reel.soundTitle,
                        style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.visibility_rounded, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text("${reel.viewsCount} مشاهدة", style: WadiqTypography.caption.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
