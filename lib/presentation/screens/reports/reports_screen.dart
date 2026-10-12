import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  static const _weeklyPointCount = 5;
  static final _chartDateFormatter = DateFormat('MMM d');
  static final _rangeDateFormatter = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final payments = context.watch<PaymentProvider>();
    final inventory = context.watch<InventoryProvider>();
    final utang = context.watch<UtangProvider>();
    final now = DateTime.now();
    final dailyLabels = _dailyDateLabels(now);
    final weeklyLabels = _weeklyDateLabels(now);
    final dailySales = _combineSales(
      inventory.weeklySalesByDay(),
      utang.weeklySalesByDay(),
      length: dailyLabels.length,
    );
    final weeklySales = _combineSales(
      inventory.weeklySalesByWeek(weeks: weeklyLabels.length),
      utang.weeklySalesByWeek(weeks: weeklyLabels.length),
      length: weeklyLabels.length,
    );
    final data = _isWeekly ? weeklySales : dailySales;
    final labels = _isWeekly ? weeklyLabels : dailyLabels;
    final periodStart = _isWeekly
        ? _startOfWeek(now).subtract(
            const Duration(days: DateTime.daysPerWeek * (_weeklyPointCount - 1)),
          )
        : _startOfWeek(now);
    final periodEnd = _startOfWeek(now).add(
      const Duration(days: DateTime.daysPerWeek - 1),
    );
    final periodLabel =
        '${_rangeDateFormatter.format(periodStart)} – ${_rangeDateFormatter.format(periodEnd)}';
    final totalSales = inventory.totalSales + utang.totalSales;
    final outstanding = payments.remainingOutstanding(utang.customers);
    final topSellingProducts = inventory.topSellingProducts();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      Text('Reports', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Daily'), icon: Icon(Icons.today_outlined)), ButtonSegment(value: true, label: Text('Weekly'), icon: Icon(Icons.date_range_outlined))], selected: {_isWeekly}, onSelectionChanged: (value) => setState(() => _isWeekly = value.first)),
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales visualization',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 3),
              Text(
                _isWeekly ? 'Weekly totals · $periodLabel' : 'Daily totals · $periodLabel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 240,
                child: CustomPaint(
                  painter: SalesBarChartPainter(data: data, labels: labels),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: _summaryCard('Total Sales', currencyFormatter.format(totalSales), Icons.point_of_sale_outlined, AppColors.primary)), const SizedBox(width: 12), Expanded(child: _summaryCard('Outstanding Utang', currencyFormatter.format(outstanding), Icons.receipt_long_outlined, AppColors.danger))]),
      const SizedBox(height: 20),
      const Text('Top-Selling Products', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 10),
      if (topSellingProducts.isEmpty)
        const Card(
          child: ListTile(
            leading: Icon(Icons.inventory_2_outlined),
            title: Text('No product sales recorded yet.'),
          ),
        )
      else
        ...topSellingProducts.map(
          (item) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.accent.withValues(alpha: .25),
                child: Text(item.$2.toString()),
              ),
              title: Text(
                item.$1,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: Text(
                item.$3,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
    ]);
  }

  List<double> _combineSales(
    List<double> first,
    List<double> second, {
    required int length,
  }) {
    return List<double>.generate(
      length,
      (index) =>
          (index < first.length ? first[index] : 0.0) +
          (index < second.length ? second[index] : 0.0),
    );
  }

  List<String> _dailyDateLabels(DateTime date) {
    final start = _startOfWeek(date);
    return List.generate(
      DateTime.daysPerWeek,
      (index) => _chartDateFormatter.format(
        start.add(Duration(days: index)),
      ),
    );
  }

  List<String> _weeklyDateLabels(DateTime date) {
    final currentWeekStart = _startOfWeek(date);
    final firstWeekStart = currentWeekStart.subtract(
      const Duration(days: DateTime.daysPerWeek * (_weeklyPointCount - 1)),
    );
    return List.generate(
      _weeklyPointCount,
      (index) => _chartDateFormatter.format(
        firstWeekStart.add(Duration(days: DateTime.daysPerWeek * index)),
      ),
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return start.subtract(Duration(days: start.weekday - DateTime.monday));
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
    final trackPaint = Paint()..color = AppColors.primary.withValues(alpha: .14);
    final gridPaint = Paint()..color = Colors.black12;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final count = labels.length;
    final visibleData = List<double>.generate(
      count,
      (index) => index < data.length ? data[index] : 0,
    );
    final maxValue = visibleData.isEmpty
        ? 0.0
        : visibleData.reduce((a, b) => a > b ? a : b);
    const left = 10.0, right = 10.0, bottom = 28.0, top = 12.0;
    final chartH =
        (size.height - bottom - top).clamp(0.0, double.infinity).toDouble();
    if (count == 0) return;
    final slotW = (size.width - left - right) / count;
    final barW = (slotW * .55).clamp(18.0, 44.0).toDouble();
    final baseY = top + chartH;
    for (var line = 0; line <= 3; line++) {
      final y = top + chartH * line / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var i = 0; i < count; i++) {
      final h = maxValue == 0 ? 0.0 : chartH * (visibleData[i] / maxValue);
      final centerX = left + slotW * i + slotW / 2;
      final x = centerX - barW / 2;
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
