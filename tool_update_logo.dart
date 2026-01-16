// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  try {
    const sourcePath =
        r'C:\Users\advhm\.gemini\antigravity\brain\3959f8d8-a897-4ed4-8d4a-549b2ccf240d\uploaded_image_1766898263084.jpg';
    const destPath = r'c:\Users\advhm\paikari.shop\assets\logo.jpg';

    final source = File(sourcePath);
    final dest = File(destPath);

    if (!source.existsSync()) {
      print('Error: Source file not found at $sourcePath');
      return;
    }

    if (!dest.parent.existsSync()) {
      dest.parent.createSync(recursive: true);
    }

    source.copySync(dest.path);
    print('SUCCESS: Updated logo from uploaded image.');
  } catch (e) {
    print('ERROR: $e');
  }
}
