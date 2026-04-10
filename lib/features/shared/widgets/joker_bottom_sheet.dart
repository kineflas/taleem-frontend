import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';

class JokerBottomSheet extends ConsumerStatefulWidget {
  final int jokersLeft;
  final Future<void> Function(JokerReason reason, String? note) onConfirm;

  const JokerBottomSheet({
    super.key,
    required this.jokersLeft,
    required this.onConfirm,
  });

  @override
  ConsumerState<JokerBottomSheet> createState() => _JokerBottomSheetState();
}

class _JokerBottomSheetState extends ConsumerState<JokerBottomSheet> {
  JokerReason? _reason;
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;

  static const _reasons = [
    (reason: JokerReason.illness, label: '🤒 Maladie'),
    (reason: JokerReason.travel, label: '✈️ Voyage'),
    (reason: JokerReason.family, label: '👨‍👩‍👧 Obligations familiales'),
    (reason: JokerReason.other, label: '💬 Autre'),
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_reason == null) return;
    setState(() => _isLoading = true);
    try {
      await widget.onConfirm(_reason!, _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '🃏 Utiliser un joker',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Il te reste ${widget.jokersLeft} joker${widget.jokersLeft > 1 ? 's' : ''} ce mois-ci.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          const Text(
            'Raison :',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ..._reasons.map((r) => RadioListTile<JokerReason>(
                contentPadding: EdgeInsets.zero,
                value: r.reason,
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                title: Text(r.label),
                activeColor: AppColors.joker,
              )),

          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note (optionnel)',
              hintText: 'Explique la situation...',
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _reason == null || _isLoading ? null : _confirm,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.joker),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text("Confirmer l'utilisation du joker"),
          ),
        ],
      ),
    );
  }
}

Future<bool> showJokerBottomSheet(
  BuildContext context, {
  required int jokersLeft,
  required Future<void> Function(JokerReason reason, String? note) onConfirm,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => JokerBottomSheet(jokersLeft: jokersLeft, onConfirm: onConfirm),
  );
  return result ?? false;
}
