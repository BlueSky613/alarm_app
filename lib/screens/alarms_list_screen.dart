import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/alarm_service.dart';
import 'package:dawn_weaver/screens/add_edit_alarm_screen.dart';

class AlarmsListScreen extends StatefulWidget {
  const AlarmsListScreen({super.key});

  @override
  State<AlarmsListScreen> createState() => _AlarmsListScreenState();
}

class _AlarmsListScreenState extends State<AlarmsListScreen> {
  List<Alarms> _alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final alarms = await StorageService.getAlarms();
    setState(() {
      _alarms = alarms;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Alarms'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const AddEditAlarmScreen(),
                    ),
                  )
                  .then((_) => _loadAlarms());
            },
            icon: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      body: _alarms.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _alarms.length,
                      itemBuilder: (context, index) {
                        final alarm = _alarms[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AlarmCard(
                            alarm: alarm,
                            onToggle: (isActive) =>
                                _toggleAlarm(alarm.id, isActive),
                            onEdit: () => _editAlarm(alarm),
                            onDelete: () => _deleteAlarm(alarm.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.alarm_off,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Alarms Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first alarm to start waking up with personalized greetings and content',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const AddEditAlarmScreen(),
                      ),
                    )
                    .then((_) => _loadAlarms());
              },
              icon: const Icon(Icons.add),
              label: const Text('Create First Alarm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final activeAlarms = _alarms.where((alarm) => alarm.isActive).length;
    final inactiveAlarms = _alarms.length - activeAlarms;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', _alarms.length.toString()),
          Container(
            height: 40,
            width: 1,
            color: Theme.of(context)
                .colorScheme
                .onPrimaryContainer
                .withValues(alpha: 0.3),
          ),
          _buildStatItem('Active', activeAlarms.toString()),
          Container(
            height: 40,
            width: 1,
            color: Theme.of(context)
                .colorScheme
                .onPrimaryContainer
                .withValues(alpha: 0.3),
          ),
          _buildStatItem('Inactive', inactiveAlarms.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }

  void _toggleAlarm(String alarmId, bool isActive) async {
    final alarmIndex = _alarms.indexWhere((alarm) => alarm.id == alarmId);
    if (alarmIndex >= 0) {
      final updatedAlarm = _alarms[alarmIndex].copyWith(isActive: isActive);
      await StorageService.saveAlarm(updatedAlarm);

      if (isActive) {
        await AlarmService.scheduleAlarm(updatedAlarm);
      } else {
        await AlarmService.cancelAlarm(alarmId);
      }

      _loadAlarms();
    }
  }

  void _editAlarm(Alarms alarm) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddEditAlarmScreen(alarm: alarm),
          ),
        )
        .then((_) => _loadAlarms());
  }

  void _deleteAlarm(String alarmId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: const Text('Are you sure you want to delete this alarm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteAlarm(alarmId);
      await AlarmService.cancelAlarm(alarmId);
      _loadAlarms();
    }
  }
}

class AlarmCard extends StatelessWidget {
  final Alarms alarm;
  final Function(bool) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alarm.isActive
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alarm.isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: alarm.isActive
            ? [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(alarm.time),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: alarm.isActive
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                              ),
                    ),
                    if (alarm.label.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        alarm.label,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: alarm.isActive
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      alarm.repeatString,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: alarm.isActive
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4),
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: alarm.isActive,
                onChanged: onToggle,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFeatureChip(
                  context,
                  Icons.star,
                  'Horoscope',
                  alarm.hasHoroscope,
                ),
                const SizedBox(width: 8),
                _buildFeatureChip(
                  context,
                  Icons.lightbulb_outline,
                  'Motivation',
                  alarm.hasMotivation,
                ),
                const SizedBox(width: 8),
                _buildFeatureChip(
                  context,
                  Icons.cloud,
                  'Weather',
                  alarm.hasWeather,
                ),
                // const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(
    BuildContext context,
    IconData icon,
    String label,
    bool isEnabled,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isEnabled
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isEnabled
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isEnabled
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                  fontWeight: isEnabled ? FontWeight.w500 : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}
