import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isWeekly = false;

  final _daily = <double>[280, 420, 310, 650, 510, 790, 620, 910, 730, 860, 540, 390];
  final _weeklyData = <double>[3200, 4100, 3650, 4920, 4450, 5180, 4865];

  @override
  Widget build(BuildContext context) {
    final data = _isWeekly ? _weeklyData : _daily;
    final totalSales = _isWeekly ? 30365.0 : 6970.0;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      Text('Reports', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Daily'), icon: Icon(Icons.today_outlined)), ButtonSegment(value: true, label: Text('Weekly'), icon: Icon(Icons.date_range_outlined))], selected: {_isWeekly}, onSelectionChanged: (value) => setState(() => _isWeekly = value.first)),
      const SizedBox(height: 18),
      Card(child: Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Sales visualization', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), const SizedBox(height: 10), SizedBox(height: 240, child: CustomPaint(painter: SalesBarChartPainter(data: data, labels: _isWeekly ? const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'] : const ['7a','8a','9a','10a','11a','12p','1p','2p','3p','4p','5p','6p'])))]))),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: _summaryCard('Total Sales', currencyFormatter.format(totalSales), Icons.point_of_sale_outlined, AppColors.primary)), const SizedBox(width: 12), Expanded(child: _summaryCard('Outstanding Utang', currencyFormatter.format(2485.00), Icons.receipt_long_outlined, AppColors.danger))]),
      const SizedBox(height: 20),
      const Text('Top-Selling Products', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 10),
      ...const [
        ('Lucky Me! Pancit Canton', 86, '₱1,548'),
        ('Coca-Cola 1.5L', 62, '₱4,836'),
        ('Nescafé Classic 25g', 54, '₱2,268'),
        ('SkyFlakes Crackers', 49, '₱490'),
        ('Safeguard Soap', 37, '₱962'),
      ].map((item) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: AppColors.accent.withValues(alpha: .25), child: Text(item.$2.toString())), title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)), trailing: Text(item.$3, style: const TextStyle(fontWeight: FontWeight.w800))))),
    ]);
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
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    const left = 8.0, bottom = 28.0, top = 12.0;
    final chartH = size.height - bottom - top;
    const gap = 8.0;
    final barW = (size.width - left - gap * (data.length - 1)) / data.length;
    final baseY = top + chartH;
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), Paint()..color = Colors.black12);
    for (var i = 0; i < data.length; i++) {
      final h = chartH * (data[i] / maxValue);
      final x = left + i * (barW + gap);
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x, baseY - h, barW, h), const Radius.circular(6));
      canvas.drawRRect(rect, paint);
      textPainter.text = TextSpan(text: labels[i], style: const TextStyle(fontSize: 10, color: Colors.black54));
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + (barW - textPainter.width) / 2, baseY + 7));
    }
  }

  @override
  bool shouldRepaint(covariant SalesBarChartPainter oldDelegate) => oldDelegate.data != data || oldDelegate.labels != labels;
}
