import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/constants/app_colors.dart';

class StudentSettingsScreen extends ConsumerStatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  ConsumerState<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends ConsumerState<StudentSettingsScreen> {
  int _notifHour = 18;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(localStorageProvider);
    final hour = await storage.getNotifHour();
    setState(() => _notifHour = hour);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final jokersAsync = ref.watch(jokersHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          // Profile
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
            ),
          ),

          // Notifications
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('NOTIFICATIONS',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.textHint, letterSpacing: 1)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              title: const Text('Heure de rappel'),
              subtitle: Text('Rappel quotidien à ${_notifHour}h00'),
              trailing: DropdownButton<int>(
                value: _notifHour,
                underline: const SizedBox.shrink(),
                items: List.generate(24, (i) => DropdownMenuItem(
                  value: i,
                  child: Text('${i}h'),
                )),
                onChanged: (h) async {
                  if (h == null) return;
                  setState(() => _notifHour = h);
                  final storage = ref.read(localStorageProvider);
                  await storage.setNotifHour(h);
                },
              ),
            ),
          ),

          // Parental validation
          if (user?.isChildProfile == true || user?.isChildProfile == false) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('VALIDATION PARENTALE',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppColors.textHint, letterSpacing: 1)),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
                    title: const Text('Validation parentale'),
                    subtitle: Text(
                      user?.isChildProfile == true ? 'Activée' : 'Désactivée',
                    ),
                  ),
                  if (user?.isChildProfile == true) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.pin_outlined),
                      title: user?.hasParentPin == true
                          ? const Text('Modifier le PIN parental')
                          : const Text('Définir un PIN parental'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showPinSetup(context),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Jokers history
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('MES JOKERS',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.textHint, letterSpacing: 1)),
          ),
          jokersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (jokers) {
              if (jokers.isEmpty) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: const ListTile(
                    title: Text('Aucun joker utilisé ce mois.'),
                    leading: Text('🃏', style: TextStyle(fontSize: 24)),
                  ),
                );
              }
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: jokers.map((j) => ListTile(
                    leading: const Text('🃏', style: TextStyle(fontSize: 20)),
                    title: Text(j.reasonLabel),
                    subtitle: j.note != null ? Text('"${j.note}"') : null,
                    trailing: Text(
                      '${j.usedForDate.day}/${j.usedForDate.month}',
                      style: const TextStyle(color: AppColors.textHint),
                    ),
                  )).toList(),
                ),
              );
            },
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

  void _showPinSetup(BuildContext context) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Définir un PIN parental'),
        content: TextField(
          controller: pinCtrl,
          maxLength: 4,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '4 chiffres'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinCtrl.text.length == 4) {
                final ok = await ref.read(authStateProvider.notifier).setParentPin(pinCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN parental mis à jour.')),
                  );
                }
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
