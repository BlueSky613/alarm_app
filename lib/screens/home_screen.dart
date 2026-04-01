import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/models/user_profile.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/alarm_service.dart';
import 'package:dawn_weaver/screens/add_edit_alarm_screen.dart';
import 'package:dawn_weaver/screens/alarms_list_screen.dart';
import 'package:dawn_weaver/screens/premium_screen.dart';
import 'package:dawn_weaver/screens/settings_screen.dart';
import 'package:dawn_weaver/screens/user_setup_screen.dart';
import 'package:dawn_weaver/l10n/app_localizations.dart';
import 'package:dawn_weaver/widgets/wallet_alarm_gate.dart';
import 'package:dawn_weaver/widgets/add_alarm_fab.dart';
import 'package:dawn_weaver/app_route_observer.dart';
import 'package:dawn_weaver/utils/profile_avatar.dart';

/// Dashboard UI colors from reference (dashboard.html).
const Color _kPrimary = Color(0xFF0EF196);
const Color _kSolanaPurple = Color(0xFF9945FF);
const Color _kBackgroundDark = Color(0xFF000000);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadData();
  }

  void _initializeServices() async {
    await AlarmService.initialize();
  }

  void _startTimeStream() {
    _timeStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
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
              MaterialPageRoute(builder: (context) => const UserSetupScreen()),
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

  void _openAlarmsList() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AlarmsListScreen()))
        .then((_) => _loadData());
  }

  void _openAddAlarmScreen() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const AddEditAlarmScreen()),
        )
        .then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _kBackgroundDark,
      bottomNavigationBar: SafeArea(
        top: false,
        child: _buildBottomNavigation(),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.2,
                child: Image.asset(
                  'assets/solrise_logo.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 24 + 100 + bottomInset,
            ),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildTimeDisplay(),
                const SizedBox(height: 24),
                _buildNextAlarmCard(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildAIBanner(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            bottom: 24 + bottomInset,
            right: 24,
            child: Tooltip(
              message: AppLocalizations.of(context).addAlarm,
              child: AddAlarmFab(onPressed: _openAddAlarmScreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final name = _userProfile?.name;
    final walletAddress = _userProfile?.solanaAddress;
    final tierLabel = name != null && name.isNotEmpty ? 'Seeker Pro' : 'Seeker';
    final subtitle = walletAddress != null && walletAddress.isNotEmpty
        ? 'Solana Mainnet'
        : 'Solana Mainnet';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _kSolanaPurple.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Image(
                      image: _userProfile != null
                          ? avatarImageProviderFromRef(_userProfile!.avatarRef)
                          : const AssetImage('assets/solrise_logo.png'),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return ColoredBox(
                          color: _kSolanaPurple.withValues(alpha: 0.2),
                          child: Center(
                            child: Text(
                              name != null && name.isNotEmpty
                                  ? name.substring(0, 1).toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tierLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: Color(0xFF9945FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
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
              Icons.settings_outlined,
              color: Colors.white.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  static final TextStyle _timeTextStyle = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.bold,
    letterSpacing: -2,
    color: Colors.white,
    shadows: [Shadow(color: _kPrimary.withValues(alpha: 0.5), blurRadius: 10)],
  );

  Widget _buildTimeDisplay() {
    final hour = _currentTime.hour;
    final isAm = hour < 12;
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final hoursStr = hour12.toString().padLeft(2, '0');
    final minutesStr = _currentTime.minute.toString().padLeft(2, '0');
    final amPm = isAm ? 'am' : 'pm';
    final colonVisible = _currentTime.second % 2 == 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(hoursStr, style: _timeTextStyle),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: colonVisible ? 1.0 : 0.0,
              child: Text(':', style: _timeTextStyle),
            ),
            Text(minutesStr, style: _timeTextStyle),
            const SizedBox(width: 4),
            Text(
              amPm.toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextAlarmCard() {
    final nextAlarm = _nextAlarm;
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: nextAlarm != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.alarm_on_rounded,
                          color: _kPrimary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.nextAlarm,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextAlarm.label.isNotEmpty
                                  ? nextAlarm.label
                                  : (nextAlarm.repeatDays.isEmpty
                                        ? (nextAlarm.isActive
                                              ? l10n.today
                                              : l10n.tomorrow)
                                        : nextAlarm.repeatString),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l10n.inTime,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _timeUntilNextAlarm,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.alarm_off_rounded,
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noActiveAlarms,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    // const SizedBox(height: 4),
                    // Text(
                    //   l10n.tapToCreateFirstAlarm,
                    //   style: TextStyle(
                    //     fontSize: 12,
                    //     color: Colors.white.withValues(alpha: 0.6),
                    //   ),
                    // ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.alarm_on_rounded,
            label: l10n.quickAlarm,
            subtitle: l10n.minutes15,
            accentColor: _kSolanaPurple,
            onTap: () => _createQuickAlarm(15),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.dark_mode_rounded,
            label: l10n.powerNap,
            subtitle: l10n.minutes20,
            accentColor: _kPrimary,
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
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kSolanaPurple, Color(0xFF4E2D8A)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Transform.translate(
                offset: const Offset(24, 0),
                child: Transform.rotate(
                  angle: -0.785,
                  child: Container(
                    width: 128,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Go Premium',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Get unlimited access to all AI characters and your favorite premium alarm music.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (context) => const PremiumScreen(),
                                  ),
                                )
                                .then((_) => _loadData());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'GET STARTED',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.auto_fix_high_rounded,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ],
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
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(
            icon: Icons.home_outlined,
            label: 'HOME',
            isSelected: true,
            onTap: () {},
          ),
          _buildNavButton(
            icon: Icons.alarm_outlined,
            label: 'MY ALARMS',
            isSelected: false,
            onTap: _openAlarmsList,
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
                  .then((_) => _loadData());
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
                  .then((_) => _loadData());
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
    final isPremium = label == 'Premium';
    final displayLabel = isPremium ? 'Premium' : label;
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

  void _createQuickAlarm(int minutes) async {
    final l10n = AppLocalizations.of(context);
    final ok = await ensureWalletAllowsAlarmSave(context);
    if (!ok || !mounted) return;

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
          content: Text(
            l10n.quickAlarmSetFor(DateFormat('HH:mm').format(quickAlarmTime)),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}
