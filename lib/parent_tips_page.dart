import 'dart:math';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class ParentTipsPage extends StatefulWidget {
  const ParentTipsPage({super.key});

  @override
  State<ParentTipsPage> createState() => _ParentTipsPageState();
}

class _ParentTipsPageState extends State<ParentTipsPage> {
  final List<String> _tipsPool = [
    "Maintain room temperature between 20–24°C for comfortable sleep.",
    "Reduce noisy toys in the baby’s room during naps.",
    "Establish a bedtime routine: bath, feed, dim lights, lullaby.",
    "Use soft white noise if the baby is sensitive to sudden sounds.",
    "Keep the crib area free of loose bedding and toys.",
    "Check the baby’s temperature if they seem unusually restless.",
    "Skin-to-skin contact soothes many newborns and helps sleep.",
  ];

  final Random _rand = Random();
  String _generatedTip = "";
  String _insight = "";

  @override
  void initState() {
    super.initState();
    _generateTip();
    _generateInsight();
  }

  Future<void> _generateTip() async {
    setState(() {
      _generatedTip = _tipsPool[_rand.nextInt(_tipsPool.length)];
    });
  }

  Future<void> _generateInsight() async {
    final temps = await DatabaseHelper.instance.getRecentTemps();
    final noises = await DatabaseHelper.instance.getRecentNoises();
    if (temps.isNotEmpty) {
      final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
      if (avgTemp < 19) {
        _insight = "Your baby's room has been slightly cool on average. Consider a light blanket or warmer clothing.";
      } else if (avgTemp > 27) {
        _insight = "Average room temperature is high. Check for overheating and ensure good ventilation.";
      } else {
        _insight = "Temperature averages look good — within comfortable ranges.";
      }
    } else {
      _insight = "No recent sensor data available — try monitoring for a few minutes.";
    }

    if (noises.isNotEmpty) {
      final avgNoise = noises.reduce((a, b) => a + b) / noises.length;
      if (avgNoise > 65) {
        _insight += " Also, noise levels tend to be high — look for noisy appliances or sources.";
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Parent Tips & Insights")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: const Text("Today's Tip"),
                subtitle: Text(_generatedTip),
                trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _generateTip),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.insights),
                title: const Text("Insight"),
                subtitle: Text(_insight),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.check),
                    title: const Text("Safety Reminder"),
                    subtitle: const Text("Always place baby on their back to sleep and keep the crib free of soft objects."),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_note),
                    title: const Text("Feeding Tip"),
                    subtitle: const Text("Feed on demand; track weight changes using the profile page."),
                  ),
                  ListTile(
                    leading: const Icon(Icons.health_and_safety),
                    title: const Text("When to seek help"),
                    subtitle: const Text("If baby has a fever (>38°C) or persistent high-pitched crying, consult a doctor."),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
