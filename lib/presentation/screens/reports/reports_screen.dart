import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/utang_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isWeekly = false;

  static const _dailyLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  static const _weeklyLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final payments = context.watch<PaymentProvider>();
    final inventory = context.watch<InventoryProvider>();
    final utang = context.watch<UtangProvider>();
    final dailySales =
        _combineSales(inventory.salesByWeekday(), utang.salesByWeekday());
    final weeklySales =
        _combineSales(inventory.weeklySalesByDay(), utang.weeklySalesByDay());
    final data = _isWeekly ? weeklySales : dailySales;
    final labels = _isWeekly ? _weeklyLabels : _dailyLabels;
    final totalSales = inventory.totalSales + utang.totalSales;
    final outstanding = payments.remainingFrom(utang.outstanding);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      Text('Reports', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Daily'), icon: Icon(Icons.today_outlined)), ButtonSegment(value: true, label: Text('Weekly'), icon: Icon(Icons.date_range_outlined))], selected: {_isWeekly}, onSelectionChanged: (value) => setState(() => _isWeekly = value.first)),
      const SizedBox(height: 18),
      Card(child: Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Sales visualization', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), const SizedBox(height: 10), SizedBox(height: 240, child: CustomPaint(painter: SalesBarChartPainter(data: data, labels: labels)))]))),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: _summaryCard('Total Sales', currencyFormatter.format(totalSales), Icons.point_of_sale_outlined, AppColors.primary)), const SizedBox(width: 12), Expanded(child: _summaryCard('Outstanding Utang', currencyFormatter.format(outstanding), Icons.receipt_long_outlined, AppColors.danger))]),
      const SizedBox(height: 20),
      const Text('Top-Selling Products', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 10),
      ...const [
        
      ].map((item) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: AppColors.accent.withValues(alpha: .25), child: Text(item.$2.toString())), title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)), trailing: Text(item.$3, style: const TextStyle(fontWeight: FontWeight.w800))))),
    ]);
  }

  List<double> _combineSales(List<double> first, List<double> second) {
    return List<double>.generate(
      first.length,
      (index) => first[index] + second[index],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 5), FittedBox(child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)))])));
}

class SalesBarChartPainter extends CustomPainter {
  SalesBarChartPainter({required this.data, required this.labels});
  final List<double> data;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary;
    final trackPaint = Paint()..color = AppColors.primary.withValues(alpha: .10);
    final gridPaint = Paint()..color = Colors.black12;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final maxValue = data.isEmpty ? 0.0 : data.reduce((a, b) => a > b ? a : b);
    const left = 8.0, bottom = 28.0, top = 12.0;
    final chartH = size.height - bottom - top;
    const gap = 8.0;
    final barW = (size.width - left - gap * (data.length - 1)) / data.length;
    final baseY = top + chartH;
    for (var line = 0; line <= 3; line++) {
      final y = top + chartH * line / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var i = 0; i < data.length; i++) {
      final h = maxValue == 0 ? 0.0 : chartH * (data[i] / maxValue);
      final x = left + i * (barW + gap);
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barW, chartH),
        const Radius.circular(6),
      );
      canvas.drawRRect(trackRect, trackPaint);
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x, baseY - h, barW, h), const Radius.circular(6));
      if (h > 0) canvas.drawRRect(rect, paint);
      textPainter.text = TextSpan(text: labels[i], style: const TextStyle(fontSize: 10, color: Colors.black54));
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + (barW - textPainter.width) / 2, baseY + 7));
    }
  }

  @override
  bool shouldRepaint(covariant SalesBarChartPainter oldDelegate) => oldDelegate.data != data || oldDelegate.labels != labels;
}
