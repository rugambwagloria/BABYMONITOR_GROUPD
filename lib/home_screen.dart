import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'trends_page.dart';
import 'database_helper.dart';

class BabyMonitorService {
  final _tempController = StreamController<double>.broadcast();
  final _noiseController = StreamController<double>.broadcast();

  Stream<double> get temperatureStream => _tempController.stream;
  Stream<double> get noiseStream => _noiseController.stream;

  Timer? _simTimer;
  final Random _random = Random();

  void start() {
    stop();
    _simTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final temp = 18 + _random.nextDouble() * 10; // 18–28 °C
      final noise = 30 + _random.nextDouble() * 50; // 30–80 dB
      _tempController.add(double.parse(temp.toStringAsFixed(1)));
      _noiseController.add(double.parse(noise.toStringAsFixed(1)));
    });
  }

  void stop() {
    _simTimer?.cancel();
    _simTimer = null;
  }

  void dispose() {
    stop();
    _tempController.close();
    _noiseController.close();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final BabyMonitorService _service = BabyMonitorService();
  double _temperature = 22.0;
  double _noise = 45.0;
  final List<double> _tempHistory = [];
  final List<double> _noiseHistory = [];

  late AnimationController _pulse;
  StreamSubscription<double>? _tempSub;
  StreamSubscription<double>? _noiseSub;

  final double _minComfort = 20;
  final double _maxComfort = 26;
  final double _noiseThreshold = 60;
  bool _alarmMuted = false;

  String _babyName = "Baby";
  String _parentName = "Parent";

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _service.start();
    _loadProfile();

    _tempSub = _service.temperatureStream.listen((t) {
      setState(() {
        _temperature = t;
        _tempHistory.add(t);
        if (_tempHistory.length > 50) _tempHistory.removeAt(0);
      });
    });

    _noiseSub = _service.noiseStream.listen((n) {
      setState(() {
        _noise = n;
        _noiseHistory.add(n);
        if (_noiseHistory.length > 50) _noiseHistory.removeAt(0);
      });
    });
  }

  Future<void> _loadProfile() async {
    final profiles = await DatabaseHelper.instance.getBabyProfiles();
    if (profiles.isNotEmpty) {
      final p = profiles.first;
      setState(() {
        _babyName = p['name'] ?? 'Baby';
      });
    }
    // parent name from user table (first user)
    final users = await DatabaseHelper.instance.getUsersAll();
    if (users.isNotEmpty) {
      setState(() {
        _parentName = users.first['email'] ?? 'Parent';
      });
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _service.dispose();
    _tempSub?.cancel();
    _noiseSub?.cancel();
    super.dispose();
  }

  String _tempStatus() {
    if (_temperature < _minComfort) return "❄️ Too Cold";
    if (_temperature > _maxComfort) return "🔥 Too Hot";
    return "✅ Comfortable";
  }

  String _noiseStatus() {
    if (_noise > _noiseThreshold) return "🔊 Too Loud";
    return "🔈 Calm";
  }

  Color _statusColor(String status) {
    if (status.contains("Too")) return Colors.redAccent;
    return Colors.green;
  }

  double _normalize(double v, double min, double max) {
    return ((v - min) / (max - min)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final tempStatus = _tempStatus();
    final noiseStatus = _noiseStatus();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, $_parentName — monitoring $_babyName'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "View Trends",
            icon: const Icon(Icons.show_chart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrendsPage(
                    tempHistory: _tempHistory,
                    noiseHistory: _noiseHistory,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: "Tips",
            icon: const Icon(Icons.lightbulb),
            onPressed: () => Navigator.pushNamed(context, '/tips'),
          ),
          IconButton(
            tooltip: "Settings",
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCard(
                title: "Temperature",
                icon: Icons.thermostat,
                value: "${_temperature.toStringAsFixed(1)} °C",
                status: tempStatus,
                color: _statusColor(tempStatus),
                progress: _normalize(_temperature, 10, 35),
                history: _tempHistory,
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: "Noise Level",
                icon: Icons.volume_up,
                value: "${_noise.toStringAsFixed(1)} dB",
                status: noiseStatus,
                color: _statusColor(noiseStatus),
                progress: _normalize(_noise, 30, 80),
                history: _noiseHistory,
              ),
              const SizedBox(height: 16),
              _buildSettingsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required String value,
    required String status,
    required Color color,
    required double progress,
    required List<double> history,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                ScaleTransition(
                  scale: Tween(begin: 0.95, end: 1.05).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: Column(
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              width: double.infinity,
              child: CustomPaint(painter: _MiniGraph(history, color)),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildSettingsCard(BuildContext context) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(Icons.settings, color: Theme.of(context).primaryColor),
      title: const Text("Quick Settings"),
      subtitle: Text(
        "Comfort: ${_minComfort.toStringAsFixed(1)}–${_maxComfort.toStringAsFixed(1)} °C\nNoise limit: ${_noiseThreshold.toStringAsFixed(0)} dB",
      ),
      trailing: Switch(
        value: _alarmMuted,
        onChanged: (v) => setState(() => _alarmMuted = v),
      ),
      onTap: () => Navigator.pushNamed(context, '/settings'),
    ),
  );
}
}

class _MiniGraph extends CustomPainter {
  final List<double> values;
  final Color color;

  _MiniGraph(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
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
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniGraph oldDelegate) =>
      oldDelegate.values != values;
}
