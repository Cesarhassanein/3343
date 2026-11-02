import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/services/wadiq_api_service.dart';

class ReelVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isPlaying;

  const ReelVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.isPlaying = true,
  });

  @override
  State<ReelVideoPlayerWidget> createState() => _ReelVideoPlayerWidgetState();
}

class _ReelVideoPlayerWidgetState extends State<ReelVideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  static const List<String> _fallbackCdnVideos = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
  ];

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant ReelVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _initPlayer();
    } else if (_controller != null && _isInitialized) {
      if (widget.isPlaying && !_controller!.value.isPlaying) {
        _controller!.play();
      } else if (!widget.isPlaying && _controller!.value.isPlaying) {
        _controller!.pause();
      }
    }
  }

  String _resolvePlayableUrl(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return '';
    // Relative API path from our backend proxy
    if (clean.startsWith('/api/')) {
      return WadiqApiService.instance.getMediaUrl(clean);
    }
    // Raw Telegram file ID
    if (!clean.startsWith('http') && !clean.startsWith('blob:') && !clean.contains('/')) {
      return WadiqApiService.instance.getMediaUrl(clean);
    }
    return clean;
  }

  Future<void> _initPlayer() async {
    _disposeController();

    final playableUrl = _resolvePlayableUrl(widget.videoUrl);
    if (playableUrl.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(playableUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      _controller = controller;

      await controller.initialize();
      await controller.setLooping(true);
      // Sound is enabled at full volume; volume control is handled by phone's hardware buttons
      await controller.setVolume(1.0);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
        if (widget.isPlaying) {
          try {
            await controller.play();
          } catch (e) {
            debugPrint('[ReelPlayer] Browser required interaction to play: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[ReelPlayer] Video player init error: $e. Retrying with fallback.');
      if (mounted) {
        _retryWithFallback();
      }
    }
  }

  Future<void> _retryWithFallback() async {
    try {
      final fallbackUrl = _fallbackCdnVideos[widget.videoUrl.hashCode.abs() % _fallbackCdnVideos.length];
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(fallbackUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1.0);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
        if (widget.isPlaying) {
          try {
            await controller.play();
          } catch (_) {}
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _disposeController() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 48),
              SizedBox(height: 8),
              Text('تعذر تشغيل هذا المقطع', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        color: const Color(0xFF111111),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: WadiqColors.primaryAmber,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (_controller == null || !_isInitialized) return;
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
        setState(() {});
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 9 / 16,
                child: VideoPlayer(_controller!),
              ),
            ),
            if (!_controller!.value.isPlaying && _isInitialized)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
              ),
          ],
        ),
      ),
    );
  }
}
