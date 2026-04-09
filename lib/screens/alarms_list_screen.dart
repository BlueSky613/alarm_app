import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/alarm_service.dart';
import 'package:dawn_weaver/screens/add_edit_alarm_screen.dart';
import 'package:dawn_weaver/screens/premium_screen.dart';
import 'package:dawn_weaver/screens/settings_screen.dart';
import 'package:dawn_weaver/screens/home_screen.dart';
import 'package:dawn_weaver/l10n/app_localizations.dart';
import 'package:dawn_weaver/widgets/wallet_alarm_gate.dart';
import 'package:dawn_weaver/widgets/add_alarm_fab.dart';

const Color _kPrimary = Color(0xFF0EF196);
const Color _kBackgroundDark = Color(0xFF000000);

class AlarmsListScreen extends StatefulWidget {
  final String? highlightAlarmId;
  const AlarmsListScreen({super.key, this.highlightAlarmId});

  @override
  State<AlarmsListScreen> createState() => _AlarmsListScreenState();
}

class _AlarmsListScreenState extends State<AlarmsListScreen> {
  List<Alarms> _alarms = [];
  String? _highlightId;

  @override
  void initState() {
    super.initState();
    _highlightId = widget.highlightAlarmId;
    _loadAlarms();
    if (_highlightId != null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _highlightId = null);
      });
    }
  }

  Future<void> _loadAlarms() async {
    final alarms = await StorageService.getAlarms();
    setState(() {
      _alarms = alarms;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nonQuickAlarms = _alarms
        .where((a) => !a.id.startsWith('quick_') && !a.id.startsWith('snooze_'))
        .toList();

    return Scaffold(
      backgroundColor: _kBackgroundDark,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _alarms.isEmpty
                      ? _buildEmptyState()
                      : SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom:
                                24 +
                                100 +
                                MediaQuery.of(context).padding.bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              _buildStatsGrid(),
                              const SizedBox(height: 16),
                              ...nonQuickAlarms.map(
                                (alarm) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: AlarmCard(
                                    alarm: alarm,
                                    isHighlighted: _highlightId == alarm.id,
                                    onToggle: (isActive) =>
                                        _toggleAlarm(alarm.id, isActive),
                                    onEdit: () => _editAlarm(alarm),
                                    onDelete: () => _deleteAlarm(alarm.id),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (nonQuickAlarms.isNotEmpty)
            Positioned(
              bottom: 24 + MediaQuery.of(context).padding.bottom + 100,
              right: 24,
              child: AddAlarmFab(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => const AddEditAlarmScreen(),
                        ),
                      )
                      .then((_) => _loadAlarms());
                },
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _kPrimary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(Icons.alarm_on_rounded, color: _kPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).alarms,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final nonQuick = _alarms.where((a) => !a.id.contains('quick')).toList();
    final total = nonQuick.length;
    final active = nonQuick.where((a) => a.isActive).length;

    return Row(
      children: [
        Expanded(
          child: _buildGlassStatCard(
            label: 'TOTAL',
            value: total.toString(),
            valueColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGlassStatCard(
            label: 'ACTIVE',
            value: active.toString(),
            valueColor: _kPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassStatCard({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _kPrimary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kBackgroundDark,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(
            icon: Icons.home_outlined,
            label: 'HOME',
            isSelected: false,
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            ),
          ),
          _buildNavButton(
            icon: Icons.alarm_outlined,
            label: 'MY ALARMS',
            isSelected: true,
            onTap: () {},
          ),
          _buildNavButton(
            icon: Icons.diamond_outlined,
            label: 'PREMIUM',
            isSelected: false,
            onTap: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const PremiumScreen(),
                    ),
                  )
                  .then((_) => _loadAlarms());
            },
          ),
          _buildNavButton(
            icon: Icons.settings_outlined,
            label: 'SETTINGS',
            isSelected: false,
            onTap: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  )
                  .then((_) => _loadAlarms());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isPremium = label == 'PREMIUM';
    final displayLabel = isPremium ? 'PREMIUM' : label;
    final inactiveColor = Colors.white.withValues(alpha: 0.35);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: isSelected ? _kPrimary : inactiveColor),
            const SizedBox(height: 6),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? _kPrimary : inactiveColor,
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
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.alarm_off_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).noAlarmsYet,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).addYourFirstAlarm,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const AddEditAlarmScreen(),
                      ),
                    )
                    .then((_) => _loadAlarms());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  AppLocalizations.of(context).createFirstAlarm,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAlarm(String alarmId, bool isActive) async {
    final alarmIndex = _alarms.indexWhere((alarm) => alarm.id == alarmId);
    if (alarmIndex >= 0) {
      if (isActive) {
        final ok = await ensureWalletAllowsAlarmSave(context);
        if (!ok || !mounted) return;
      }

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
        title: Text(AppLocalizations.of(context).deleteAlarm),
        content: Text(AppLocalizations.of(context).clearDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppLocalizations.of(context).delete,
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
  final bool isHighlighted;
  final Function(bool) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    this.isHighlighted = false,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  bool _isAlarmToday(Alarms alarm) {
    final now = DateTime.now();
    final alarmTime = DateTime(
      now.year, now.month, now.day,
      alarm.time.hour, alarm.time.minute,
    );
    return alarmTime.isAfter(now);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hour = alarm.time.hour;
    final isAm = hour < 12;
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeStr =
        '${hour12.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}';
    final amPm = isAm ? 'AM' : 'PM';
    final opacity = alarm.isActive ? 1.0 : 0.6;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? _kPrimary.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHighlighted
                    ? _kPrimary.withValues(alpha: 0.6)
                    : alarm.isActive
                        ? _kPrimary.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.05),
                width: isHighlighted ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                amPm,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                          if (alarm.label.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              alarm.label,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Switch(
                      value: alarm.isActive,
                      onChanged: onToggle,
                      activeTrackColor: _kPrimary,
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          (alarm.repeatDays.isEmpty
                                  ? (_isAlarmToday(alarm)
                                      ? l10n.today
                                      : l10n.tomorrow)
                                  : alarm.repeatString)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: _kPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
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
