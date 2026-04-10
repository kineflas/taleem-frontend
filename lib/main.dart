import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization (skip if no google-services.json yet)
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured yet — FCM will not work
    debugPrint('Firebase not configured. Push notifications disabled.');
  }

  runApp(
    const ProviderScope(
      child: TaliemApp(),
    ),
  );
}
