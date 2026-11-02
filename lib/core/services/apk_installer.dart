import 'apk_installer_stub.dart'
    if (dart.library.io) 'apk_installer_io.dart' as impl;

class ApkInstaller {
  static Future<bool> install(String url, {Function(double progress)? onProgress}) {
    return impl.installDownloadedApk(url, onProgress: onProgress);
  }
}
