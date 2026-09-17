import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({super.key, required this.label, required this.onPressed, this.icon, this.loading = false, this.filled = true});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(label),
          ]);
    return SizedBox(height: 52, width: double.infinity, child: filled
        ? ElevatedButton(onPressed: loading ? null : onPressed, child: child)
        : OutlinedButton(onPressed: loading ? null : onPressed, child: child));
  }
}
