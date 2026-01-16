import 'dart:convert';
import 'dart:io';

void main() {
  // A simple 1x1 pixel blue PNG
  const base64Image =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPj/HwADBwIAMCb5xwAAAABJRU5ErkJggg==';
  // Actually let's use a bigger one if possible, but 1x1 is enough to stop the crash.
  // Let's use a slightly larger one, 100x100 blue.
  // I'll stick to the 1x1 blue pixel for safety of the string length, creating a valid file is the priority.
  // The user can replace it later.
  // Wait, I can try to make it look like a logo?
  // No, just get the file there.

  final bytes = base64Decode(base64Image);
  final file = File('assets/logo.jpg');
  if (!file.parent.existsSync()) {
    file.parent.createSync(recursive: true);
  }
  file.writeAsBytesSync(bytes);
  // print('Created assets/logo.jpg');
}
