import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class InvitationCodeScreen extends ConsumerStatefulWidget {
  const InvitationCodeScreen({super.key});

  @override
  ConsumerState<InvitationCodeScreen> createState() => _InvitationCodeScreenState();
}

class _InvitationCodeScreenState extends ConsumerState<InvitationCodeScreen> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Le code doit contenir 6 caractères.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authStateProvider.notifier).linkInvitationCode(code);
      if (mounted) context.go('/student');
    } catch (e) {
      setState(() => _error = 'Code invalide ou expiré.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.link, color: AppColors.primary, size: 64),
              const SizedBox(height: 24),
              Text(
                "Code d'invitation",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "Saisis le code à 6 caractères fourni par ton enseignant.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),

              TextFormField(
                controller: _codeCtrl,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(letterSpacing: 8, color: AppColors.primary),
                decoration: InputDecoration(
                  hintText: '_ _ _ _ _ _',
                  hintStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        letterSpacing: 8,
                        color: AppColors.textHint,
                      ),
                  counterText: '',
                  errorText: _error,
                ),
                onChanged: (v) {
                  if (v.length == 6) _submit();
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Rejoindre'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/student'),
                child: const Text("Passer pour l'instant"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
