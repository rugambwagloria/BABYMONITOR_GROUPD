import 'package:flutter/material.dart';
import 'dart:math';

class TrendsPage extends StatelessWidget {
  final List<double> tempHistory;
  final List<double> noiseHistory;

  const TrendsPage({
    super.key,
    required this.tempHistory,
    required this.noiseHistory,
  });

  @override
  Widget build(BuildContext context) {
    final avgTemp = tempHistory.isEmpty
        ? 0
        : tempHistory.reduce((a, b) => a + b) / tempHistory.length;
    final avgNoise = noiseHistory.isEmpty
        ? 0
        : noiseHistory.reduce((a, b) => a + b) / noiseHistory.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Trends"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTrendCard(
              title: "Temperature Trend",
              color: Theme.of(context).primaryColor,
              values: tempHistory,
              avg: "${avgTemp.toStringAsFixed(1)} °C",
              icon: Icons.thermostat,
            ),
            const SizedBox(height: 16),
            _buildTrendCard(
              title: "Noise Trend",
              color: Theme.of(context).primaryColor,
              values: noiseHistory,
              avg: "${avgNoise.toStringAsFixed(1)} dB",
              icon: Icons.volume_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard({
    required String title,
    required Color color,
    required List<double> values,
    required String avg,
    required IconData icon,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("Avg: $avg", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              width: double.infinity,
              child: CustomPaint(painter: _TrendPainter(values, color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _TrendPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final range = (maxV - minV).abs() < 0.1 ? 1.0 : (maxV - minV);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * (size.width / (values.length - 1));
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final shadow = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, shadow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.values != values;
}
