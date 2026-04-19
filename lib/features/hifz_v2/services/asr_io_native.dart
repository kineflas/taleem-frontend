/// Implémentation native (mobile/desktop) — utilise dart:io.
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Sur mobile, pas de blob URL — retourne null.
Future<Uint8List?> fetchBlobBytes(String blobUrl) async => null;

/// Supprime un fichier temporaire.
Future<void> deleteFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {}
}

/// Retourne un chemin temporaire pour l'enregistrement.
Future<String> getTempRecordingPath() async {
  final dir = await getTemporaryDirectory();
  return '${dir.path}/asr_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
}
