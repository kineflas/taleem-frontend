/// Web implementation — triggers a hard browser reload.
import 'dart:js_interop';

@JS('window.location.reload')
external void _jsReload();

void reloadApp() => _jsReload();
