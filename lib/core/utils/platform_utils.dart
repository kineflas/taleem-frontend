/// Platform utilities — conditional import selects the right implementation.
///
/// On Flutter web  : calls window.location.reload() via dart:js_interop
/// On mobile/desktop: no-op
export 'platform_utils_stub.dart'
    if (dart.library.js_interop) 'platform_utils_web.dart';
