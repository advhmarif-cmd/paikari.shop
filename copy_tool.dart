// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  print('Starting copy...');
  final source = File(
      r'C:\Users\advhm\.gemini\antigravity\brain\3959f8d8-a897-4ed4-8d4a-549b2ccf240d\uploaded_image_1766898263084.jpg');
  final dest = File(r'c:\Users\advhm\paikari.shop\assets\logo.jpg');
  try {
    if (!source.existsSync()) {
      print('Source does not exist!');
      return;
    }
    final bytes = source.readAsBytesSync();
    print('Read ${bytes.length} bytes.');
    dest.writeAsBytesSync(bytes);
    print('Wrote to ${dest.path}');
  } catch (e) {
    print('Error: $e');
  }
}
