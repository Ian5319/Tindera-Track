import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/utang_transaction.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({super.key, required this.transaction});

  final UtangTransaction transaction;

  Future<void> _showPhoto(BuildContext context, String photoUrl) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                title: const Text('Utang photo evidence'),
                actions: [
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: InteractiveViewer(
                  minScale: .8,
                  maxScale: 4,
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('The attached photo could not be loaded.'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credit = transaction.type == UtangType.credit;
    final photoUrl = transaction.photoUrl;
    final hasPhoto = photoUrl?.startsWith('https://') == true;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: credit ? AppColors.warningBg : AppColors.successBg,
          child: Icon(
            credit ? Icons.add : Icons.remove,
            color: credit ? AppColors.warningText : AppColors.secondary,
          ),
        ),
        title: Text(
          credit ? 'Charge' : 'Payment',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${dateFormatter.format(transaction.createdAt)}'
          '${transaction.note == null ? '' : '\n${transaction.note}'}',
        ),
        isThreeLine: transaction.note != null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPhoto)
              IconButton(
                tooltip: 'View attached photo',
                visualDensity: VisualDensity.compact,
                onPressed: () => _showPhoto(context, photoUrl!),
                icon: const Icon(Icons.photo_camera_outlined, size: 20),
              ),
            const SizedBox(width: 4),
            Text(
              '${credit ? '+' : '-'}${currencyFormatter.format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: credit ? AppColors.warningText : AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
