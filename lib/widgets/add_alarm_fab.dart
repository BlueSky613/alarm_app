import 'package:flutter/material.dart';

/// Same control as the MY ALARMS screen add button (rounded square, not circular FAB).
class AddAlarmFab extends StatelessWidget {
  const AddAlarmFab({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  static const Color _kPrimary = Color(0xFF0EF196);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kPrimary,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: _kPrimary.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.add_rounded, size: 28, color: Colors.black),
        ),
      ),
    );
  }
}
