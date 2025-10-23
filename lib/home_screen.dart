import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'trends_Page.dart'; // make sure this matches your file name

/// Simulates both temperature and noise readings.
class BabyMonitorService {
  final _tempController = StreamController<double>.broadcast();
  final _noiseController = StreamController<double>.broadcast();

  Stream<double> get temperatureStream => _tempController.stream;
  Stream<double> get noiseStream => _noiseController.stream;

  Timer? _simTimer;
  final Random _random = Random();

  void start() {
    stop();
    // Simulate new readings every 2 seconds
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

/// The main mobile-friendly screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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

  double _minComfort = 20;
  double _maxComfort = 26;
  double _noiseThreshold = 60; // dB threshold for too loud
  bool _alarmMuted = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _service.start();

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('👶 Baby Monitor'),
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
                Icon(icon, color: Colors.pinkAccent),
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
        leading: const Icon(Icons.settings, color: Colors.pinkAccent),
        title: const Text("Settings"),
        subtitle: Text(
          "Comfort: ${_minComfort.toStringAsFixed(1)}–${_maxComfort.toStringAsFixed(1)} °C\nNoise limit: $_noiseThreshold dB",
        ),
        trailing: Switch(
          value: _alarmMuted,
          onChanged: (v) => setState(() => _alarmMuted = v),
        ),
        onTap: () async {
          await showModalBottomSheet(
            context: context,
            builder: (_) => _SettingsSheet(
              min: _minComfort,
              max: _maxComfort,
              noise: _noiseThreshold,
              muted: _alarmMuted,
              onSave: (min, max, noise, muted) {
                setState(() {
                  _minComfort = min;
                  _maxComfort = max;
                  _noiseThreshold = noise;
                  _alarmMuted = muted;
                });
              },
            ),
          );
        },
      ),
    );
  }
}

/// Small graph painter
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
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniGraph oldDelegate) =>
      oldDelegate.values != values;
}

/// Settings bottom sheet
class _SettingsSheet extends StatefulWidget {
  final double min;
  final double max;
  final double noise;
  final bool muted;
  final Function(double, double, double, bool) onSave;

  const _SettingsSheet({
    required this.min,
    required this.max,
    required this.noise,
    required this.muted,
    required this.onSave,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late double _min;
  late double _max;
  late double _noise;
  late bool _muted;

  @override
  void initState() {
    super.initState();
    _min = widget.min;
    _max = widget.max;
    _noise = widget.noise;
    _muted = widget.muted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Settings",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Temperature Comfort Range: ${_min.toStringAsFixed(1)}–${_max.toStringAsFixed(1)} °C",
          ),
          RangeSlider(
            min: 10,
            max: 35,
            values: RangeValues(_min, _max),
            onChanged: (v) => setState(() {
              _min = v.start;
              _max = v.end;
            }),
          ),
          const SizedBox(height: 12),
          Text("Noise Threshold: ${_noise.toStringAsFixed(0)} dB"),
          Slider(
            min: 40,
            max: 90,
            value: _noise,
            divisions: 10,
            onChanged: (v) => setState(() => _noise = v),
          ),
          SwitchListTile(
            value: _muted,
            onChanged: (v) => setState(() => _muted = v),
            title: const Text("Mute Alarms"),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onSave(_min, _max, _noise, _muted);
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
