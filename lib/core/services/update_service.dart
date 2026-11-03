import 'package:flutter/material.dart';
import '../../core/theme/wadiq_colors.dart';
import 'wadiq_api_service.dart';
import 'apk_installer.dart';

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const int currentVersionCode = 3;
  static const String currentVersionName = "1.0.3";

  bool _isChecking = false;

  Future<void> checkForUpdate(BuildContext context, {bool silent = true}) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final info = await WadiqApiService.instance.checkAppVersion();
      _isChecking = false;

      if (!context.mounted) return;

      if (info != null && info['ok'] == true) {
        final int remoteCode = (info['versionCode'] as num?)?.toInt() ?? 0;
        final String latestVersion = info['latestVersion']?.toString() ?? '1.0.2';
        final String notes = info['releaseNotes']?.toString() ?? 'تحسينات عامة على الأداء وإصلاحات.';
        final String downloadUrl = info['downloadUrl']?.toString() ??
            'https://github.com/Cesarhassanein/3343/releases/latest/download/app-release.apk';
        final bool isForced = info['isForced'] == true;

        if (remoteCode > currentVersionCode) {
          final bool hasApk = info['hasApk'] == true;
          final bool hasValidUrl = downloadUrl.isNotEmpty && downloadUrl.startsWith('http');
          
          // إذا لم يتوفر ملف الـ APK بعد، لا يظهر إشعار التحديث للمستخدمين منعاً لخطأ التحميل
          if (!hasApk && !hasValidUrl) {
            return;
          }

          _showUpdateDialog(
            context,
            latestVersion: latestVersion,
            notes: notes,
            downloadUrl: downloadUrl,
            isForced: isForced,
          );
          return;
        }
      }

      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("أنت تستخدم أحدث إصدار من تطبيق ودق ($currentVersionName) ✓"),
            backgroundColor: WadiqColors.primaryAmber,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      _isChecking = false;
    }
  }

  void _showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String notes,
    required String downloadUrl,
    required bool isForced,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (ctx) {
        double downloadProgress = 0.0;
        bool isDownloading = false;
        String statusText = "تحديث الآن (تنزيل وتثبيت)";

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: WadiqColors.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: WadiqColors.primaryAmber, width: 1.2),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: WadiqColors.amberGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.system_update_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "تحديث جديد متوفر! 🚀",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "الإصدار الجديد: $latestVersion",
                          style: const TextStyle(color: WadiqColors.primaryAmber, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ما الجديد في هذا الإصدار:",
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WadiqColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WadiqColors.surfaceBorder, width: 0.8),
                    ),
                    child: Text(
                      notes,
                      style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
                    ),
                  ),
                  if (isDownloading) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: downloadProgress > 0 ? downloadProgress : null,
                        backgroundColor: WadiqColors.elevatedSurface,
                        valueColor: const AlwaysStoppedAnimation<Color>(WadiqColors.primaryAmber),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        downloadProgress > 0
                            ? "جاري التحميل والتجهيز... ${(downloadProgress * 100).toInt()}%"
                            : "جاري بدء التحميل...",
                        style: const TextStyle(color: WadiqColors.primaryAmber, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isForced && !isDownloading)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text("لاحقاً", style: TextStyle(color: Colors.white54)),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WadiqColors.primaryAmber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isDownloading
                      ? null
                      : () async {
                          setDialogState(() {
                            isDownloading = true;
                            statusText = "جاري التحميل...";
                          });

                          final success = await ApkInstaller.install(
                            downloadUrl,
                            onProgress: (p) {
                              setDialogState(() {
                                downloadProgress = p;
                              });
                            },
                          );

                          if (!success && dialogCtx.mounted) {
                            setDialogState(() {
                              isDownloading = false;
                              statusText = "إعادة المحاولة";
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("تعذر تثبيت التحديث تلقائياً، يمكنك التحميل من الرابط المباشر."),
                                backgroundColor: WadiqColors.cardSurface,
                              ),
                            );
                          }
                        },
                  child: Text(
                    statusText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
