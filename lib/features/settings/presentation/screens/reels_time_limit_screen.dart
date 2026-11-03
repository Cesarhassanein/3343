import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';

class ReelsTimeLimitScreen extends StatefulWidget {
  const ReelsTimeLimitScreen({super.key});

  @override
  State<ReelsTimeLimitScreen> createState() => _ReelsTimeLimitScreenState();
}

class _ReelsTimeLimitScreenState extends State<ReelsTimeLimitScreen> {
  bool _enableDailyLimit = false;
  double _limitMinutes = 45;
  bool _enableBreakReminder = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: const Text(
          'الوقت المحدد للريلز',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Trial Mode Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WadiqColors.primaryAmber.withValues(alpha: 0.25),
                  WadiqColors.cardSurface,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WadiqColors.primaryAmber.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        'حالياً في وضع التجربة قريباً ⏳',
                        style: TextStyle(
                          color: WadiqColors.primaryAmber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'نعمل على تطوير نظام ذكي لإدارة وقت مشاهدة الريلز ومساعدتك في تنظيم أوقاتك الدراسية واليومية دون إهدار للوقت. الميزة ستتوفر بالكامل في التحديث القادم!',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WadiqColors.primaryAmber.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, color: WadiqColors.primaryAmber, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Daily screen time section preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Switch.adaptive(
                      value: _enableDailyLimit,
                      activeColor: WadiqColors.primaryAmber,
                      onChanged: (val) {
                        setState(() {
                          _enableDailyLimit = val;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val
                                  ? 'تم تفعيل منبه الحد اليومي التجريبي (${_limitMinutes.toInt()} دقيقة)'
                                  : 'تم إيقاف الحد اليومي',
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: const [
                        Text(
                          'تحديد سقف يومي للمشاهدة',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.timer_outlined, color: WadiqColors.primaryAmber, size: 20),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'تنبيهك بإشعار صوتي عند وصولك للحد الأقصى اليومي المسموح به.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
                if (_enableDailyLimit) ...[
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_limitMinutes.toInt()} دقيقة',
                        style: const TextStyle(color: WadiqColors.primaryAmber, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'الحد المسموح يومياً:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: WadiqColors.primaryAmber,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: WadiqColors.primaryAmber,
                    ),
                    child: Slider(
                      value: _limitMinutes,
                      min: 15,
                      max: 180,
                      divisions: 11,
                      onChanged: (val) {
                        setState(() {
                          _limitMinutes = val;
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Break reminders
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WadiqColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Switch.adaptive(
                  value: _enableBreakReminder,
                  activeColor: WadiqColors.primaryAmber,
                  onChanged: (val) {
                    setState(() {
                      _enableBreakReminder = val;
                    });
                  },
                ),
                Row(
                  children: const [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'تذكير أخذ استراحة',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'تنبيه كل 20 دقيقة مشاهدة متواصلة',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.bedtime_outlined, color: WadiqColors.primaryAmber, size: 22),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
