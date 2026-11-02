import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/wadiq_api_service.dart';

class CallScreen extends StatefulWidget {
  final String targetName;
  final String? targetUsername;
  final String avatarChar;
  final bool isVideo;

  const CallScreen({
    super.key,
    required this.targetName,
    this.targetUsername,
    required this.avatarChar,
    this.isVideo = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _callTimer;
  int _seconds = 0;
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isVideoOff = false;
  bool _isConnecting = true;
  Map<String, dynamic>? _callSession;

  @override
  void initState() {
    super.initState();
    _initiateAgoraCall();
  }

  void _initiateAgoraCall() async {
    final caller = AuthService.instance.currentUser.username;
    final receiver = widget.targetUsername ?? widget.targetName.replaceAll('@', '').trim();

    try {
      final session = await WadiqApiService.instance.initiateCall(
        caller: caller,
        receiver: receiver,
        isVideo: widget.isVideo,
      );

      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _callSession = session;
      });
      _startTimer();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _seconds++;
      });
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  String get _formattedDuration {
    final mins = _seconds ~/ 60;
    final secs = _seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              widget.isVideo ? "مكالمة فيديو مشفرة" : "مكالمة صوتية مشفرة",
              style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber),
            ),
            const SizedBox(height: 8),
            Text(
              widget.targetName,
              style: WadiqTypography.displayMedium.copyWith(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 6),
            Text(
              _isConnecting ? "جاري الاتصال الأكاديمي المشفر..." : _formattedDuration,
              style: WadiqTypography.titleMedium.copyWith(color: Colors.white70),
            ),
            if (_callSession != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: WadiqColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WadiqColors.success.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded, size: 14, color: WadiqColors.success),
                    const SizedBox(width: 6),
                    Text(
                      "قناة Agora مشفرة: ${_callSession!['channelName'] ?? ''}",
                      style: const TextStyle(color: WadiqColors.success, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),

            // Avatar / Video Simulation Canvas
            Center(
              child: widget.isVideo && !_isVideoOff
                  ? Container(
                      width: 220,
                      height: 280,
                      decoration: BoxDecoration(
                        color: WadiqColors.cardSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: WadiqColors.primaryAmber.withValues(alpha: 0.5)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.videocam_rounded, size: 70, color: Colors.white.withValues(alpha: 0.2)),
                          Positioned(
                            bottom: 16,
                            child: Text("الكاميرا نشطة (HD)", style: WadiqTypography.caption),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: WadiqColors.primaryAmber.withValues(alpha: 0.1),
                          ),
                        ),
                        Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: WadiqColors.amberGradient,
                            boxShadow: [
                              BoxShadow(
                                color: WadiqColors.amberGlow,
                                blurRadius: 24,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.avatarChar,
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            const Spacer(),

            // Control Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              decoration: const BoxDecoration(
                color: Color(0xFF161920),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute
                  _buildControlBtn(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? "مكتوم" : "كتم",
                    isActive: _isMuted,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),

                  // Video Toggle (if video call)
                  if (widget.isVideo)
                    _buildControlBtn(
                      icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                      label: _isVideoOff ? "الكاميرا متوقفة" : "الكاميرا",
                      isActive: _isVideoOff,
                      onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                    )
                  else
                    // Speaker
                    _buildControlBtn(
                      icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                      label: "مكبر الصوت",
                      isActive: _isSpeaker,
                      onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                    ),

                  // End Call
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.redAccent, blurRadius: 16, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive ? WadiqColors.primaryAmber : Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isActive ? Colors.black : Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
