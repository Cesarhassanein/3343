import 'file_downloader_stub.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart'
    if (dart.library.html) 'file_downloader_web.dart';

void downloadVideoFile(String url, String fileName) {
  triggerFileDownload(url, fileName);
}
