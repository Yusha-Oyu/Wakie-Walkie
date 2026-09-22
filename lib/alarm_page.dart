import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmPage extends StatefulWidget {
  final int? triggeredAlarmId;
  const AlarmPage({super.key, this.triggeredAlarmId});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class AlarmItem {
  TimeOfDay time;
  bool enabled;

  AlarmItem({required this.time, this.enabled = false});
}

class _AlarmPageState extends State<AlarmPage> {
  // ─────────────────────────────────────────────
  // Audio / Pedometer
  // ─────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<StepCount>? _stepSub;

  // Multiple alarms = multiple timers
  final Map<int, Timer> _alarmTimers = {};

  // Steps / Alarm state
  int _initialSteps = -1;
  int stepsRequired = 5;
  int _stepsSinceAlarm = 0;
  int _rawSteps = 0;
  bool _isRinging = false;

  // Which alarm is currently ringing (for display/debug)
  int? _ringingAlarmIndex;

  // ─────────────────────────────────────────────
  // Alarm list UI state
  // ─────────────────────────────────────────────
  final List<AlarmItem> _alarms = [
    AlarmItem(time: const TimeOfDay(hour: 5, minute: 0), enabled: true),
    AlarmItem(time: const TimeOfDay(hour: 4, minute: 30), enabled: false),
    AlarmItem(time: const TimeOfDay(hour: 6, minute: 30), enabled: false),
  ];

  // Colors (mockup vibe)
  static const Color _bgTop = Color(0xFF1B1E23);
  static const Color _bgBottom = Color(0xFF2B2F36);
  static const Color _pillFill = Color(0xFF3A3F47);
  static const Color _textGold = Color(0xFFE7D28B);
  static const Color _switchOn = Color(0xFFE7C86A);
  static const Color _switchOff = Color(0xFFBFC6D0);

  @override
  void initState() {
    super.initState();
    _initPedometer();

    // Schedule any alarms that start as enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < _alarms.length; i++) {
        if (_alarms[i].enabled) {
          _scheduleAlarmForIndex(i, silent: true);
        }
      }
    });
  }

  @override
  void dispose() {
    for (final t in _alarmTimers.values) {
      t.cancel();
    }
    _alarmTimers.clear();

    _stepSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // PEDOMETER + PERMISSION
  // ─────────────────────────────────────────────
  Future<void> _initPedometer() async {
    if (kIsWeb) {
      debugPrint('Pedometer not supported on web');
      return;
    }

    var status = await Permission.activityRecognition.status;
    if (status.isDenied || status.isRestricted || status.isLimited) {
      status = await Permission.activityRecognition.request();
    }

    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity recognition permission is required for steps.'),
        ),
      );
      return;
    }

    _stepSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepError,
      onDone: _onStepDone,
      cancelOnError: false,
    );
  }

  void _onStepCount(StepCount event) {
    final totalSteps = event.steps;

    if (_initialSteps < 0) {
      _initialSteps = totalSteps;
    }

    final diff = totalSteps - _initialSteps;

    setState(() {
      _rawSteps = totalSteps;
      _stepsSinceAlarm = diff < 0 ? 0 : diff;
    });

    if (_isRinging && _stepsSinceAlarm >= stepsRequired) {
      _stopAlarm();
    }
  }

  void _onStepError(error) {
    debugPrint('Step Count Error: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Step sensor error: $error')),
    );
  }

  void _onStepDone() {
    debugPrint('Pedometer stream closed');
  }

  // ─────────────────────────────────────────────
  // Alarm scheduling (MULTIPLE)
  // ─────────────────────────────────────────────
  void _scheduleAlarmForIndex(int index, {bool silent = false}) {
    // Cancel existing timer for this alarm
    _alarmTimers[index]?.cancel();

    final alarmTime = _alarms[index].time;
    final now = DateTime.now();

    var alarmDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarmTime.hour,
      alarmTime.minute,
    );

    if (alarmDateTime.isBefore(now)) {
      alarmDateTime = alarmDateTime.add(const Duration(days: 1));
    }

    final duration = alarmDateTime.difference(now);

    _alarmTimers[index] = Timer(duration, () => _onAlarmTriggered(index));

    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alarm set for ${_formatTime(alarmTime)}')),
      );
    }
  }

  void _cancelAlarmForIndex(int index) {
    _alarmTimers[index]?.cancel();
    _alarmTimers.remove(index);
  }

  // ─────────────────────────────────────────────
  // Alarm sound start/stop
  // ─────────────────────────────────────────────
  Future<void> _startAlarm(int index) async {
    setState(() {
      _isRinging = true;
      _ringingAlarmIndex = index;
      _initialSteps = -1; // reset baseline so steps start counting fresh
      _stepsSinceAlarm = 0;
    });

    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(
      AssetSource('sounds/test.mp3'),
      volume: 1.0,
    );
  }

  Future<void> _stopAlarm() async {
    if (!_isRinging) return;

    await _audioPlayer.stop();

    // close dialog if open
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    setState(() {
      _isRinging = false;
      _ringingAlarmIndex = null;
      _initialSteps = -1;
      _stepsSinceAlarm = 0;
    });
  }

  Future<void> _onAlarmTriggered(int index) async {
    await _startAlarm(index);
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('Alarm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Alarm time: ${_formatTime(_alarms[index].time)}'),
              const SizedBox(height: 12),
              Text('Walk $stepsRequired steps to stop the alarm.'),
              const SizedBox(height: 12),
              Text(
                'Steps walked: $_stepsSinceAlarm / $stepsRequired',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );

    // Reschedule this alarm for the next day automatically (optional but typical)
    if (_alarms[index].enabled) {
      _scheduleAlarmForIndex(index, silent: true);
    }
  }

  // ─────────────────────────────────────────────
  // UI helpers
  // ─────────────────────────────────────────────
  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final ap = t.period == DayPeriod.am ? 'am' : 'pm';
    return "$h:$mm $ap";
  }

  Widget _pillRow({
    required Widget left,
    required Widget right,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: _pillFill.withOpacity(0.55),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            Expanded(child: left),
            right,
          ],
        ),
      ),
    );
  }

  Future<void> _addAlarm() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;

    setState(() {
      _alarms.add(AlarmItem(time: picked, enabled: true));
      _alarms.sort((a, b) {
        final am = a.time.hour * 60 + a.time.minute;
        final bm = b.time.hour * 60 + b.time.minute;
        return am.compareTo(bm);
      });
    });

    // Schedule the newly added enabled alarm
    final idx = _alarms.indexWhere(
      (a) => a.time.hour == picked.hour && a.time.minute == picked.minute,
    );
    if (idx != -1) {
      _scheduleAlarmForIndex(idx, silent: true);
    }
  }

  void _toggleAlarm(int index, bool enabled) {
    setState(() => _alarms[index].enabled = enabled);

    if (enabled) {
      _scheduleAlarmForIndex(index, silent: true);
    } else {
      _cancelAlarmForIndex(index);
    }
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(''),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Icon(Icons.nights_stay_rounded, size: 92, color: _textGold),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView.separated(
                    itemCount: _alarms.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      // Add alarm pill
                      if (i == _alarms.length) {
                        return _pillRow(
                          onTap: _addAlarm,
                          left: const Center(
                            child: Icon(Icons.alarm_add_rounded, color: _textGold, size: 30),
                          ),
                          right: const SizedBox(width: 44),
                        );
                      }

                      final alarm = _alarms[i];

                      return _pillRow(
                        // Tap to edit time
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: alarm.time,
                          );
                          if (picked == null) return;

                          setState(() => alarm.time = picked);

                          // If enabled, reschedule this alarm with new time
                          if (alarm.enabled) {
                            _scheduleAlarmForIndex(i, silent: true);
                          }
                        },
                        left: Text(
                          _formatTime(alarm.time),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _textGold,
                          ),
                        ),
                        right: Switch(
                          value: alarm.enabled,
                          onChanged: (v) => _toggleAlarm(i, v),
                          trackColor: WidgetStateProperty.resolveWith(
                            (_) => Colors.white.withOpacity(0.25),
                          ),
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            final isOn = states.contains(WidgetState.selected);
                            return isOn ? _switchOn : _switchOff;
                          }),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  'Steps: $_stepsSinceAlarm / $stepsRequired   |   Raw: $_rawSteps'
                  '${_ringingAlarmIndex == null ? '' : '   |   Ringing: #$_ringingAlarmIndex'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _onAlarmTriggered(0),
                      child: const Text('TEST', style: TextStyle(color: _textGold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}