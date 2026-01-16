import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paikari_shop/firebase_options.dart';

class FirebaseDebugPage extends StatelessWidget {
  const FirebaseDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    final options = DefaultFirebaseOptions.currentPlatform;
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Platform: \\$defaultTargetPlatform'),
            const SizedBox(height: 8),
            Text('API Key: \\${options.apiKey}'),
            const SizedBox(height: 8),
            Text('App ID: \\${options.appId}'),
            const SizedBox(height: 8),
            Text('Project ID: \\${options.projectId}'),
            const SizedBox(height: 8),
            Text('Storage Bucket: \\${options.storageBucket}'),
            const SizedBox(height: 16),
            const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('- Ensure SHA keys registered for Android release.'),
            const Text(
                '- Ensure Google/Facebook sign-in configured in Firebase console.'),
            const Text(
                '- For web phone auth, recaptcha container must exist in index.html.'),
          ],
        ),
      ),
    );
  }
}
