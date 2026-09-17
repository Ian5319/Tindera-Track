import 'package:flutter/material.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[const SizedBox(height: 16), OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try Again'))],
      ])));
}
