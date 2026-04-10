import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/shared/widgets/offline_banner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TaliemApp extends ConsumerWidget {
  const TaliemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final app = MaterialApp.router(
      title: 'Taliem',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('ar', 'SA'),
      ],
      locale: const Locale('fr', 'FR'),
    );

    // Wrap web app with offline overlay
    if (kIsWeb) {
      return ProviderScope(
        child: WebOfflineOverlay(child: app),
      );
    }

    return app;
  }
}
