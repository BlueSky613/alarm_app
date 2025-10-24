import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/models/user_profile.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/alarm_service.dart';
import 'package:dawn_weaver/screens/alarms_list_screen.dart';
import 'package:dawn_weaver/screens/add_edit_alarm_screen.dart';
import 'package:dawn_weaver/screens/settings_screen.dart';
import 'package:dawn_weaver/screens/user_setup_screen.dart';
import 'package:dawn_weaver/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Alarms> _alarms = [];
  UserProfile? _userProfile;
  DateTime _currentTime = DateTime.now();
  late Stream<DateTime> _timeStream;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadData();
    _startTimeStream();
  }

  void _initializeServices() async {
    await AlarmService.initialize();
  }

  void _startTimeStream() {
    _timeStream =
        Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
    _timeStream.listen((time) {
      if (mounted) {
        setState(() {
          _currentTime = time;
        });
      }
    });
  }

  Future<void> _loadData() async {
    final alarms = await StorageService.getAlarms();
    final profile = await StorageService.getUserProfile();
    final isFirstRun = await StorageService.isFirstRun();

    setState(() {
      _alarms = alarms;
      _userProfile = profile;
    });

    if (isFirstRun || profile == null) {
      if (mounted) {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => const UserSetupScreen(),
              ),
            )
            .then((_) => _loadData());
      }
    }
  }

  Alarms? get _nextAlarm {
    final activeAlarms = _alarms.where((alarm) => alarm.isActive).toList();
    if (activeAlarms.isEmpty) return null;

    final now = DateTime.now();
    Alarms? nextAlarm;
    DateTime? nextTime;

    for (final alarm in activeAlarms) {
      var alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.time.hour,
        alarm.time.minute,
      );

      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      if (nextTime == null || alarmTime.isBefore(nextTime)) {
        nextTime = alarmTime;
        nextAlarm = alarm;
      }
    }

    return nextAlarm;
  }

  String get _timeUntilNextAlarm {
    final nextAlarm = _nextAlarm;
    if (nextAlarm == null) return '';

    final now = DateTime.now();
    var alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      nextAlarm.time.hour,
      nextAlarm.time.minute,
    );

    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    final difference = alarmTime.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60 + 1;

    if (hours == 0) {
      return '${minutes}m';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildTimeDisplay(),
              const SizedBox(height: 30),
              _buildNextAlarmCard(),
              const SizedBox(height: 30),
              _buildQuickActions(),
              const Spacer(),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    final greeting = _userProfile != null
        ? l10n.helloName(_userProfile!.name)
        : l10n.welcome;
    final timeOfDay = _currentTime.hour < 12
        ? l10n.goodMorning
        : _currentTime.hour < 17
            ? l10n.goodAfternoon
            : l10n.goodEvening;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeOfDay,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    )
                    .then((_) => _loadData());
              },
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('EEEE, MMMM d').format(_currentTime),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildTimeDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(
            DateFormat('HH:mm').format(_currentTime),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          Text(
            DateFormat('ss').format(_currentTime),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAlarmCard() {
    final nextAlarm = _nextAlarm;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: nextAlarm != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.alarm,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).nextAlarm,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(nextAlarm.time),
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                        Text(
                          nextAlarm.label.isNotEmpty
                              ? nextAlarm.label
                              : nextAlarm.repeatString,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.8),
                                  ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppLocalizations.of(context).inTime,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                        Text(
                          _timeUntilNextAlarm,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                Icon(
                  Icons.alarm_off,
                  size: 48,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).noActiveAlarms,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).tapToCreateFirstAlarm,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActions() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.alarm_add,
            label: l10n.quickAlarm,
            subtitle: l10n.minutes15,
            onTap: () => _createQuickAlarm(15),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.bedtime,
            label: l10n.powerNap,
            subtitle: l10n.minutes20,
            onTap: () => _createQuickAlarm(20),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavButton(
          icon: Icons.list,
          label: l10n.alarms,
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => const AlarmsListScreen(),
                  ),
                )
                .then((_) => _loadData());
          },
        ),
        _buildNavButton(
          icon: Icons.add_circle,
          label: l10n.addAlarm,
          isPrimary: true,
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => const AddEditAlarmScreen(),
                  ),
                )
                .then((_) => _loadData());
          },
        ),
        _buildNavButton(
          icon: Icons.person,
          label: l10n.profile,
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                )
                .then((_) => _loadData());
          },
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
              size: isPrimary ? 28 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isPrimary
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _createQuickAlarm(int minutes) async {
    final l10n = AppLocalizations.of(context);
    final quickAlarmTime = DateTime.now().add(Duration(minutes: minutes));
    final quickAlarm = Alarms(
      id: 'quick_${DateTime.now().millisecondsSinceEpoch}',
      time: quickAlarmTime,
      label: minutes == 15 ? l10n.quickAlarm : l10n.powerNap,
      hasMotivation: true,
    );

    await StorageService.saveAlarm(quickAlarm);
    await AlarmService.scheduleAlarm(quickAlarm);

    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n
              .quickAlarmSetFor(DateFormat('HH:mm').format(quickAlarmTime))),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}
