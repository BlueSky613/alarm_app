import 'package:flutter/material.dart';
import 'package:dawn_weaver/models/user_profile.dart';
import 'package:dawn_weaver/services/storage_service.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _nameController = TextEditingController();
  ZodiacSign _selectedZodiacSign = ZodiacSign.aries;
  String _selectedLanguage = 'en';

  final Map<ZodiacSign, String> _zodiacNames = {
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

  final Map<ZodiacSign, String> _zodiacDates = {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      _buildWelcomeHeader(),
                      const SizedBox(height: 40),
                      _buildNameInput(),
                      const SizedBox(height: 32),
                      _buildLanguageSelection(),
                      const SizedBox(height: 32),
                      _buildZodiacSelection(),
                      const SizedBox(height: 40),
                      _buildFeaturesList(),
                    ],
                  ),
                ),
              ),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🌅',
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome to\nDawn Weaver',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Let\'s personalize your wake-up experience with virtual characters, daily horoscopes, and motivational messages.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What should we call you?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Enter your name or nickname',
            prefixIcon: Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your language',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildLanguageCard('en', '🇺🇸', 'English'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildLanguageCard('es', '🇪🇸', 'Español'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageCard(String code, String flag, String name) {
    final isSelected = _selectedLanguage == code;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = code;
        });
      },
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
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZodiacSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your zodiac sign',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us provide personalized horoscopes',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<ZodiacSign>(
            value: _selectedZodiacSign,
            isExpanded: true,
            underline: const SizedBox(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            items: ZodiacSign.values.map((sign) {
              final profile = UserProfile(name: '', zodiacSign: sign);
              return DropdownMenuItem<ZodiacSign>(
                value: sign,
                child: Row(
                  children: [
                    Text(
                      profile.zodiacEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _zodiacNames[sign]!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _zodiacDates[sign]!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (ZodiacSign? value) {
              if (value != null) {
                setState(() {
                  _selectedZodiacSign = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.face,
        'title': 'Virtual Characters',
        'description': 'Choose from animated characters that will greet you',
      },
      {
        'icon': Icons.star,
        'title': 'Daily Horoscope',
        'description': 'Personalized horoscope based on your zodiac sign',
      },
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Motivational Messages',
        'description': 'Inspiring phrases to start your day positively',
      },
      {
        'icon': Icons.cloud,
        'title': 'Weather Updates',
        'description': 'Current weather information for your area',
      },
      {
        'icon': Icons.music_note,
        'title': 'Custom Music',
        'description': 'Wake up to your favorite songs',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What you\'ll get:',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      feature['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildContinueButton() {
    final isValid = _nameController.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton(
        onPressed: isValid ? _saveProfile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Continue',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    final profile = UserProfile(
      name: _nameController.text.trim(),
      zodiacSign: _selectedZodiacSign,
      language: _selectedLanguage,
      firstTimeSetup: false,
    );

    await StorageService.saveUserProfile(profile);
    await StorageService.setFirstRun(false);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}