import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/teacher_provider.dart';
import '../../auth/models/user_model.dart';
import '../../shared/models/task_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/arabic_text.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  final String? preselectedStudentId;
  const CreateTaskScreen({super.key, this.preselectedStudentId});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  int _step = 0;
  String? _selectedStudentId;
  TaskPillar? _pillar;
  TaskType? _taskType;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String _repeatType = 'NONE';

  // Quran fields
  SurahModel? _surah;
  int? _verseStart;
  int? _verseEnd;
  bool _verseStartSuggested = false;

  // Arabic fields
  BookRef? _bookRef;
  int? _chapterNumber;
  int? _pageStart;
  int? _pageEnd;

  final _descCtrl = TextEditingController();
  final _chapterTitleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedStudentId != null) {
      _selectedStudentId = widget.preselectedStudentId;
      _step = 1;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _chapterTitleCtrl.dispose();
    super.dispose();
  }

  void _loadQuranContinuity() async {
    if (_selectedStudentId == null || _pillar != TaskPillar.quran) return;
    final lastTask = await ref.read(quranLastTaskProvider(_selectedStudentId!).future);
    if (lastTask == null || !mounted) return;

    final lastSurahNum = lastTask.surahNumber;
    final lastVerseEnd = lastTask.verseEnd;

    if (lastSurahNum == null || lastVerseEnd == null) return;

    final surahs = await ref.read(surahsProvider.future);
    final lastSurah = surahs.firstWhere((s) => s.number == lastSurahNum, orElse: () => surahs.first);

    setState(() {
      if (lastVerseEnd >= lastSurah.totalVerses) {
        // Move to next surah
        final nextNum = lastSurahNum + 1;
        if (nextNum <= 114) {
          _surah = surahs.firstWhere((s) => s.number == nextNum, orElse: () => lastSurah);
          _verseStart = 1;
          _verseStartSuggested = true;
        }
      } else {
        _surah = lastSurah;
        _verseStart = lastVerseEnd + 1;
        _verseStartSuggested = true;
      }
    });
  }

  Future<void> _submit() async {
    final payload = <String, dynamic>{
      'student_id': _selectedStudentId,
      'pillar': _pillar == TaskPillar.quran ? 'QURAN' : 'ARABIC',
      'task_type': _taskTypeApi(_taskType!),
      'title': _buildTitle(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'due_date': _dueDate.toIso8601String().split('T').first,
      'repeat_type': _repeatType,
    };

    if (_pillar == TaskPillar.quran) {
      payload['surah_number'] = _surah?.number;
      payload['surah_name'] = _surah?.nameAr;
      payload['verse_start'] = _verseStart;
      payload['verse_end'] = _verseEnd;
    } else {
      payload['book_ref'] = _bookRef?.apiValue;
      payload['chapter_number'] = _chapterNumber;
      payload['chapter_title'] = _chapterTitleCtrl.text.trim().isEmpty
          ? null
          : _chapterTitleCtrl.text.trim();
      payload['page_start'] = _pageStart;
      payload['page_end'] = _pageEnd;
    }

    await ref.read(taskCreationProvider.notifier).createTask(payload);

    if (!mounted) return;
    final state = ref.read(taskCreationProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tâche assignée avec succès !')),
        );
        context.pop();
      },
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      },
      loading: () {},
    );
  }

  String _buildTitle() {
    if (_pillar == TaskPillar.quran && _surah != null) {
      final type = _taskTypeLabel(_taskType!);
      return '$type ${_surah!.nameFr}${_verseStart != null ? ' V$_verseStart-$_verseEnd' : ''}';
    } else if (_pillar == TaskPillar.arabic && _bookRef != null) {
      final type = _taskTypeLabel(_taskType!);
      return '$type ${_bookRef!.label}${_chapterNumber != null ? ' Ch.$_chapterNumber' : ''}';
    }
    return _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : 'Tâche';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(taskCreationProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer une tâche'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor: AppColors.divider,
            color: AppColors.primary,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStep(),
            ),
          ),
          if (_step == 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmer et assigner'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepStudent(
          selectedId: _selectedStudentId,
          onSelect: (id) {
            setState(() {
              _selectedStudentId = id;
              _step = 1;
            });
          },
        );
      case 1:
        return _StepPillar(
          selected: _pillar,
          onSelect: (p) {
            setState(() {
              _pillar = p;
              _step = 2;
            });
            if (p == TaskPillar.quran) _loadQuranContinuity();
          },
        );
      case 2:
        return _pillar == TaskPillar.quran
            ? _StepQuran(
                selectedSurah: _surah,
                verseStart: _verseStart,
                verseEnd: _verseEnd,
                verseStartSuggested: _verseStartSuggested,
                taskType: _taskType,
                descCtrl: _descCtrl,
                onSurahChanged: (s) => setState(() {
                  _surah = s;
                  _verseStartSuggested = false;
                }),
                onVerseStartChanged: (v) => setState(() {
                  _verseStart = v;
                  _verseStartSuggested = false;
                }),
                onVerseEndChanged: (v) => setState(() => _verseEnd = v),
                onTypeChanged: (t) => setState(() => _taskType = t),
                onNext: () {
                  if (_surah != null && _verseEnd != null && _taskType != null) {
                    setState(() => _step = 3);
                  }
                },
              )
            : _StepArabic(
                bookRef: _bookRef,
                chapterNumber: _chapterNumber,
                pageStart: _pageStart,
                pageEnd: _pageEnd,
                taskType: _taskType,
                chapterTitleCtrl: _chapterTitleCtrl,
                descCtrl: _descCtrl,
                onBookChanged: (b) => setState(() => _bookRef = b),
                onChapterChanged: (c) => setState(() => _chapterNumber = c),
                onPageStartChanged: (p) => setState(() => _pageStart = p),
                onPageEndChanged: (p) => setState(() => _pageEnd = p),
                onTypeChanged: (t) => setState(() => _taskType = t),
                onNext: () {
                  if (_bookRef != null && _taskType != null) {
                    setState(() => _step = 3);
                  }
                },
              );
      case 3:
        return _StepSchedule(
          dueDate: _dueDate,
          repeatType: _repeatType,
          onDateChanged: (d) => setState(() => _dueDate = d),
          onRepeatChanged: (r) => setState(() => _repeatType = r),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _taskTypeApi(TaskType t) {
    switch (t) {
      case TaskType.memorization:
        return 'MEMORIZATION';
      case TaskType.revision:
        return 'REVISION';
      case TaskType.reading:
        return 'READING';
      case TaskType.grammar:
        return 'GRAMMAR';
      case TaskType.vocabulary:
        return 'VOCABULARY';
    }
  }

  String _taskTypeLabel(TaskType t) {
    switch (t) {
      case TaskType.memorization:
        return 'Mémorisation';
      case TaskType.revision:
        return 'Révision';
      case TaskType.reading:
        return 'Lecture';
      case TaskType.grammar:
        return 'Grammaire';
      case TaskType.vocabulary:
        return 'Vocabulaire';
    }
  }
}

