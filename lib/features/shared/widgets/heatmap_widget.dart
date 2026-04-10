import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/task_model.dart';

class HeatmapWidget extends StatefulWidget {
  final List<HeatmapDay> days;
  final int year;
  final int month;
  final ValueChanged<int>? onMonthChanged; // offset from current
  final void Function(HeatmapDay day)? onDayTap;

  const HeatmapWidget({
    super.key,
    required this.days,
    required this.year,
    required this.month,
    this.onMonthChanged,
    this.onDayTap,
  });

  @override
  State<HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends State<HeatmapWidget> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.year;
    _month = widget.month;
  }

  void _prevMonth() {
    setState(() {
      _month--;
      if (_month < 1) {
        _month = 12;
        _year--;
      }
    });
    widget.onMonthChanged?.call(-1);
  }

  void _nextMonth() {
    setState(() {
      _month++;
      if (_month > 12) {
        _month = 1;
        _year++;
      }
    });
    widget.onMonthChanged?.call(1);
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_year, _month, 1);
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday

    final dayMap = {
      for (final d in widget.days) '${d.date.year}-${d.date.month}-${d.date.day}': d
    };

    final monthLabel = DateFormat('MMMM yyyy', 'fr').format(firstDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _prevMonth,
            ),
            Text(
              monthLabel,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
            ),
          ],
        ),

        // Day labels
        Row(
          children: ['D', 'L', 'M', 'M', 'J', 'V', 'S'].map((d) {
            return Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (ctx, i) {
            if (i < startWeekday) return const SizedBox.shrink();
            final dayNum = i - startWeekday + 1;
            final date = DateTime(_year, _month, dayNum);
            final key = '${date.year}-${date.month}-${date.day}';
            final hd = dayMap[key];

            return GestureDetector(
              onTap: hd != null ? () => widget.onDayTap?.call(hd) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: _colorForDay(hd, date),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dayNum',
                  style: TextStyle(
                    fontSize: 11,
                    color: hd != null ? Colors.white : AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),

        // Legend
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _LegendItem(color: AppColors.heatmapLight, label: '1 tâche'),
            _LegendItem(color: AppColors.heatmapDark, label: '3+ tâches'),
            _LegendItem(color: AppColors.heatmapJoker, label: 'Joker'),
            _LegendItem(color: AppColors.heatmapMissed, label: 'Manquée'),
            _LegendItem(color: AppColors.heatmapSkipped, label: 'Excusée'),
          ],
        ),
      ],
    );
  }

  Color _colorForDay(HeatmapDay? hd, DateTime date) {
    if (date.isAfter(DateTime.now())) return AppColors.heatmapEmpty;
    if (hd == null) return AppColors.heatmapEmpty;
    if (hd.hasMissed && hd.completedCount == 0) return AppColors.heatmapMissed;
    if (hd.hasSkipped && hd.completedCount == 0) return AppColors.heatmapSkipped;
    if (hd.jokerUsed && hd.completedCount == 0) return AppColors.heatmapJoker;
    switch (hd.completedCount) {
      case 0:
        return AppColors.heatmapEmpty;
      case 1:
        return AppColors.heatmapLight;
      case 2:
        return AppColors.heatmapMedium;
      default:
        return AppColors.heatmapDark;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
