import 'package:flutter/material.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/alarm_service.dart';
import 'package:dawn_weaver/services/content_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


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

  List<dynamic> _virtualCharacters = [];

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

  List<String> _motivationalMessages = [
    // 'You can do it!',
    // 'Rise and shine!',
    // 'Make today amazing!',
    // 'Every day is a new beginning.',
    // 'Stay positive and strong!',
    // 'Success starts with you!',
  ];
  String? _selectedMotivationalMessage;

  @override
  void initState() {
    super.initState();
    _initializeFromAlarm();
    _loadMotivationalMessages();
  }

  Future<void> _loadMotivationalMessages() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('config');
    if (jsonString != null) {
      Map<String, dynamic> data = jsonDecode(jsonString);
      _motivationalMessages = List<String>.from(data['motivationMessage']);
      _virtualCharacters = data['videoPaths'];
      setState(() {});
    }
    _selectedMotivationalMessage = _motivationalMessages.first;
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
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _virtualCharacters.length,
            itemBuilder: (context, index) {
              final character = _virtualCharacters[index]['thumbnail'];
              final imageUrl = _virtualCharacters[index]['image_path'];
              final characterName = _virtualCharacters[index]['name'];
              bool isSelected = _selectedVirtualCharacter == imageUrl;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedVirtualCharacter = 'default';
                      } else {
                        _selectedVirtualCharacter = imageUrl;
                      }
                      isSelected = !isSelected;
                    });
                  },
                  child: Container(
                    width: 120,
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
                              "${dotenv.env['base_url']}/storage/$character",
                              width: 120,
                              fit: BoxFit.cover,
                              // errorBuilder: (context, error, stackTrace) {
                              //   return Container(
                              //     color: Theme.of(context)
                              //         .colorScheme
                              //         .primaryContainer,
                              //     child: Icon(
                              //       Icons.person,
                              //       color: Theme.of(context)
                              //           .colorScheme
                              //           .onPrimaryContainer,
                              //     ),
                              //   );
                              // },
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
                            characterName,
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
        if (_hasMotivation)
          Padding(
            padding: const EdgeInsets.only(
                left: 8.0, top: 8.0, right: 8.0, bottom: 8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedMotivationalMessage,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Choose your motivational message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: List.generate(_motivationalMessages.length, (index) {
                final msg = _motivationalMessages[index];
                // Alternate colors, you can customize these
                final bgColor = index.isEven
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.primary.withOpacity(0.08);
                return DropdownMenuItem(
                  value: msg,
                  child: Container(
                    color: bgColor,
                    width: double.infinity,
                    child: Text(
                      msg,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }),
              onChanged: (value) {
                setState(() {
                  _selectedMotivationalMessage = value;
                });
              },
              dropdownColor: Theme.of(context).colorScheme.surface,
              menuMaxHeight: 5 * 48.0,
            ),
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
      motivationMessage: _selectedMotivationalMessage ?? 'You can do it!',
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
