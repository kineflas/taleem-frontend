import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../autonomous_learning/models/learning_models.dart';
import '../providers/hifz_provider.dart';

class HifzGoalCreateScreen extends ConsumerStatefulWidget {
  const HifzGoalCreateScreen({super.key});

  @override
  ConsumerState<HifzGoalCreateScreen> createState() => _HifzGoalCreateScreenState();
}

class _HifzGoalCreateScreenState extends ConsumerState<HifzGoalCreateScreen> {
  int _selectedSurah = 1;
  GoalMode _mode = GoalMode.quantitative;
  int _versesPerDay = 5;
  DateTime? _targetDate;
  String _selectedReciter = 'Alafasy_128kbps';

  final surahNames = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة',
    'الأنعام', 'الأعراف', 'الأنفال', 'التوبة', 'يونس',
    'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
    'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه',
    'الأنبياء', 'الحج', 'المؤمنون', 'النور', 'الفرقان',
    'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
    'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر',
    'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
    'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية',
    'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق',
    'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن',
    'الواقعة', 'الحديد', 'المجادلة', 'الحشر', 'الممتحنة',
    'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق',
    'التحريم', 'الملك', 'القلم', 'الحاقة', 'نوح',
    'الجن', 'المزمل', 'المدثر', 'القيامة', 'الإنسان',
    'المرسلات', 'النبأ', 'النازعات', 'عبس', 'التكوير',
    'الإنفطار', 'المطففين', 'الانشقاق', 'البروج', 'الطارق',
    'الأعلى', 'الغاشية', 'الفجر', 'البلد', 'الشمس',
    'الليل', 'الضحى', 'الشرح', 'التين', 'العلق',
    'القدر', 'البينة', 'الزلزلة', 'العاديات', 'القارعة',
    'التكاثر', 'العصر', 'الهمزة', 'الفيل', 'قريش',
    'الماعون', 'الكوثر', 'الكافرون', 'النصر', 'المسد',
    'الإخلاص', 'الفلق', 'الناس',
  ];

  @override
  Widget build(BuildContext context) {
    final recitersAsync = ref.watch(hifzRecitersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer un objectif'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Surah Picker
            _buildSection(
              'Choisir une Sourah',
              _buildSurahPicker(),
            ),
            const SizedBox(height: 24),

            // Mode selection
            _buildSection(
              'Mode objectif',
              _buildModeSelection(),
            ),
            const SizedBox(height: 24),

            // Daily target display
            _buildSection(
              'Cible quotidienne',
              _buildDailyTargetDisplay(),
            ),
            const SizedBox(height: 24),

            // Mode-specific controls
            if (_mode == GoalMode.quantitative)
              _buildSection(
                'Versets par jour',
                _buildVersesPerDaySlider(),
              )
            else
              _buildSection(
                'Date cible',
                _buildTargetDatePicker(),
              ),
            const SizedBox(height: 24),

            // Reciter selection
            _buildSection(
              'Sélectionner un récitant',
              recitersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erreur: $e'),
                data: (reciters) => _buildReciterChips(reciters),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleCreateGoal,
                icon: const Text('✨', style: TextStyle(fontSize: 20)),
                label: const Text(
                  'Commencer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildSurahPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedSurah,
                isExpanded: true,
                items: List.generate(114, (i) {
                  final surahNum = i + 1;
                  return DropdownMenuItem(
                    value: surahNum,
                    child: Row(
                      children: [
                        Text(
                          surahNames[i],
                          style: GoogleFonts.amiri(fontSize: 16),
                          textDirection: TextDirection.rtl,
                        ),
                        const Spacer(),
                        Text(
                          '($surahNum)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSurah = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelection() {
    return Row(
      children: [
        Expanded(
          child: _buildModeCard(
            '📊',
            'Quantitatif',
            'versets par jour',
            _mode == GoalMode.quantitative,
            () => setState(() => _mode = GoalMode.quantitative),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModeCard(
            '📅',
            'Temporel',
            'date limite',
            _mode == GoalMode.temporal,
            () => setState(() => _mode = GoalMode.temporal),
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard(
    String icon,
    String title,
    String subtitle,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTargetDisplay() {
    final target = _mode == GoalMode.quantitative
        ? _versesPerDay
        : _calculateDailyTarget();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vous devez apprendre',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '$target versets par jour',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          Text(
            '📖',
            style: const TextStyle(fontSize: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildVersesPerDaySlider() {
    return Column(
      children: [
        Slider(
          value: _versesPerDay.toDouble(),
          min: 1,
          max: 20,
          divisions: 19,
          activeColor: AppColors.primary,
          onChanged: (value) {
            setState(() => _versesPerDay = value.toInt());
          },
        ),
        const SizedBox(height: 8),
        Text(
          '$_versesPerDay versets',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTargetDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _targetDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              _targetDate != null
                  ? DateFormat('d MMMM yyyy', 'fr').format(_targetDate!)
                  : 'Sélectionner une date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _targetDate != null ? AppColors.textPrimary : AppColors.textHint,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReciterChips(List<ReciterModel> reciters) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: reciters.map((reciter) {
        final isSelected = _selectedReciter == reciter.id;
        return FilterChip(
          label: Text(reciter.nameEn),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedReciter = reciter.id);
            }
          },
          backgroundColor: Colors.white,
          selectedColor: AppColors.primary.withOpacity(0.2),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        );
      }).toList(),
    );
  }

  int _calculateDailyTarget() {
    if (_targetDate == null) return 1;
    final daysRemaining = _targetDate!.difference(DateTime.now()).inDays;
    if (daysRemaining <= 0) return 1;
    // Assuming average surah has 30 verses, adjust as needed
    return (30 / daysRemaining).ceil();
  }

  Future<void> _handleCreateGoal() async {
    if (_mode == GoalMode.temporal && _targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date')),
      );
      return;
    }

    // TODO: Call API to create goal
    // For now, just navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Objectif créé! 🎉'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pop();
  }
}
