import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class TemperatureService {
  final _controller = StreamController<double>.broadcast();
  Stream<double> get stream => _controller.stream;

  Timer? _simTimer;
  final Random _random = Random();
  bool simulate = true;

  void start() {
    stop();
    if (simulate) {
      _simTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        final value = 18 + _random.nextDouble() * 10;
        addReading(double.parse(value.toStringAsFixed(1)));
      });
    }
  }

  void stop() {
    _simTimer?.cancel();
    _simTimer = null;
  }

  void addReading(double temp) {
    if (!_controller.isClosed) _controller.add(temp);
  }

  Future<void> connectToArduino() async {
    simulate = false;
    stop();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TemperatureService _service = TemperatureService();
  final List<_TempPoint> _history = [];
  double _temperature = 22.0;
  bool _connected = false;
  bool _alarmMuted = false;

  double _minComfort = 20.0;
  double _maxComfort = 26.0;

  late AnimationController _pulseController;
  StreamSubscription<double>? _sub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _service.start();
    _sub = _service.stream.listen((temp) {
      setState(() {
        _temperature = temp;
        _history.add(_TempPoint(temp, DateTime.now()));
        if (_history.length > 60) _history.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseController.dispose();
    _service.dispose();
    super.dispose();
  }

  String _statusText(double t) {
    if (t < _minComfort) return "❄️ Too Cold";
    if (t > _maxComfort) return "🔥 Too Hot";
    return "✅ Comfortable";
  }

  Color _statusColor(double t) {
    if (t < _minComfort || t > _maxComfort) return Colors.redAccent;
    return Colors.green;
  }

  double _normalized(double t) {
    const min = 10.0;
    const max = 35.0;
    return ((t - min) / (max - min)).clamp(0.0, 1.0);
  }

  void _manualRefresh() {
    if (_service.simulate) {
      final rand = Random();
      final newTemp = 18 + rand.nextDouble() * 10;
      _service.addReading(double.parse(newTemp.toStringAsFixed(1)));
    }
  }

  Future<void> _connectArduino() async {
    await _service.connectToArduino();
    setState(() {
      _connected = true;
    });
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusText(_temperature);
    final statusColor = _statusColor(_temperature);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade50, Colors.pink.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.baby_changing_station,
                    size: 28,
                    color: Colors.pinkAccent,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Baby Room Monitor',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: () async {
                      final res =
                          await showModalBottomSheet<Map<String, dynamic>>(
                            context: context,
                            builder: (_) => SettingsSheet(
                              min: _minComfort,
                              max: _maxComfort,
                              alarmMuted: _alarmMuted,
                            ),
                          );
                      if (res != null) {
                        setState(() {
                          _minComfort = (res['min'] as double?) ?? _minComfort;
                          _maxComfort = (res['max'] as double?) ?? _maxComfort;
                          _alarmMuted = (res['muted'] as bool?) ?? _alarmMuted;
                        });
                      }
                    },
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    // Left: gauge and actions
                    Expanded(
                      flex: 5,
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 220,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: CircularProgressIndicator(
                                        value: _normalized(_temperature),
                                        strokeWidth: 18,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              statusColor,
                                            ),
                                        backgroundColor: Colors.grey.shade200,
                                      ),
                                    ),
                                    ScaleTransition(
                                      scale: Tween(begin: 0.95, end: 1.05)
                                          .animate(
                                            CurvedAnimation(
                                              parent: _pulseController,
                                              curve: Curves.easeInOut,
                                            ),
                                          ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${_temperature.toStringAsFixed(1)} °C',
                                            style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pinkAccent,
                                    ),
                                    onPressed: _manualRefresh,
                                    icon: const Icon(Icons.sync),
                                    label: const Text('Refresh'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pinkAccent,
                                    ),
                                    onPressed: _connected
                                        ? null
                                        : _connectArduino,
                                    icon: Icon(
                                      _connected
                                          ? Icons.bluetooth_connected
                                          : Icons.bluetooth,
                                    ),
                                    label: Text(
                                      _connected
                                          ? 'Connected'
                                          : 'Connect Arduino',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (!_connected)
                                const Text(
                                  'Tip: implement connectToArduino() in TemperatureService to feed real data.',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right: trend and history
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Recent Trend',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 120,
                                    child: CustomPaint(
                                      painter: _SparklinePainter(
                                        _history.map((h) => h.value).toList(),
                                        min: 10,
                                        max: 35,
                                        color: Colors.pinkAccent,
                                      ),
                                      child: Container(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Last: ${_history.isNotEmpty ? _history.last.value.toStringAsFixed(1) : _temperature.toStringAsFixed(1)} °C',
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'Clear history',
                                            onPressed: _clearHistory,
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: _alarmMuted
                                                ? 'Unmute alarm'
                                                : 'Mute alarm',
                                            onPressed: () => setState(
                                              () => _alarmMuted = !_alarmMuted,
                                            ),
                                            icon: Icon(
                                              _alarmMuted
                                                  ? Icons.volume_off
                                                  : Icons.volume_up,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Make the history card flexible to avoid overflow
                          Expanded(
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'History',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: _history.isEmpty
                                          ? const Center(
                                              child: Text('No history yet'),
                                            )
                                          : Builder(
                                              builder: (context) {
                                                final rev = _history.reversed
                                                    .toList();
                                                return ListView.separated(
                                                  itemCount: rev.length,
                                                  separatorBuilder: (_, __) =>
                                                      const Divider(height: 8),
                                                  itemBuilder: (context, idx) {
                                                    final item = rev[idx];
                                                    final txt =
                                                        '${item.value.toStringAsFixed(1)} °C';
                                                    final time =
                                                        TimeOfDay.fromDateTime(
                                                          item.time,
                                                        ).format(context);
                                                    final isOut =
                                                        item.value <
                                                            _minComfort ||
                                                        item.value >
                                                            _maxComfort;
                                                    return ListTile(
                                                      dense: true,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      leading: Icon(
                                                        item.value < _minComfort
                                                            ? Icons.ac_unit
                                                            : (item.value >
                                                                      _maxComfort
                                                                  ? Icons
                                                                        .local_fire_department
                                                                  : Icons
                                                                        .check_circle),
                                                        color: isOut
                                                            ? Colors.redAccent
                                                            : Colors.green,
                                                      ),
                                                      title: Text(
                                                        txt,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      subtitle: Text(time),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Auto-updating${_service.simulate ? ' (simulator)' : ''} • Last update: ${_history.isNotEmpty ? _formatTime(_history.last.time) : _formatTime(DateTime.now())}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }
}

class _TempPoint {
  final double value;
  final DateTime time;
  _TempPoint(this.value, this.time);
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final double min;
  final double max;
  final Color color;

  _SparklinePainter(
    this.values, {
    this.min = 10,
    this.max = 35,
    this.color = Colors.blue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (values.isEmpty) return;

    final normalized = values
        .map((v) => ((v - min) / (max - min)).clamp(0.0, 1.0))
        .toList();

    final step = normalized.length <= 1
        ? 0.0
        : size.width / (normalized.length - 1);

    final path = Path();
    for (int i = 0; i < normalized.length; i++) {
      final x = i * step;
      final y = size.height - (normalized[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final shadowPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, shadowPaint);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class SettingsSheet extends StatefulWidget {
  final double min;
  final double max;
  final bool alarmMuted;
  const SettingsSheet({
    Key? key,
    required this.min,
    required this.max,
    required this.alarmMuted,
  }) : super(key: key);

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late double _min;
  late double _max;
  late bool _muted;

  @override
  void initState() {
    super.initState();
    _min = widget.min;
    _max = widget.max;
    _muted = widget.alarmMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(
        16.0,
      ).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Comfort range:'),
              const SizedBox(width: 12),
              Text(
                '${_min.toStringAsFixed(1)}°C - ${_max.toStringAsFixed(1)}°C',
              ),
            ],
          ),
          Slider(
            value: _min,
            min: 10,
            max: 30,
            divisions: 40,
            label: _min.toStringAsFixed(1),
            onChanged: (v) => setState(() {
              _min = min(v, _max - 0.5);
            }),
          ),
          Slider(
            value: _max,
            min: 20,
            max: 40,
            divisions: 40,
            label: _max.toStringAsFixed(1),
            onChanged: (v) => setState(() {
              _max = max(v, _min + 0.5);
            }),
          ),
          SwitchListTile(
            value: _muted,
            onChanged: (v) => setState(() => _muted = v),
            title: const Text('Mute alarms'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop({'min': _min, 'max': _max, 'muted': _muted}),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