// ─── Step widgets ─────────────────────────────────────────────────────────────

class _StepStudent extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _StepStudent({required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Étape 1 — Choisir l\'élève',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 16),
        studentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(e.toString()),
          data: (students) => Column(
            children: students
                .map((s) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(s.student.fullName[0]),
                      ),
                      title: Text(s.student.fullName),
                      trailing: selectedId == s.student.id
                          ? const Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                      onTap: () => onSelect(s.student.id),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _StepPillar extends StatelessWidget {
  final TaskPillar? selected;
  final ValueChanged<TaskPillar> onSelect;

  const _StepPillar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Étape 2 — Choisir le pilier',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _PillarCard(
                icon: '📖',
                label: 'Coran',
                selected: selected == TaskPillar.quran,
                onTap: () => onSelect(TaskPillar.quran),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _PillarCard(
                icon: '🔤',
                label: 'Arabe',
                selected: selected == TaskPillar.arabic,
                onTap: () => onSelect(TaskPillar.arabic),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PillarCard extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillarCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepQuran extends ConsumerWidget {
  final SurahModel? selectedSurah;
  final int? verseStart;
  final int? verseEnd;
  final bool verseStartSuggested;
  final TaskType? taskType;
  final TextEditingController descCtrl;
  final ValueChanged<SurahModel> onSurahChanged;
  final ValueChanged<int?> onVerseStartChanged;
  final ValueChanged<int?> onVerseEndChanged;
  final ValueChanged<TaskType> onTypeChanged;
  final VoidCallback onNext;

  const _StepQuran({
    required this.selectedSurah,
    required this.verseStart,
    required this.verseEnd,
    required this.verseStartSuggested,
    required this.taskType,
    required this.descCtrl,
    required this.onSurahChanged,
    required this.onVerseStartChanged,
    required this.onVerseEndChanged,
    required this.onTypeChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Étape 3 — Détails Coran',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 16),

        // Type
        const Text('Type de tâche', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [TaskType.memorization, TaskType.revision].map((t) {
            final label = t == TaskType.memorization ? 'Mémorisation' : 'Révision';
            return ChoiceChip(
              label: Text(label),
              selected: taskType == t,
              onSelected: (_) => onTypeChanged(t),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Surah
        const Text('Sourate', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        surahsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(e.toString()),
          data: (surahs) => DropdownButtonFormField<SurahModel>(
            value: selectedSurah,
            decoration: const InputDecoration(hintText: 'Choisir une sourate'),
            items: surahs.map((s) => DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Text('${s.number}. ', style: const TextStyle(color: AppColors.textSecondary)),
                  ArabicText(s.nameAr, fontSize: 18),
                  const SizedBox(width: 8),
                  Text(s.nameFr, style: const TextStyle(fontSize: 13)),
                ],
              ),
            )).toList(),
            onChanged: (s) { if (s != null) onSurahChanged(s); },
          ),
        ),
        const SizedBox(height: 16),

        // Verses
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Verset de', style: TextStyle(fontWeight: FontWeight.w600)),
                      if (verseStartSuggested) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Suggestion',
                            style: TextStyle(fontSize: 10, color: AppColors.accent),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: verseStart?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Ex: 1'),
                    onChanged: (v) => onVerseStartChanged(int.tryParse(v)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verset à', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: verseEnd?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Ex: 10'),
                    onChanged: (v) => onVerseEndChanged(int.tryParse(v)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextField(
          controller: descCtrl,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Instructions (optionnel)'),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedSurah != null && verseEnd != null && taskType != null ? onNext : null,
            child: const Text('Suivant → Planification'),
          ),
        ),
      ],
    );
  }
}

class _StepArabic extends StatelessWidget {
  final BookRef? bookRef;
  final int? chapterNumber;
  final int? pageStart;
  final int? pageEnd;
  final TaskType? taskType;
  final TextEditingController chapterTitleCtrl;
  final TextEditingController descCtrl;
  final ValueChanged<BookRef> onBookChanged;
  final ValueChanged<int?> onChapterChanged;
  final ValueChanged<int?> onPageStartChanged;
  final ValueChanged<int?> onPageEndChanged;
  final ValueChanged<TaskType> onTypeChanged;
  final VoidCallback onNext;

  const _StepArabic({
    required this.bookRef,
    required this.chapterNumber,
    required this.pageStart,
    required this.pageEnd,
    required this.taskType,
    required this.chapterTitleCtrl,
    required this.descCtrl,
    required this.onBookChanged,
    required this.onChapterChanged,
    required this.onPageStartChanged,
    required this.onPageEndChanged,
    required this.onTypeChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Étape 3 — Détails Arabe',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 16),

        const Text('Type de tâche', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [TaskType.reading, TaskType.grammar, TaskType.vocabulary].map((t) {
            final labels = {
              TaskType.reading: 'Lecture',
              TaskType.grammar: 'Grammaire',
              TaskType.vocabulary: 'Vocabulaire',
            };
            return ChoiceChip(
              label: Text(labels[t]!),
              selected: taskType == t,
              onSelected: (_) => onTypeChanged(t),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        const Text('Livre', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<BookRef>(
          value: bookRef,
          decoration: const InputDecoration(hintText: 'Choisir un livre'),
          items: BookRef.values
              .map((b) => DropdownMenuItem(value: b, child: Text(b.label)))
              .toList(),
          onChanged: (b) { if (b != null) onBookChanged(b); },
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Chapitre/Leçon'),
                onChanged: (v) => onChapterChanged(int.tryParse(v)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: chapterTitleCtrl,
                decoration: const InputDecoration(labelText: 'Titre (optionnel)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Page de'),
                onChanged: (v) => onPageStartChanged(int.tryParse(v)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Page à'),
                onChanged: (v) => onPageEndChanged(int.tryParse(v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextField(
          controller: descCtrl,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Instructions (optionnel)'),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: bookRef != null && taskType != null ? onNext : null,
            child: const Text('Suivant → Planification'),
          ),
        ),
      ],
    );
  }
}

class _StepSchedule extends StatelessWidget {
  final DateTime dueDate;
  final String repeatType;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onRepeatChanged;

  const _StepSchedule({
    required this.dueDate,
    required this.repeatType,
    required this.onDateChanged,
    required this.onRepeatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Étape 4 — Planification',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 20),

        const Text("Date d'échéance", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dueDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) onDateChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE d MMMM yyyy', 'fr').format(dueDate),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text('Répétition', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...[
          ('NONE', 'Aucune'),
          ('DAILY', 'Quotidienne'),
          ('WEEKLY', 'Hebdomadaire'),
        ].map((r) => RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: r.$1,
          groupValue: repeatType,
          onChanged: (v) { if (v != null) onRepeatChanged(v); },
          title: Text(r.$2),
          activeColor: AppColors.primary,
        )),
      ],
    );
  }
}
