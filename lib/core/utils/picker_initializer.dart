import 'picker_initializer_stub.dart'
    if (dart.library.js_interop) 'picker_initializer_web.dart'
    if (dart.library.html) 'picker_initializer_web.dart';

void setupImagePicker() {
  initImagePickerPlatform();
}
