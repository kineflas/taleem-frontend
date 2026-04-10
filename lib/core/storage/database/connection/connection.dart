import 'package:drift/drift.dart';

// Conditional import: native on mobile/desktop, stub on web
import 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart';

QueryExecutor openAppDatabase() => getExecutor();
