import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Madd-O-Meter : Gamification des prolongations coraniques
//
// Utilise le package `record` pour le stream d'amplitude en temps réel.
// Ajouter dans pubspec.yaml :
//   record: ^5.0.4
//   permission_handler: ^11.3.1  (si pas déjà présent)
//
// Usage :
//   MaddOMeter(
//     targetCounts: 2,         // Madd Tabii = 2 harakatain
//     msPerCount: 300,         // ~300ms par harakata à tempo pédagogique
//     letter: 'آ',
//     onResult: (result) => print(result),
//   )
// ─────────────────────────────────────────────────────────────────────────────

enum MaddType {
  tabii,      // 2 harakatain (~600ms)
  munfasil,   // 4 harakatain (~1200ms)
  muttasil,   // 4-5 harakatain (~1200-1500ms)
  lazim,      // 6 harakatain (~1800ms)
}

extension MaddTypeExt on MaddType {
  String get labelFr {
    switch (this) {
      case MaddType.tabii:    return 'Madd Tabii — 2 temps';
      case MaddType.munfasil: return 'Madd Munfasil — 4 temps';
      case MaddType.muttasil: return 'Madd Muttasil — 4-5 temps';
      case MaddType.lazim:    return 'Madd Lazim — 6 temps';
    }
  }

  int get counts {
    switch (this) {
      case MaddType.tabii:    return 2;
      case MaddType.munfasil: return 4;
      case MaddType.muttasil: return 4;
      case MaddType.lazim:    return 6;
    }
  }

  Color get color {
    switch (this) {
      case MaddType.tabii:    return const Color(0xFF2196F3); // bleu
      case MaddType.munfasil: return const Color(0xFF9C27B0); // violet
      case MaddType.muttasil: return const Color(0xFFE91E63); // rose
      case MaddType.lazim:    return const Color(0xFF1B4B82); // primaire
    }
  }
}

class MaddResult {
  final Duration actualDuration;
  final Duration targetDuration;
  final double ratio;          // 1.0 = parfait
  final bool isSuccess;        // ratio entre 0.75 et 1.30
  final String feedback;

