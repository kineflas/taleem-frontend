/// Implémentation web — utilise dart:html pour fetch les blob URLs.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Récupère les bytes d'un blob URL via XHR natif du navigateur.
Future<Uint8List?> fetchBlobBytes(String blobUrl) async {
  try {
    final request = await html.HttpRequest.request(
      blobUrl,
      responseType: 'arraybuffer',
    );
    final buffer = request.response as ByteBuffer;
    return buffer.asUint8List();
  } catch (e) {
    // ignore: avoid_print
    print('ASR web: Erreur fetch blob: $e');
    return null;
  }
}

/// Sur web, pas de fichier à supprimer.
Future<void> deleteFile(String path) async {}

/// Sur web, pas de chemin temporaire — l'enregistrement est en mémoire.
Future<String> getTempRecordingPath() async => '';
