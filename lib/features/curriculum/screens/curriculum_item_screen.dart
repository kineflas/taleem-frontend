import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../models/curriculum_model.dart';
import '../providers/curriculum_provider.dart';

/// Full lesson view — shows Arabic content, French explanation, transliteration.
/// Has "J'ai appris" button and submission sheet.
/// Route: /student/curriculum/:enrollmentId/item/:itemId
class CurriculumItemScreen extends ConsumerStatefulWidget {
  final String enrollmentId;
  final String itemId;

  const CurriculumItemScreen({
    super.key,
    required this.enrollmentId,
    required this.itemId,
  });

  @override
  ConsumerState<CurriculumItemScreen> createState() => _CurriculumItemScreenState();
}

class _CurriculumItemScreenState extends ConsumerState<CurriculumItemScreen> {
  bool _completed = false;
  int _selectedMastery = 2; // default: practiced
  bool _loading = false;
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String audioUrl) async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
      return;
    }
    try {
      final fullUrl = '${ApiConstants.baseUrl}$audioUrl';
      setState(() => _isPlaying = true);
      await _audioPlayer.play(UrlSource(fullUrl));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (e) {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _markComplete() async {
    setState(() => _loading = true);
    try {
      await ref.read(curriculumApiProvider).completeItem(
        widget.itemId,
        enrollmentId: widget.enrollmentId,
        masteryLevel: _selectedMastery,
      );
      ref.invalidate(enrollmentProgressProvider(widget.enrollmentId));
      setState(() => _completed = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Élément marqué comme appris ✅'),
            backgroundColor: AppColors.success,
          ),
        );
        // Short delay then navigate back
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSubmissionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SubmissionSheet(
        enrollmentId: widget.enrollmentId,
        itemId: widget.itemId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(curriculumItemProvider(widget.itemId));

    return itemAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (item) => _buildContent(item),
    );
  }

  Widget _buildContent(CurriculumItem item) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          item.titleFr ?? item.titleAr,
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none),
            onPressed: _showSubmissionSheet,
            tooltip: 'Envoyer un enregistrement',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Arabic content card ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Main Arabic title
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      item.titleAr,
                      style: TextStyle(
                        fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                        fontSize: 48,
                        height: 1.6,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  if (item.transliteration != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '[${item.transliteration}]',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.accent,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  if (item.titleFr != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.titleFr!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // Letter position badge (for alphabet items)
                  if (item.letterPosition != null) ...[
                    const SizedBox(height: 12),
                    _PositionBadge(position: item.letterPosition!),
                  ],

                  // Audio play button
                  if (item.audioUrl != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPlaying
                            ? AppColors.accent
                            : AppColors.primary.withOpacity(0.1),
                        foregroundColor:
                            _isPlaying ? Colors.white : AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: () => _playAudio(item.audioUrl!),
                      icon: Icon(
                        _isPlaying ? Icons.stop : Icons.volume_up,
                        size: 22,
                      ),
                      label: Text(
                        _isPlaying ? 'Arrêter' : 'Écouter',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Arabic body content (rules, examples) ────────────────────
            if (item.contentAr != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    right: BorderSide(color: AppColors.primary, width: 4),
                  ),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    item.contentAr!,
                    style: TextStyle(
                      fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                      fontSize: 20,
                      height: 1.8,
                    ),
                  ),
                ),
              ),

            // ── French explanation ────────────────────────────────────────
            if (item.contentFr != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _contentLabel(item.itemType),
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.contentFr!,
                      style: TextStyle(fontSize: 15, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],

            // ── Metadata pills (for Tajwid — letters concerned) ──────────
            if (item.metadata != null && item.metadata!['letters'] != null) ...[
              const SizedBox(height: 16),
              _LetterPills(letters: List<String>.from(item.metadata!['letters'])),
            ],

            // ── Surah reference (Hifz) ────────────────────────────────────
            if (item.surahNumber != null) ...[
              const SizedBox(height: 16),
              _SurahReference(
                surahNumber: item.surahNumber!,
                verseStart: item.verseStart,
                verseEnd: item.verseEnd,
              ),
            ],

            const SizedBox(height: 32),

            // ── Mastery selector ──────────────────────────────────────────
            if (!_completed) ...[
              Text(
                'Niveau de maîtrise',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              _MasterySelector(
                selected: _selectedMastery,
                onChanged: (v) => setState(() => _selectedMastery = v),
              ),
              const SizedBox(height: 16),
            ],

            // ── Action button ─────────────────────────────────────────────
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _completed ? AppColors.success : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _completed || _loading ? null : _markComplete,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(
                        _completed ? Icons.check_circle : Icons.done_all,
                        color: Colors.white,
                      ),
                label: Text(
                  _completed ? 'Appris ✅' : "J'ai appris !",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Submission button ─────────────────────────────────────────
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _showSubmissionSheet,
              icon: Icon(Icons.mic, color: AppColors.primary),
              label: Text(
                'Envoyer un enregistrement',
                style: TextStyle(color: AppColors.primary, fontSize: 15),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _contentLabel(ItemType type) {
    switch (type) {
      case ItemType.rule: return 'Règle';
      case ItemType.vocabulary: return 'Vocabulaire';
      case ItemType.grammarPoint: return 'Grammaire';
      case ItemType.example: return 'Exemple';
      case ItemType.combination: return 'Combinaison';
      default: return 'Explication';
    }
  }
}

class _PositionBadge extends StatelessWidget {
  final String position;
  const _PositionBadge({required this.position});

  String get label {
    switch (position) {
      case 'isolated': return 'Isolée';
      case 'initial': return 'Initiale';
      case 'medial': return 'Médiane';
      case 'final': return 'Finale';
      default: return position;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _LetterPills extends StatelessWidget {
  final List<String> letters;
  const _LetterPills({required this.letters});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: letters.map((l) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          l,
          style: TextStyle(
            fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
            fontSize: 22,
            color: AppColors.primary,
          ),
          textDirection: TextDirection.rtl,
        ),
      )).toList(),
    );
  }
}

class _SurahReference extends StatelessWidget {
  final int surahNumber;
  final int? verseStart;
  final int? verseEnd;

  const _SurahReference({
    required this.surahNumber,
    this.verseStart,
    this.verseEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_stories, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sourate $surahNumber',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (verseStart != null)
                Text(
                  'Versets $verseStart – ${verseEnd ?? verseStart}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MasterySelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _MasterySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = ['Vu', 'Pratiqué', 'Maîtrisé'];
    final colors = [Colors.grey, AppColors.accent, AppColors.success];

    return Row(
      children: List.generate(3, (i) {
        final level = i + 1;
        final isSelected = selected == level;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors[i].withOpacity(0.15) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? colors[i] : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(level, (_) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? colors[i] : Colors.grey[400],
                      ),
                    )),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? colors[i] : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Submission Bottom Sheet ────────────────────────────────────────────────

class _SubmissionSheet extends ConsumerStatefulWidget {
  final String enrollmentId;
  final String itemId;

  const _SubmissionSheet({required this.enrollmentId, required this.itemId});

  @override
  ConsumerState<_SubmissionSheet> createState() => _SubmissionSheetState();
}

class _SubmissionSheetState extends ConsumerState<_SubmissionSheet> {
  final _noteController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await ref.read(curriculumApiProvider).createSubmission(
        enrollmentId: widget.enrollmentId,
        curriculumItemId: widget.itemId,
        textContent: _noteController.text.isNotEmpty ? _noteController.text : null,
      );
      ref.invalidate(mySubmissionsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Soumission envoyée à votre enseignant 🎤'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Envoyer un enregistrement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre enseignant recevra votre soumission et pourra vous donner un retour.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Audio placeholder (future feature)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, color: AppColors.primary, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enregistrement audio',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Bientôt disponible',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Text note
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Note facultative pour votre enseignant...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Envoyer',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
