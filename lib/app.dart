import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/shared/widgets/offline_banner.dart';
import 'features/shared/widgets/version_banner.dart';

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

    // On web: layer version-update banner + offline overlay
    if (kIsWeb) {
      return ProviderScope(
        child: VersionUpdateBanner(
          child: WebOfflineOverlay(child: app),
        ),
      );
    }

    return app;
  }
}
