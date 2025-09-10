import 'package:flutter/material.dart';
import 'package:dawn_weaver/models/user_profile.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/alarm_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _userProfile;
  final _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await StorageService.getUserProfile();
    if (profile != null) {
      setState(() {
        _userProfile = profile;
        _nameController.text = profile.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (_userProfile != null)
            TextButton(
              onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
              child: Text(
                _isEditing ? 'Save' : 'Edit',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(),
                  const SizedBox(height: 32),
                  _buildLanguageSection(),
                  const SizedBox(height: 32),
                  _buildZodiacSection(),
                  const SizedBox(height: 32),
                  _buildPreferencesSection(),
                  const SizedBox(height: 32),
                  _buildAboutSection(),
                  const SizedBox(height: 32),
                  _buildDangerZone(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              _userProfile!.name.isNotEmpty ? _userProfile!.name[0].toUpperCase() : '?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isEditing)
            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              _userProfile!.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _userProfile!.zodiacEmoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                _getZodiacName(_userProfile!.zodiacSign),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection() {
    return _buildSection(
      title: 'Language',
      icon: Icons.language,
      children: [
        _buildLanguageOption('en', '🇺🇸', 'English'),
        const SizedBox(height: 8),
        _buildLanguageOption('es', '🇪🇸', 'Español'),
      ],
    );
  }

  Widget _buildLanguageOption(String code, String flag, String name) {
    final isSelected = _userProfile!.language == code;
    
    return GestureDetector(
      onTap: _isEditing ? () => _updateLanguage(code) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildZodiacSection() {
    return _buildSection(
      title: 'Zodiac Sign',
      icon: Icons.star,
      children: [
        if (_isEditing)
          DropdownButtonFormField<ZodiacSign>(
            value: _userProfile!.zodiacSign,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: ZodiacSign.values.map((sign) {
              final profile = UserProfile(name: '', zodiacSign: sign);
              return DropdownMenuItem<ZodiacSign>(
                value: sign,
                child: Row(
                  children: [
                    Text(profile.zodiacEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(_getZodiacName(sign)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (ZodiacSign? value) {
              if (value != null) {
                _updateZodiacSign(value);
              }
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  _userProfile!.zodiacEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getZodiacName(_userProfile!.zodiacSign),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getZodiacDates(_userProfile!.zodiacSign),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSection(
      title: 'Preferences',
      icon: Icons.settings,
      children: [
        _buildPreferenceItem(
          icon: Icons.notifications,
          title: 'Notification Permission',
          subtitle: 'Allow notifications for alarms',
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          onTap: _openNotificationSettings,
        ),
        const SizedBox(height: 12),
        _buildPreferenceItem(
          icon: Icons.volume_up,
          title: 'Audio Settings',
          subtitle: 'Manage text-to-speech and sound',
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          onTap: _openAudioSettings,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About',
      icon: Icons.info_outline,
      children: [
        _buildPreferenceItem(
          icon: Icons.apps,
          title: 'Dawn Weaver',
          subtitle: 'Version 1.0.0',
        ),
        const SizedBox(height: 12),
        _buildPreferenceItem(
          icon: Icons.star,
          title: 'Rate App',
          subtitle: 'Help us improve Dawn Weaver',
          onTap: () {
            // Rate app functionality
          },
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return _buildSection(
      title: 'Danger Zone',
      icon: Icons.warning,
      children: [
        _buildPreferenceItem(
          icon: Icons.delete_forever,
          title: 'Clear All Data',
          subtitle: 'Delete all alarms and reset profile',
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.error,
          ),
          titleColor: Theme.of(context).colorScheme.error,
          onTap: _showClearDataDialog,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (titleColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: titleColor ?? Theme.of(context).colorScheme.primary,
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
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  String _getZodiacName(ZodiacSign sign) {
    const names = {
      ZodiacSign.aries: 'Aries',
      ZodiacSign.taurus: 'Taurus',
      ZodiacSign.gemini: 'Gemini',
      ZodiacSign.cancer: 'Cancer',
      ZodiacSign.leo: 'Leo',
      ZodiacSign.virgo: 'Virgo',
      ZodiacSign.libra: 'Libra',
      ZodiacSign.scorpio: 'Scorpio',
      ZodiacSign.sagittarius: 'Sagittarius',
      ZodiacSign.capricorn: 'Capricorn',
      ZodiacSign.aquarius: 'Aquarius',
      ZodiacSign.pisces: 'Pisces',
    };
    return names[sign] ?? '';
  }

  String _getZodiacDates(ZodiacSign sign) {
    const dates = {
      ZodiacSign.aries: 'Mar 21 - Apr 19',
      ZodiacSign.taurus: 'Apr 20 - May 20',
      ZodiacSign.gemini: 'May 21 - Jun 20',
      ZodiacSign.cancer: 'Jun 21 - Jul 22',
      ZodiacSign.leo: 'Jul 23 - Aug 22',
      ZodiacSign.virgo: 'Aug 23 - Sep 22',
      ZodiacSign.libra: 'Sep 23 - Oct 22',
      ZodiacSign.scorpio: 'Oct 23 - Nov 21',
      ZodiacSign.sagittarius: 'Nov 22 - Dec 21',
      ZodiacSign.capricorn: 'Dec 22 - Jan 19',
      ZodiacSign.aquarius: 'Jan 20 - Feb 18',
      ZodiacSign.pisces: 'Feb 19 - Mar 20',
    };
    return dates[sign] ?? '';
  }

  void _updateLanguage(String language) {
    if (_userProfile != null) {
      setState(() {
        _userProfile = _userProfile!.copyWith(language: language);
      });
    }
  }

  void _updateZodiacSign(ZodiacSign zodiacSign) {
    if (_userProfile != null) {
      setState(() {
        _userProfile = _userProfile!.copyWith(zodiacSign: zodiacSign);
      });
    }
  }

  void _saveProfile() async {
    if (_userProfile != null && _nameController.text.trim().isNotEmpty) {
      final updatedProfile = _userProfile!.copyWith(
        name: _nameController.text.trim(),
      );
      
      await StorageService.saveUserProfile(updatedProfile);
      setState(() {
        _userProfile = updatedProfile;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  void _openNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Text(
          'Please go to your device settings to manage notification permissions for Dawn Weaver.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openAudioSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audio Settings'),
        content: const Text(
          'Text-to-speech and audio settings can be adjusted in your device\'s accessibility settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Data?',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        content: const Text(
          'This will permanently delete all your alarms, settings, and profile data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData();
            },
            child: Text(
              'Delete Everything',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllData() async {
    // Cancel all scheduled alarms first
    await AlarmService.rescheduleAllAlarms();
    
    // Clear all stored data
    await StorageService.clearAll();
    
    if (mounted) {
      // Navigate back and show confirmation
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All data cleared successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}