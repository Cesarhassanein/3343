import 'package:flutter/material.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/services/reels_settings_service.dart';

class ReelsContentPreferencesScreen extends StatefulWidget {
  const ReelsContentPreferencesScreen({super.key});

  @override
  State<ReelsContentPreferencesScreen> createState() => _ReelsContentPreferencesScreenState();
}

class _ReelsContentPreferencesScreenState extends State<ReelsContentPreferencesScreen> {
  final _service = ReelsSettingsService.instance;
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _muteController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    _muteController.dispose();
    super.dispose();
  }

  void _showAddKeywordDialog() {
    _keywordController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WadiqColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'إضافة كلمة لتصفية المحتوى',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'لن تظهر المقاطع التي تحتوي على هذه الكلمة في موجز الريلز الخاص بك.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keywordController,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'مثال: رعب، مقالب...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: WadiqColors.obsidianBlack,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: WadiqColors.primaryAmber)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WadiqColors.primaryAmber,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (_keywordController.text.trim().isNotEmpty) {
                _service.addFeedKeyword(_keywordController.text.trim());
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إضافة الكلمة للتصفية بنجاح')),
                );
              }
            },
            child: const Text('إضافة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMuteAccountDialog() {
    _muteController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WadiqColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'كتم حساب من الريلز',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'أدخل اسم المستخدم (بدون @) لإخفاء مقاطعه من الظهور لك:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _muteController,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'اسم المستخدم...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: WadiqColors.obsidianBlack,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: WadiqColors.primaryAmber)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WadiqColors.primaryAmber,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (_muteController.text.trim().isNotEmpty) {
                _service.muteAccount(_muteController.text.trim());
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم كتم الحساب بنجاح')),
                );
              }
            },
            child: const Text('كتم', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
              'تفضيلات المحتوى الخاصة بالريلز',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Study Mode Toggle
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      WadiqColors.primaryAmber.withValues(alpha: 0.15),
                      WadiqColors.cardSurface,
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _service.isStudyModeEnabled ? WadiqColors.primaryAmber : Colors.white12,
                    width: _service.isStudyModeEnabled ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Switch.adaptive(
                      value: _service.isStudyModeEnabled,
                      activeColor: WadiqColors.primaryAmber,
                      onChanged: (val) {
                        _service.setStudyMode(val);
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: const [
                              Text(
                                'صفحة الدراسة (الوضع التعليمي)',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.school, color: WadiqColors.primaryAmber, size: 20),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'تفعيل موجز مخصص يركز حصراً على المحتوى الأكاديمي، شروحات المواد، والريلز التعليمية الهادفة.',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Feed Keywords Filter
              Container(
                margin: const EdgeInsets.only(bottom: 20),
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
                        IconButton(
                          onPressed: _showAddKeywordDialog,
                          icon: const Icon(Icons.add_circle, color: WadiqColors.primaryAmber, size: 24),
                          tooltip: 'إضافة كلمة',
                        ),
                        Row(
                          children: const [
                            Text(
                              'تصفية كلمات محددة من الموجز',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.filter_list, color: WadiqColors.primaryAmber, size: 20),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'المقاطع التي تحتوي على هذه الكلمات في الوصف لن تظهر في خلاصتك:',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 14),
                    if (_service.feedFilteredKeywords.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'لم تتم إضافة أي كلمات محظورة بعد',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: _service.feedFilteredKeywords.map((kw) {
                          return Chip(
                            backgroundColor: WadiqColors.obsidianBlack,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Colors.white24),
                            ),
                            label: Text(kw, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            deleteIcon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                            onDeleted: () => _service.removeFeedKeyword(kw),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              // 3. Muted Accounts
              Container(
                margin: const EdgeInsets.only(bottom: 20),
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
                        IconButton(
                          onPressed: _showMuteAccountDialog,
                          icon: const Icon(Icons.person_add_disabled, color: WadiqColors.primaryAmber, size: 24),
                          tooltip: 'كتم حساب',
                        ),
                        Row(
                          children: const [
                            Text(
                              'الحسابات المكتومة',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.volume_off, color: Colors.orangeAccent, size: 20),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'الحسابات التي قمت بكتمها ولن تظهر مقاطعها في ريلزك:',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    if (_service.mutedAccounts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'لا توجد حسابات مكتومة حالياً',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _service.mutedAccounts.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                        itemBuilder: (ctx, idx) {
                          final account = _service.mutedAccounts[idx];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white12,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                _service.unmuteAccount(account);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تم إلغاء كتم @$account')),
                                );
                              },
                              child: const Text('إلغاء الكتم', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                            title: Text(
                              '@$account',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.right,
                            ),
                            trailing: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white10,
                              child: Icon(Icons.person, color: Colors.white70, size: 20),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
