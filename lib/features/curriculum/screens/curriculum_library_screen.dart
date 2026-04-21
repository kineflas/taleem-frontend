import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../models/curriculum_model.dart';
import '../providers/curriculum_provider.dart';

/// Student Library Screen — lists all 5 programs with enrollment status.
/// Accessible from the student bottom navigation (new "Parcours" tab).
class CurriculumLibraryScreen extends ConsumerWidget {
  const CurriculumLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(curriculumProgramsProvider);
    final enrollmentsAsync = ref.watch(myEnrollmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Parcours', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: programsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (programs) {
          final enrollments = enrollmentsAsync.valueOrNull ?? [];
          final enrolledIds = {for (final e in enrollments) e.curriculumProgramId};

          // Hide legacy programs replaced by newer features
          const hiddenTypes = {
            CurriculumType.alphabetArabe,    // → L'Odyssée des Lettres
            CurriculumType.voyellesSyllabes, // → L'Odyssée des Lettres
            CurriculumType.medineT1,         // → Tome 1 de Médine V2
            CurriculumType.hifzRevision,     // → Hifz Master V2
          };
          final visiblePrograms = programs
              .where((p) => !hiddenTypes.contains(p.curriculumType))
              .toList();

          // Group programs by category, preserving sort order
          final grouped = <ProgramCategory, List<CurriculumProgram>>{};
          for (final p in visiblePrograms) {
            grouped.putIfAbsent(p.category, () => []).add(p);
          }
          // Order categories — toujours afficher les 3 catégories même si
          // elles n'ont plus de programmes API visibles (les _FeatureCard
          // comme Médine V2, Odyssée ou Hifz Master doivent rester visibles).
          final orderedCategories = [
            ProgramCategory.apprendreALire,
            ProgramCategory.comprendreArabe,
            ProgramCategory.coran,
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final cat in orderedCategories) ...[
                  _CategoryHeader(category: cat),
                  const SizedBox(height: 10),
                  ...(grouped[cat] ?? []).map((program) {
                    final isEnrolled = enrolledIds.contains(program.id);
                    final enrollment = isEnrolled
                        ? enrollments.firstWhere(
                            (e) => e.curriculumProgramId == program.id)
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ProgramCard(
                        program: program,
                        isEnrolled: isEnrolled,
                        enrollment: enrollment,
                        onTap: () {
                          if (isEnrolled && enrollment != null) {
                            context.push(
                                '/student/curriculum/${enrollment.id}');
                          } else {
                            _showEnrollDialog(context, ref, program);
                          }
                        },
                      ),
                    );
                  }),
                  // Add Odyssée des Lettres in "Apprendre à lire"
                  if (cat == ProgramCategory.apprendreALire) ...[
                    _FeatureCard(
                      icon: '✨',
                      titleFr: "L'Odyssée des Lettres",
                      titleAr: 'رحلة الحروف',
                      subtitleFr: '18 leçons : apprends les 28 lettres arabes pas à pas',
                      color: const Color(0xFF2A9D8F),
                      onTap: () => context.go('/student/odyssee'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Add Medine V2 feature card in "Comprendre l'arabe"
                  if (cat == ProgramCategory.comprendreArabe) ...[
                    _FeatureCard(
                      icon: '🐫',
                      titleFr: 'Tome 1 de Médine — V2',
                      titleAr: 'الكتاب الأول من سلسلة المدينة',
                      subtitleFr: 'Parcours immersif : 23 leçons interactives',
                      color: const Color(0xFF1B4332),
                      onTap: () => context.go('/student/medine-v2'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Add special feature cards after the Coran category
                  if (cat == ProgramCategory.coran) ...[
                    _FeatureCard(
                      icon: '🔤',
                      titleFr: 'Vocabulaire du Coran',
                      titleAr: 'مفردات القرآن',
                      subtitleFr: 'Apprenez les mots les plus fréquents du Coran',
                      color: const Color(0xFF00897B),
                      onTap: () => context.go('/student/learn'),
                    ),
                    const SizedBox(height: 10),
                    _FeatureCard(
                      icon: '🌟',
                      titleFr: 'Hifz Master V2 — Le Voyage du Hafiz',
                      titleAr: 'رحلة الحافظ',
                      subtitleFr: 'Wird quotidien avec SRS 7 paliers, exercices et récitation',
                      color: const Color(0xFF1B5E20),
                      onTap: () => context.go('/student/hifz-v2'),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEnrollDialog(
      BuildContext context, WidgetRef ref, CurriculumProgram program) {
    // Capture the page-level navigator so it survives dialog dismissal.
    final pageContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(program.titleFr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(program.descriptionFr ?? '', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Text('${program.totalUnits} unités', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(dialogContext); // close dialog
              try {
                final enrollment = await ref.read(curriculumApiProvider).enroll(program.id);
                ref.invalidate(myEnrollmentsProvider);
                ref.invalidate(enrollmentProgressProvider(enrollment.id));
                if (pageContext.mounted) {
                  pageContext.push('/student/curriculum/${enrollment.id}');
                }
              } catch (e) {
                if (pageContext.mounted) {
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            child: const Text("S'inscrire", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final ProgramCategory category;

  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(category.icon, color: category.color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          category.titleFr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: category.color,
          ),
        ),
      ],
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final CurriculumProgram program;
  final bool isEnrolled;
  final StudentEnrollment? enrollment;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.program,
    required this.isEnrolled,
    required this.enrollment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    program.curriculumType.icon,
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.titleFr,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      program.titleAr,
                      style: TextStyle(
                          fontSize: 18,
                          color: AppColors.primary,
                          fontFamily: GoogleFonts.scheherazadeNew().fontFamily),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${program.totalUnits} unités',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    if (isEnrolled) ...[
                      const SizedBox(height: 8),
                      const _EnrollmentBadge(),
                    ],
                  ],
                ),
              ),
              // Arrow
              Icon(
                isEnrolled ? Icons.arrow_forward_ios : Icons.add_circle_outline,
                color: isEnrolled ? AppColors.primary : AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String icon;
  final String titleFr;
  final String titleAr;
  final String subtitleFr;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.titleFr,
    required this.titleAr,
    required this.subtitleFr,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleFr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      titleAr,
                      style: TextStyle(
                        fontSize: 16,
                        color: color.withOpacity(0.8),
                        fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleFr,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnrollmentBadge extends StatelessWidget {
  const _EnrollmentBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle, size: 14, color: AppColors.success),
        const SizedBox(width: 4),
        Text(
          'En cours',
          style: TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}


/// Teacher — Student Curriculum Tab
/// Shown inside the StudentDetailScreen as a tab.
class TeacherStudentCurriculumTab extends ConsumerWidget {
  final String studentId;

  const TeacherStudentCurriculumTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(studentEnrollmentsProvider(studentId));
    final programsAsync = ref.watch(curriculumProgramsProvider);

    return enrollmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (enrollments) {
        final programs = programsAsync.valueOrNull ?? [];
        final enrolledIds = {for (final e in enrollments) e.curriculumProgramId};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enrolled programs
              if (enrollments.isNotEmpty) ...[
                Text('Programmes en cours',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...enrollments.map((e) => _TeacherEnrollmentTile(
                  enrollment: e,
                  studentId: studentId,
                )),
                const SizedBox(height: 20),
              ],

              // Available programs to assign (grouped by category)
              Text('Assigner un programme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._buildGroupedAssignList(
                programs.where((p) => !enrolledIds.contains(p.id)).toList(),
                studentId,
                ref,
              ),
              if (programs.where((p) => !enrolledIds.contains(p.id)).isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('L\'élève est inscrit à tous les programmes disponibles.'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildGroupedAssignList(
      List<CurriculumProgram> available, String studentId, WidgetRef ref) {
    final grouped = <ProgramCategory, List<CurriculumProgram>>{};
    for (final p in available) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }
    final categoryOrder = [
      ProgramCategory.apprendreALire,
      ProgramCategory.comprendreArabe,
      ProgramCategory.coran,
    ];
    final widgets = <Widget>[];
    for (final cat in categoryOrder) {
      if (!grouped.containsKey(cat)) continue;
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(cat.titleFr,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cat.color)),
      ));
      for (final p in grouped[cat]!) {
        widgets.add(_AssignProgramTile(
          program: p,
          studentId: studentId,
          onAssigned: () =>
              ref.invalidate(studentEnrollmentsProvider(studentId)),
        ));
      }
    }
    return widgets;
  }
}

class _TeacherEnrollmentTile extends StatelessWidget {
  final StudentEnrollment enrollment;
  final String studentId;

  const _TeacherEnrollmentTile({required this.enrollment, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          enrollment.program.curriculumType.icon,
          style: TextStyle(fontSize: 24),
        ),
        title: Text(enrollment.program.titleFr),
        subtitle: Text(
          enrollment.mode == EnrollmentMode.teacherAssigned ? 'Assigné par vous' : 'Autonome',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.push(
            '/teacher/students/$studentId/curriculum/${enrollment.id}'),
      ),
    );
  }
}

class _AssignProgramTile extends StatelessWidget {
  final CurriculumProgram program;
  final String studentId;
  final VoidCallback onAssigned;

  const _AssignProgramTile({
    required this.program,
    required this.studentId,
    required this.onAssigned,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(program.curriculumType.icon, style: TextStyle(fontSize: 24)),
        title: Text(program.titleFr),
        subtitle: Text('${program.totalUnits} unités'),
        trailing: Consumer(builder: (context, ref, _) {
          return IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: () async {
              try {
                await ref.read(curriculumApiProvider).teacherEnroll(studentId, program.id);
                onAssigned();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${program.titleFr} assigné !'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
          );
        }),
      ),
    );
  }
}
