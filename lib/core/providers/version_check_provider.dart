import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Version check — polls /version.json every 5 minutes.
//
// Strategy:
//   1. On first load, fetch /version.json → store as the "current" version.
//   2. Every 5 min, fetch again. If the value changed, a new build was deployed.
//   3. Expose [updateAvailable] = true so the UI can show a reload banner.
//
// The JSON file is generated at Docker build time with the git short hash
// (or a timestamp fallback), so any new deployment changes the value.
// ─────────────────────────────────────────────────────────────────────────────

class VersionCheckNotifier extends Notifier<bool> {
  Timer? _timer;
  String? _baseline; // version seen on first load
  static const _interval = Duration(minutes: 5);

  @override
  bool build() {
    // Only active on web builds
    if (!kIsWeb) return false;

    ref.onDispose(() {
      _timer?.cancel();
    });

    // Kick off the initial fetch + start polling
    Future.microtask(_init);
    return false;
  }

  Future<void> _init() async {
    _baseline = await _fetchVersion();
    _timer = Timer.periodic(_interval, (_) => _check());
  }

  Future<void> _check() async {
    final latest = await _fetchVersion();
    if (latest != null && _baseline != null && latest != _baseline) {
      state = true; // triggers banner
    }
  }

  Future<String?> _fetchVersion() async {
    try {
      // Resolve /version.json relative to the page origin.
      // Uri.base is the current page URL on web.
      final origin = Uri.base.origin;
      final url = '$origin/version.json';
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        // Bust cache so we always get the latest version
        headers: {'Cache-Control': 'no-cache, no-store'},
      ));
      final response = await dio.get<Map<String, dynamic>>(url);
      return response.data?['version'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Trigger a manual check immediately (e.g. on app resume).
  Future<void> forceCheck() => _check();
}

final versionCheckProvider = NotifierProvider<VersionCheckNotifier, bool>(
  VersionCheckNotifier.new,
);
