import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/version_check_provider.dart';
import '../../../core/utils/platform_utils.dart';

/// A dismissable banner that slides in at the top of the screen when a new
/// app version has been deployed. Clicking "Recharger" calls
/// window.location.reload() so the browser fetches the new build.
class VersionUpdateBanner extends ConsumerWidget {
  final Widget child;
  const VersionUpdateBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAvailable = ref.watch(versionCheckProvider);

    return Column(
      children: [
        if (updateAvailable) _UpdateBannerTile(),
        Expanded(child: child),
      ],
    );
  }
}

class _UpdateBannerTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A237E), // deep indigo — distinct from app chrome
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.system_update_alt_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Nouvelle version disponible — rechargez pour mettre à jour',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: reloadApp,
                child: const Text(
                  'Recharger',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
