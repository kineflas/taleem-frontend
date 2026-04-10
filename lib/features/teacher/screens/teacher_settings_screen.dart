import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/teacher_provider.dart';
import '../../../core/constants/app_colors.dart';

class TeacherSettingsScreen extends ConsumerWidget {
  const TeacherSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          // Profile section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('MON PROFIL',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.textHint, letterSpacing: 1)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  user?.fullName[0].toUpperCase() ?? '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(user?.fullName ?? ''),
              subtitle: Text(user?.email ?? ''),
              trailing: const Icon(Icons.edit_outlined, color: AppColors.textHint),
            ),
          ),

          // Students management section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('MES ÉLÈVES',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.textHint, letterSpacing: 1)),
          ),
          studentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (students) => Column(
              children: students.map((s) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(s.student.fullName[0]),
                    ),
                    title: Text(s.student.fullName),
                    subtitle: Row(
                      children: [
                        if (s.student.isChildProfile)
                          const Text('👨‍👧 Profil enfant · '),
                        Text('🃏 Quota: ${s.jokersLeft} jokers'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showStudentOptions(context, ref, s.student.id, s.student.fullName),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.person_add_outlined, color: AppColors.primary),
              title: const Text('Inviter un élève'),
              onTap: () => _showInviteDialog(context, ref),
            ),
          ),

          // Logout
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('Se déconnecter',
                  style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showStudentOptions(
      BuildContext context, WidgetRef ref, String studentId, String name) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: Text('Retirer $name'),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(studentsProvider.notifier).removeStudent(studentId);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Code d'invitation"),
        content: FutureBuilder<String>(
          future: ref.read(studentsProvider.notifier).generateInviteCode(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final code = snap.data ?? '------';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Transmets ce code à ton élève. Valide 48h."),
                const SizedBox(height: 16),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: AppColors.primary,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }
}