  const MaddResult({
    required this.actualDuration,
    required this.targetDuration,
    required this.ratio,
    required this.isSuccess,
    required this.feedback,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal
// ─────────────────────────────────────────────────────────────────────────────

class MaddOMeter extends StatefulWidget {
  final MaddType maddType;
  final String letter;          // Lettre avec voyelle longue (ex: 'آ', 'وْ', 'يْ')
  final int msPerCount;         // ms par harakata (défaut : 300ms)
  final void Function(MaddResult)? onResult;

  const MaddOMeter({
    super.key,
    required this.maddType,
    required this.letter,
    this.msPerCount = 300,
    this.onResult,
  });

  @override
  State<MaddOMeter> createState() => _MaddOMeterState();
}

class _MaddOMeterState extends State<MaddOMeter>
    with TickerProviderStateMixin {

  // ── Audio ──────────────────────────────────────────────────────────────────
  // NOTE: Ces variables sont prêtes pour l'intégration avec le package `record`.
  // StreamSubscription pour l'amplitude sera connectée dans _startRecording().
  StreamSubscription<double>? _amplitudeSubscription;

  // Seuil de détection de voix (en dB normalisé 0.0-1.0).
  // En pratique avec record: amplitude > -30dB = voix détectée.
  static const double _voiceThreshold = 0.15;

  // ── État de l'enregistrement ───────────────────────────────────────────────
  _MeterState _state = _MeterState.idle;
  double _currentAmplitude = 0.0;   // 0.0 - 1.0 normalisé
  bool _isVoiceActive = false;

  // ── Durée ─────────────────────────────────────────────────────────────────
  DateTime? _voiceStart;
  Duration _voiceDuration = Duration.zero;
  Timer? _durationTimer;
  Timer? _autoStopTimer;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _barController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late Animation<double> _pulseAnim;

  // Particles pour l'animation de succès
  final List<_Sparkle> _sparkles = [];
  final _random = math.Random();

  // ── Bruit ambiant ─────────────────────────────────────────────────────────
  double _ambientNoise = 0.0;
  int _ambientSampleCount = 0;
  bool _isCalibrating = false;

  // ── Résultat ──────────────────────────────────────────────────────────────
  MaddResult? _result;

  // ── Computed ──────────────────────────────────────────────────────────────
  Duration get _targetDuration =>
      Duration(milliseconds: widget.maddType.counts * widget.msPerCount);

  double get _progressRatio {
    if (_targetDuration.inMilliseconds == 0) return 0.0;
    return (_voiceDuration.inMilliseconds / _targetDuration.inMilliseconds)
        .clamp(0.0, 1.35); // dépasse légèrement pour signaler "trop long"
  }

  // ─── Zone cible : 75%-125% de la durée cible ─────────────────────────────
  static const double _minRatio = 0.75;
  static const double _maxRatio = 1.25;

  Color get _barColor {
    if (_result != null) {
      return _result!.isSuccess ? const Color(0xFFFFD700) : Colors.red.shade400;
    }
    if (_progressRatio < _minRatio) return widget.maddType.color;
    if (_progressRatio <= _maxRatio) return const Color(0xFF4CAF50);
    return Colors.orange.shade600;
  }

  @override
  void initState() {
    super.initState();

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _calibrateAmbientNoise();
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _durationTimer?.cancel();
    _autoStopTimer?.cancel();
    _barController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Audio : calibration du bruit ambiant
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _calibrateAmbientNoise() async {
    setState(() => _isCalibrating = true);

    // Dans l'implémentation réelle avec le package `record` :
    //
    // final recorder = AudioRecorder();
    // await recorder.start(const RecordConfig(encoder: AudioEncoder.pcm16bits), path: '');
    // await Future.delayed(const Duration(milliseconds: 800));
    // final amplitude = await recorder.getAmplitude();
    // _ambientNoise = _normalizeAmplitude(amplitude.current);
    // await recorder.stop();
    //
    // Pour le moment, on simule une calibration rapide :
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _ambientNoise = 0.05; // bruit ambiant typique en environnement calme
        _isCalibrating = false;
      });
    }
  }

  bool get _isTooNoisy => _ambientNoise > 0.20;

  // ─────────────────────────────────────────────────────────────────────────
  // Enregistrement
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (_isTooNoisy) return;

    setState(() {
      _state = _MeterState.listening;
      _voiceDuration = Duration.zero;
      _voiceStart = null;
      _isVoiceActive = false;
      _result = null;
      _sparkles.clear();
    });

    // ── Intégration `record` (à connecter au vrai stream) ────────────────
    //
    // final recorder = AudioRecorder();
    // final stream = await recorder.startStream(
    //   const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000),
    // );
    //
    // _amplitudeSubscription = stream
    //   .map((chunk) => _rmsFromPcmBytes(chunk))   // RMS → amplitude normalisée
    //   .listen(_onAmplitudeUpdate);
    //
    // Pour le widget autonome, on utilise un stream simulé :
    _amplitudeSubscription = _simulatedAmplitudeStream().listen(_onAmplitudeUpdate);

    // Arrêt automatique après 3× la durée cible (évite un enregistrement infini)
    _autoStopTimer = Timer(
      _targetDuration * 3,
      () {
        if (_state == _MeterState.listening) _stopAndEvaluate();
      },
    );

    // Timer de mise à jour de l'affichage de durée (60fps)
    _durationTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_isVoiceActive && _voiceStart != null) {
        setState(() {
          _voiceDuration = DateTime.now().difference(_voiceStart!);
        });
      }
    });
  }

  void _onAmplitudeUpdate(double amplitude) {
    if (!mounted || _state != _MeterState.listening) return;

    final effectiveAmplitude = (amplitude - _ambientNoise).clamp(0.0, 1.0);
    final isVoice = effectiveAmplitude > _voiceThreshold;

    setState(() => _currentAmplitude = effectiveAmplitude);

    if (isVoice && !_isVoiceActive) {
      // Début de la voix
      _voiceStart = DateTime.now();
      _isVoiceActive = true;
    } else if (!isVoice && _isVoiceActive) {
      // Fin de la voix → évaluer
      _stopAndEvaluate();
    }
  }

  void _stopAndEvaluate() {
    _amplitudeSubscription?.cancel();
    _durationTimer?.cancel();
    _autoStopTimer?.cancel();

    final actual = _voiceStart != null
        ? DateTime.now().difference(_voiceStart!)
        : _voiceDuration;

    final ratio = actual.inMilliseconds / _targetDuration.inMilliseconds;
    final isSuccess = ratio >= _minRatio && ratio <= _maxRatio;

    final feedback = _buildFeedback(ratio, isSuccess);

    final result = MaddResult(
      actualDuration: actual,
      targetDuration: _targetDuration,
      ratio: ratio,
      isSuccess: isSuccess,
      feedback: feedback,
    );

    HapticFeedback.mediumImpact();

    setState(() {
      _state = _MeterState.result;
      _result = result;
      _voiceDuration = actual;
      _isVoiceActive = false;
    });

    if (isSuccess) {
      _launchSparkles();
    }

    widget.onResult?.call(result);
  }

  String _buildFeedback(double ratio, bool isSuccess) {
    if (isSuccess) {
      if (ratio >= 0.90 && ratio <= 1.10) return 'Parfait ! Prolongation exacte 🌟';
      if (ratio < 0.90) return 'Très bien ! Encore un tout petit peu plus long.';
      return 'Très bien ! Essaie d\'être légèrement plus court.';
    }
    if (ratio < _minRatio) {
      return 'Trop court — prolonge le son jusqu\'à la zone dorée.';
    }
    return 'Trop long — arrête-toi quand la barre atteint la zone dorée.';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sparkles (animation de succès)
  // ─────────────────────────────────────────────────────────────────────────

  void _launchSparkles() {
    _sparkles.clear();
    for (var i = 0; i < 18; i++) {
      _sparkles.add(_Sparkle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 4 + _random.nextDouble() * 8,
        angle: _random.nextDouble() * 2 * math.pi,
        speed: 0.5 + _random.nextDouble(),
      ));
    }
    _sparkleController.forward(from: 0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stream simulé (remplacé par le vrai stream audio en production)
  // ─────────────────────────────────────────────────────────────────────────

  Stream<double> _simulatedAmplitudeStream() async* {
    // Simule : silence → voix → silence
    // En production, remplacer par le stream PCM du recorder
    await Future.delayed(const Duration(milliseconds: 500));
    while (_state == _MeterState.listening) {
      // Simule l'amplitude (en prod : RMS du buffer PCM)
      yield 0.0 + _random.nextDouble() * 0.08; // bruit de fond
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Indicateur bruit ambiant ─────────────────────────────────────
        if (_isTooNoisy) _buildNoisyEnvironmentWarning(),

        // ── Lettre cible ─────────────────────────────────────────────────
        _buildLetterDisplay(),

        const SizedBox(height: 24),

        // ── Type de Madd ─────────────────────────────────────────────────
        Text(
          widget.maddType.labelFr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.maddType.color,
          ),
        ),

        const SizedBox(height: 20),

        // ── Barre de progression ─────────────────────────────────────────
        _buildProgressBar(),

        const SizedBox(height: 12),

        // ── Labels durée ─────────────────────────────────────────────────
        _buildDurationLabels(),

        const SizedBox(height: 24),

        // ── Bouton / Feedback ────────────────────────────────────────────
        if (_state == _MeterState.result)
          _buildResultFeedback()
        else
          _buildRecordButton(),

        const SizedBox(height: 16),

        // ── Waveform en temps réel ───────────────────────────────────────
        if (_state == _MeterState.listening)
          _buildWaveform(),
      ],
    );
  }

  Widget _buildLetterDisplay() {
    return ScaleTransition(
      scale: _state == _MeterState.listening ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.maddType.color.withOpacity(0.1),
          border: Border.all(
            color: _isVoiceActive
                ? widget.maddType.color
                : widget.maddType.color.withOpacity(0.3),
            width: _isVoiceActive ? 3 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            widget.letter,
            style: TextStyle(
              fontSize: 52,
              fontFamily: 'Amiri',
              color: widget.maddType.color,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final targetRatio = 1.0 / 1.35; // position de la zone cible sur la barre totale
    final minZone = _minRatio / 1.35;
    final maxZone = _maxRatio / 1.35;

    return Stack(
      children: [
        // Animation sparkles par-dessus la barre
        if (_result?.isSuccess == true)
          AnimatedBuilder(
            animation: _sparkleController,
            builder: (_, __) => CustomPaint(
              size: const Size(double.infinity, 48),
              painter: _SparklePainter(
                sparkles: _sparkles,
                progress: _sparkleController.value,
              ),
            ),
          ),

        // Barre principale
        Container(
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // Track fond
                Container(color: Colors.grey.shade100),

                // Zone cible (dorée)
                Positioned(
                  left: MediaQuery.of(context).size.width * minZone - 48, // offset margin
                  right: MediaQuery.of(context).size.width * (1 - maxZone) - 48,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    color: const Color(0xFFFFD700).withOpacity(0.25),
                  ),
                ),

                // Barre de progression animée
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 80),
                  widthFactor: _progressRatio / 1.35,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _barColor.withOpacity(0.7),
                          _barColor,
                        ],
                      ),
                    ),
                  ),
                ),

                // Ligne cible (1.0×)
                Positioned(
                  left: MediaQuery.of(context).size.width * targetRatio - 48,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2.5,
                    color: const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationLabels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '0s',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          Column(
            children: [
              Text(
                '${(_targetDuration.inMilliseconds / 1000).toStringAsFixed(1)}s',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFD700),
                ),
              ),
              const Text(
                '🎯 cible',
                style: TextStyle(fontSize: 10, color: Color(0xFFFFD700)),
              ),
            ],
          ),
          Text(
            '${((_targetDuration.inMilliseconds * 1.35) / 1000).toStringAsFixed(1)}s',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    final isListening = _state == _MeterState.listening;

    return GestureDetector(
      onTap: _isTooNoisy
          ? null
          : isListening
              ? _stopAndEvaluate
              : _startRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isListening ? 72 : 64,
        height: isListening ? 72 : 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isTooNoisy
              ? Colors.grey.shade300
              : isListening
                  ? Colors.red.shade400
                  : widget.maddType.color,
          boxShadow: [
            BoxShadow(
              color: (isListening ? Colors.red : widget.maddType.color)
                  .withOpacity(0.3),
              blurRadius: isListening ? 20 : 10,
              spreadRadius: isListening ? 4 : 0,
            ),
          ],
        ),
        child: Icon(
          isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildResultFeedback() {
    final result = _result!;

    return Column(
      children: [
        // Emoji résultat
        Text(
          result.isSuccess ? '🌟' : (result.ratio < _minRatio ? '⏱️' : '🛑'),
          style: const TextStyle(fontSize: 40),
        ),

        const SizedBox(height: 8),

        // Feedback texte
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            result.feedback,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: result.isSuccess
                  ? const Color(0xFF2E7D32)
                  : Colors.orange.shade800,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 6),

        // Durée réelle vs cible
        Text(
          '${(result.actualDuration.inMilliseconds / 1000).toStringAsFixed(2)}s '
          '/ ${(result.targetDuration.inMilliseconds / 1000).toStringAsFixed(2)}s cible',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 20),

        // Bouton réessayer
        GestureDetector(
          onTap: () {
            setState(() {
              _state = _MeterState.idle;
              _result = null;
              _voiceDuration = Duration.zero;
              _sparkles.clear();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              color: widget.maddType.color,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'Réessayer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 48,
      child: CustomPaint(
        painter: _WaveformPainter(
          amplitude: _currentAmplitude,
          color: _isVoiceActive ? widget.maddType.color : Colors.grey.shade300,
        ),
        size: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _buildNoisyEnvironmentWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_off, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Trop de bruit ambiant — isole-toi un peu pour une détection précise.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// État interne
// ─────────────────────────────────────────────────────────────────────────────

enum _MeterState { idle, calibrating, listening, result }

// ─────────────────────────────────────────────────────────────────────────────
// Modèle Sparkle
// ─────────────────────────────────────────────────────────────────────────────

class _Sparkle {
  final double x;      // position relative 0.0-1.0
  final double y;
  final double size;
  final double angle;  // direction de déplacement
  final double speed;

  const _Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.angle,
    required this.speed,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter : Sparkles
// ─────────────────────────────────────────────────────────────────────────────

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double progress; // 0.0 → 1.0

  const _SparklePainter({required this.sparkles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final s in sparkles) {
      final fade = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = const Color(0xFFFFD700).withOpacity(fade * 0.9);

      final dx = s.x * size.width + math.cos(s.angle) * progress * 50 * s.speed;
      final dy = s.y * size.height + math.sin(s.angle) * progress * 50 * s.speed;
      final currentSize = s.size * (1.0 - progress * 0.5);

      canvas.drawCircle(Offset(dx, dy), currentSize, paint);

      // Petite étoile à 4 branches
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(fade * 0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(dx - currentSize, dy),
        Offset(dx + currentSize, dy),
        starPaint,
      );
      canvas.drawLine(
        Offset(dx, dy - currentSize),
        Offset(dx, dy + currentSize),
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter : Waveform en temps réel
// ─────────────────────────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final double amplitude; // 0.0-1.0
  final Color color;

  const _WaveformPainter({required this.amplitude, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    const bars = 32;
    final barWidth = size.width / bars;

    path.moveTo(0, cy);
    for (var i = 0; i < bars; i++) {
      final x = i * barWidth + barWidth / 2;
      // Enveloppe en cloche centrée
      final envelope = math.sin((i / bars) * math.pi);
      final h = amplitude * envelope * cy * 0.8;
      canvas.drawLine(
        Offset(x, cy - h),
        Offset(x, cy + h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.amplitude != amplitude || old.color != color;
}
