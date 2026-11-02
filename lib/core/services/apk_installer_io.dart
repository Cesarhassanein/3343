import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

Future<bool> installDownloadedApk(String url, {Function(double progress)? onProgress}) async {
  try {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);

    if (response.statusCode != 200) return false;

    final contentLength = response.contentLength ?? 0;
    final file = File('${Directory.systemTemp.path}/wadiq_update.apk');
    if (await file.exists()) {
      await file.delete();
    }

    final sink = file.openWrite();
    int downloaded = 0;

    await for (final chunk in response.stream) {
      sink.add(chunk);
      downloaded += chunk.length;
      if (contentLength > 0 && onProgress != null) {
        onProgress(downloaded / contentLength);
      }
    }

    await sink.flush();
    await sink.close();

    // Trigger Android Package Installer via native MethodChannel
    const channel = MethodChannel('com.wadiq.app/installer');
    final result = await channel.invokeMethod<bool>('installApk', {'filePath': file.path});
    return result == true;
  } catch (_) {
    return false;
  }
}
