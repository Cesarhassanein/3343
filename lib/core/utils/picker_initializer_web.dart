import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void initImagePickerPlatform() {
  try {
    ImagePickerPlugin.registerWith(webPluginRegistrar);
  } catch (_) {}
  try {
    ImagePickerPlatform.instance = ImagePickerPlugin();
  } catch (_) {}
}
