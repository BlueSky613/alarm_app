import 'package:flutter/material.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/alarm_service.dart';
import 'package:dawn_weaver/services/content_service.dart';

class AddEditAlarmScreen extends StatefulWidget {
  final Alarms? alarm;

  const AddEditAlarmScreen({super.key, this.alarm});

  @override
  State<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends State<AddEditAlarmScreen> {
  late TimeOfDay _selectedTime;
  final _labelController = TextEditingController();
  Set<int> _repeatDays = {};
  String _selectedVirtualCharacter = 'default';
  bool _hasHoroscope = false;
  bool _hasMotivation = true;
  bool _hasWeather = false;
  int _snoozeMinutes = 10;

  final List<String> _virtualCharacters = [
    'https://pixabay.com/get/ga9df13a5d2cf689e58e68edf783526d39a2001018b437ec4d2e7629c15620a75b5cc633a00d1402f3f2a90b89d3622cb8bb0dabbca0fd0462d08815067a2d479_1280.png',
    'https://pixabay.com/get/g67ab19fa3fc380b31ad231572f693eb6d5588ba32075e7db8c9a7cc4455cfe284894151b9ce33ff23ec5f87425fc6207d50b8b1ce92044859bcbe23bb2191303_1280.png',
    'https://pixabay.com/get/g00dc0a828f58e81b37f9a01c07d883a1e793db7eae671c368f3f929f55c3b66490ccbf05b6034ec1683383fe64e42dfdff311b0082adfe2a5e42a343d2a82d62_1280.png',
    'https://pixabay.com/get/g5378ee0dd82bcc2434d6d7331509931fd671c7b93071b5c469f1a0c1a87ca780d3474fe9471b32b17fceed2e803d3b9d3f34cb09b40732292e44f942d310f4f4_1280.jpg',
    'https://pixabay.com/get/g763cf1dc98ff285867614c3e429c1641d9e58a89e7149ccc05ad4cc4936661c59dbb898c82efaf00289e2b07ac53b0d612570fb060fd11dd52a2391b3be6adf1_1280.jpg',
    'https://pixabay.com/get/ga608ae14800f8b45e6fe940c1573a955cf6b6edd90bbc6b07fc223cf900b8bd3cf51fc3868a363fd033d6dda424c57a0777e308ba9587e0b4c0c155a69c9c8bb_1280.png',
  ];

  final List<String> _characterNames = [
    'Virtual Assistant',
    'Friendly Robot',
    'Anime Girl',
    'Cute Animal',
    'Space Girl',
    'Digital Avatar',
  ];

  final Map<int, String> _dayNames = {
    0: 'Sun',
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
  };

  @override
  void initState() {
    super.initState();
    _initializeFromAlarm();
  }

  void _initializeFromAlarm() {
    if (widget.alarm != null) {
      final alarm = widget.alarm!;
      _selectedTime = TimeOfDay.fromDateTime(alarm.time);
      _labelController.text = alarm.label;
      _repeatDays = Set.from(alarm.repeatDays);
      _selectedVirtualCharacter = alarm.virtualCharacter;
      _hasHoroscope = alarm.hasHoroscope;
      _hasMotivation = alarm.hasMotivation;
      _hasWeather = alarm.hasWeather;
      _snoozeMinutes = alarm.snoozeMinutes;
    } else {
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.alarm != null ? 'Edit Alarm' : 'New Alarm'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: Text(
              'Save',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeSelector(),
            const SizedBox(height: 24),
            _buildLabelInput(),
            const SizedBox(height: 24),
            _buildRepeatDays(),
            const SizedBox(height: 24),
            _buildVirtualCharacterSelection(),
            const SizedBox(height: 24),
            _buildWakeupOptions(),
            const SizedBox(height: 24),
            _buildSnoozeSettings(),
            const SizedBox(height: 40),
            _buildPreviewCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alarm Time',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _selectedTime.format(context),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alarm Label (Optional)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _labelController,
          decoration: InputDecoration(
            hintText: 'e.g., Morning Workout, Work Day',
            prefixIcon: Icon(
              Icons.label_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatDays() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: _dayNames.entries.map((entry) {
            final dayIndex = entry.key;
            final dayName = entry.value;
            final isSelected = _repeatDays.contains(dayIndex);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _repeatDays.remove(dayIndex);
                  } else {
                    _repeatDays.add(dayIndex);
                  }
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    dayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _repeatDays = {1, 2, 3, 4, 5}; // Weekdays
                });
              },
              child: const Text('Weekdays'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _repeatDays = {0, 6}; // Weekends
                });
              },
              child: const Text('Weekends'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _repeatDays = {0, 1, 2, 3, 4, 5, 6}; // Every day
                });
              },
              child: const Text('Daily'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVirtualCharacterSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Virtual Character',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose who will greet you when you wake up',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _virtualCharacters.length,
            itemBuilder: (context, index) {
              final character = _virtualCharacters[index];
              final isSelected = _selectedVirtualCharacter == character;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedVirtualCharacter = character;
                    });
                  },
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10)),
                            child: Image.network(
                              character,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Icon(
                                    Icons.person,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(10)),
                          ),
                          child: Text(
                            _characterNames[index],
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWakeupOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wake-up Content',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose what content to include when you wake up',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 16),
        _buildOptionCard(
          icon: Icons.lightbulb_outline,
          title: 'Motivational Messages',
          subtitle: 'Inspiring phrases to start your day',
          value: _hasMotivation,
          onChanged: (value) {
            setState(() {
              _hasMotivation = value;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.star,
          title: 'Daily Horoscope',
          subtitle: 'Personalized horoscope based on your zodiac sign',
          value: _hasHoroscope,
          onChanged: (value) {
            setState(() {
              _hasHoroscope = value;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.cloud,
          title: 'Weather Update',
          subtitle: 'Current weather information',
          value: _hasWeather,
          onChanged: (value) {
            setState(() {
              _hasWeather = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSnoozeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Snooze Duration',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [5, 10, 15, 20].map((minutes) {
            final isSelected = _snoozeMinutes == minutes;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _snoozeMinutes = minutes;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${minutes}m',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Alarm Preview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Time: ${_selectedTime.format(context)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          if (_labelController.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Label: ${_labelController.text}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Repeat: ${_getRepeatString()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Content: ${_getContentString()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }

  String _getRepeatString() {
    if (_repeatDays.isEmpty) return 'Once';
    if (_repeatDays.length == 7) return 'Daily';
    if (_repeatDays.length == 5 &&
        !_repeatDays.contains(0) &&
        !_repeatDays.contains(6)) {
      return 'Weekdays';
    }
    if (_repeatDays.length == 2 &&
        _repeatDays.contains(0) &&
        _repeatDays.contains(6)) {
      return 'Weekends';
    }
    return _repeatDays.map((day) => _dayNames[day]).join(', ');
  }

  String _getContentString() {
    final content = <String>[];
    if (_hasMotivation) content.add('Motivation');
    if (_hasHoroscope) content.add('Horoscope');
    if (_hasWeather) content.add('Weather');
    return content.isEmpty ? 'None' : content.join(', ');
  }

  void _selectTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveAlarm() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final userProfile = await StorageService.getUserProfile();
    final now = DateTime.now();
    final alarmDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final alarm = Alarms(
      id: widget.alarm?.id ?? 'alarm_${DateTime.now().millisecondsSinceEpoch}',
      time: alarmDateTime,
      label: _labelController.text.trim(),
      repeatDays: _repeatDays,
      hasHoroscope: _hasHoroscope,
      hasMotivation: _hasMotivation,
      hasWeather: _hasWeather,
      virtualCharacter: _selectedVirtualCharacter,
      snoozeMinutes: _snoozeMinutes,
    );
    await StorageService.saveAlarm(alarm);
    await AlarmService.scheduleAlarm(alarm);
    if (_hasHoroscope == true || _hasWeather == true) {
      await ContentService.getHoroscopeWeather(userProfile!);
    }
    if (mounted) {
      Navigator.of(context).pop(); // dismiss progress dialog
      Navigator.of(context).pop(); // pop screen
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }
}
