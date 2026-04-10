import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ParentPinDialog extends StatefulWidget {
  final Future<bool> Function(String pin) onVerify;

  const ParentPinDialog({super.key, required this.onVerify});

  @override
  State<ParentPinDialog> createState() => _ParentPinDialogState();
}

class _ParentPinDialogState extends State<ParentPinDialog> {
  String _pin = '';
  int _attempts = 0;
  bool _isLocked = false;
  bool _isLoading = false;
  String? _errorMsg;

  void _appendDigit(String digit) {
    if (_pin.length >= 4 || _isLocked || _isLoading) return;
    setState(() {
      _pin += digit;
      _errorMsg = null;
    });
    if (_pin.length == 4) _verify();
  }

  void _deleteDigit() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verify() async {
    setState(() => _isLoading = true);
    final ok = await widget.onVerify(_pin);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _attempts++;
      if (_attempts >= 3) {
        setState(() {
          _isLocked = true;
          _isLoading = false;
          _errorMsg = 'Trop d\'essais. Réessaie dans 5 minutes.';
          _pin = '';
        });
        // Auto-close after 5 min (simplified: close with failure)
        Future.delayed(const Duration(minutes: 5), () {
          if (mounted) Navigator.of(context).pop(false);
        });
      } else {
        setState(() {
          _isLoading = false;
          _pin = '';
          _errorMsg = 'PIN incorrect. ${3 - _attempts} essai(s) restant(s).';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield, color: AppColors.primary, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Validation parentale',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fais valider par un parent',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: filled ? AppColors.primary : AppColors.divider,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),

            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              )
            else if (!_isLocked) ...[
              const SizedBox(height: 16),
              _buildKeypad(),
            ],

            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: digits.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((d) {
            if (d.isEmpty) return const SizedBox(width: 72, height: 56);
            return GestureDetector(
              onTap: () => d == '⌫' ? _deleteDigit() : _appendDigit(d),
              child: Container(
                width: 72,
                height: 56,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

Future<bool> showParentPinDialog(
  BuildContext context, {
  required Future<bool> Function(String pin) onVerify,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ParentPinDialog(onVerify: onVerify),
  );
  return result ?? false;
}
