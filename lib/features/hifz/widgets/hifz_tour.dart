import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ── SpotlightTour ────────────────────────────────────────────────────────────
/// Système de tutoriel par spotlight :
///   1. Superpose un overlay semi-transparent avec un "trou" au-dessus du widget cible.
///   2. Affiche un tooltip avec titre + description + bouton Suivant/Terminer.
///   3. Navigue séquentiellement dans les étapes.
///
/// Usage:
/// ```dart
/// final tour = SpotlightTour(steps: [...]);
/// tour.start(context);
/// ```

class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final String emoji;
  /// Alignement du tooltip par rapport au spotlight (top = au-dessus, bottom = en dessous)
  final TooltipPosition position;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.emoji = '👆',
    this.position = TooltipPosition.bottom,
  });
}

enum TooltipPosition { top, bottom }

class SpotlightTour {
  final List<TourStep> steps;
  final VoidCallback? onComplete;

  SpotlightTour({required this.steps, this.onComplete});

  int _currentStep = 0;
  OverlayEntry? _overlay;

  void start(BuildContext context) {
    _currentStep = 0;
    _show(context);
  }

  void _show(BuildContext context) {
    _overlay?.remove();
    _overlay = null;

    if (_currentStep >= steps.length) {
      onComplete?.call();
      return;
    }

    final step = steps[_currentStep];
    final renderBox =
        step.targetKey.currentContext?.findRenderObject() as RenderBox?;

    Rect? spotRect;
    if (renderBox != null && renderBox.attached) {
      final offset = renderBox.localToGlobal(Offset.zero);
      spotRect = offset & renderBox.size;
    }

    _overlay = OverlayEntry(
      builder: (_) => _SpotlightOverlay(
        step: step,
        stepIndex: _currentStep,
        totalSteps: steps.length,
        spotRect: spotRect,
        onNext: () {
          _currentStep++;
          _show(context);
        },
        onSkip: () {
          _overlay?.remove();
          _overlay = null;
          onComplete?.call();
        },
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  void dismiss() {
    _overlay?.remove();
    _overlay = null;
  }
}

// ── Overlay widget ─────────────────────────────────────────────────────────────

class _SpotlightOverlay extends StatefulWidget {
  final TourStep step;
  final int stepIndex;
  final int totalSteps;
  final Rect? spotRect;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _SpotlightOverlay({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.spotRect,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<_SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<_SpotlightOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final spot = widget.spotRect;

    return FadeTransition(
      opacity: _fadeIn,
      child: Stack(
        children: [
          // Dim background with spotlight cut-out
          CustomPaint(
            size: screen,
            painter: spot != null
                ? _SpotlightPainter(spotRect: spot.inflate(8))
                : _SpotlightPainter(spotRect: null),
          ),

          // Tap outside to dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onSkip,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),

          // Tooltip card
          if (spot != null)
            _buildTooltip(context, spot, screen)
          else
            _buildCenteredTooltip(context, screen),

          // Step dots + skip button at bottom
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _buildStepIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip(BuildContext context, Rect spot, Size screen) {
    final isBottom = widget.step.position == TooltipPosition.bottom;
    final cardWidth = screen.width - 48;

    double top;
    if (isBottom) {
      top = spot.bottom + 16;
      if (top + 180 > screen.height - 80) {
        top = spot.top - 196;
      }
    } else {
      top = spot.top - 196;
      if (top < 60) top = spot.bottom + 16;
    }

    final left = ((screen.width - cardWidth) / 2).clamp(16.0, screen.width - cardWidth - 16);

    return Positioned(
      left: left,
      top: top,
      width: cardWidth,
      child: _TooltipCard(
        step: widget.step,
        stepIndex: widget.stepIndex,
        totalSteps: widget.totalSteps,
        onNext: widget.onNext,
        onSkip: widget.onSkip,
      ),
    );
  }

  Widget _buildCenteredTooltip(BuildContext context, Size screen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _TooltipCard(
          step: widget.step,
          stepIndex: widget.stepIndex,
          totalSteps: widget.totalSteps,
          onNext: widget.onNext,
          onSkip: widget.onSkip,
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.totalSteps, (i) {
        final isActive = i == widget.stepIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Tooltip card ────────────────────────────────────────────────────────────────

class _TooltipCard extends StatelessWidget {
  final TourStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TooltipCard({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = stepIndex == totalSteps - 1;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {}, // absorb taps so card doesn't dismiss overlay
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: emoji + step counter
              Row(
                children: [
                  Text(step.emoji, style: const TextStyle(fontSize: 28)),
                  const Spacer(),
                  Text(
                    '${stepIndex + 1}/$totalSteps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                step.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                step.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),

              // Actions row
              Row(
                children: [
                  // Skip
                  if (!isLast)
                    GestureDetector(
                      onTap: onSkip,
                      child: Text(
                        'Passer',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  const Spacer(),

                  // Next / Done
                  GestureDetector(
                    onTap: isLast ? onSkip : onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B4B82), Color(0xFF2E7BC4)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        isLast ? 'Terminer ✓' : 'Suivant →',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom painter: spotlight dim ───────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect? spotRect;

  const _SpotlightPainter({this.spotRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.72);

    if (spotRect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(spotRect!, const Radius.circular(12));

    final path = Path()
      ..addRect(fullRect)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Subtle glow ring around spotlight
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, glowPaint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.spotRect != spotRect;
}

// ── SharedPreferences helpers ───────────────────────────────────────────────────

class TourPrefs {
  static const _hubKey = 'hifz_hub_tour_done';
  static const _sessionKey = 'hifz_session_tour_done';

  static Future<bool> isHubTourDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hubKey) ?? false;
  }

  static Future<void> markHubTourDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hubKey, true);
  }

  static Future<bool> isSessionTourDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionKey) ?? false;
  }

  static Future<void> markSessionTourDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
  }

  /// Reset all tours (for debug / testing)
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hubKey);
    await prefs.remove(_sessionKey);
  }
}
