import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/alarm_service.dart';
import 'package:dawn_weaver/services/content_service.dart';
import 'package:dawn_weaver/widgets/wallet_alarm_gate.dart';
import 'package:dawn_weaver/screens/wakeup_screen.dart';
import 'package:dawn_weaver/utils/constants.dart';
import 'package:dawn_weaver/utils/plan_limits.dart';
import 'package:dawn_weaver/screens/premium_screen.dart';
import 'package:dawn_weaver/utils/virtual_character_video.dart';
import 'package:video_player/video_player.dart';
import 'package:dawn_weaver/l10n/app_localizations.dart';

const Color _kPrimary = Color(0xFF0EF196);
const Color _kBackgroundDark = Color(0xFF000000);

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
  bool _muteVirtualCharacterAudio = false;
  int _snoozeMinutes = 10;
  String _selectedAlarmMusic = 'default';
  bool _isPremium = false;

  static const List<Map<String, String>> _virtualCharacters = [
    {
      'name': 'Ancient_Totem',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547276/Ancient_Totem_xw5vog.mp4',
    },
    {
      'name': 'Astronaut_Bear',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547272/Astronaut_Bear_iwnjyg.mp4',
    },
    {
      'name': 'Boxy_Bot',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547305/Boxy_Bot_rtvabq.mp4',
    },
    {
      'name': 'Bubble_Robot',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547290/Bubble_Robot_ip7fbp.mp4',
    },
    {
      'name': 'Cloud_Serpent',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547270/Cloud_Serpent_ma1qkz.mp4',
    },
    {
      'name': 'Crystal_Fox',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547291/Crystal_Fox_cd5jjb.mp4',
    },
    {
      'name': 'Crystal_Turtle',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547304/Crystal_Turtle_edew3s.mp4',
    },
    {
      'name': 'Cute_Bat_Monster',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547292/Cute_Bat_Monster_tmzrvq.mp4',
    },
    {
      'name': 'Cyber_Cat',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547271/Cyber_Cat_aewvm0.mp4',
    },
    {
      'name': 'Diamond_Golem',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547312/Diamond_Golem_u5poja.mp4',
    },
    {
      'name': 'Electric_Manta',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547293/Electric_Manta_qpobl9.mp4',
    },
    {
      'name': 'Electric_Moth',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547302/Electric_Moth_e3eosg.mp4',
    },
    {
      'name': 'Fluffy_Monster',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547279/Fluffy_Monster_lwmezi.mp4',
    },
    {
      'name': 'Forest_Sprite',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547277/Forest_Sprite_gswefd.mp4',
    },
    {
      'name': 'Gemstone_Spider',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547291/Gemstone_Spider_segbzq.mp4',
    },
    {
      'name': 'Glass_Jellyfish',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547314/Glass_Jellyfish_ixbg3i.mp4',
    },
    {
      'name': 'Glitch_Pixie',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547307/Glitch_Pixie_xbdeqs.mp4',
    },
    {
      'name': 'Glow_Jellyfish',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547283/Glow-Jellyfish_ppdxpx.mp4',
    },
    {
      'name': 'Golden_Lion_Cub',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547299/Golden_Lion_Cub_wuliey.mp4',
    },
    {
      'name': 'Golden_Scarab',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547283/Golden_Scarab_vyya3n.mp4',
    },
    {
      'name': 'Happy_Fungus',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547271/Happy_Fungus_hnsyb6.mp4',
    },
    {
      'name': 'Hologram_Hamster',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547281/Hologram_Hamster_nlnhna.mp4',
    },
    {
      'name': 'Hologram_Pixie',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547298/Hologram_Pixie_v5jws2.mp4',
    },
    {
      'name': 'Jeweled_Bird',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547311/Jeweled_Bird_bjgkeq.mp4',
    },
    {
      'name': 'Lava_Slug',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547270/Lava_Slug_xvedpy.mp4',
    },
    {
      'name': 'LED_Bunny',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547287/LED_Bunny_yrbuqq.mp4',
    },
    {
      'name': 'Living_Candle',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547269/Living_Candle_onjsvz.mp4',
    },
    {
      'name': 'Luminous_Frog',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547283/Luminous_Frog_zpgkfk.mp4',
    },
    {
      'name': 'Magic_Cat',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547282/Magic_Cat_sv1rzg.mp4',
    },
    {
      'name': 'Neon_Dragon',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547290/Neon_Dragon_aiieo1.mp4',
    },
    {
      'name': 'Paper_Crane',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547272/Paper_Crane_rf5we9.mp4',
    },
    {
      'name': 'Snow_Globe_Spirit',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547301/Snow_Globe_Spirit_ngbl0q.mp4',
    },
    {
      'name': 'Star_Blob',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547308/Star_Blob_bqxkkw.mp4',
    },
    {
      'name': 'Starlight_Bunny',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547300/Starlight_Bunny_lbhsom.mp4',
    },
    {
      'name': 'Starlight_Turtle',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547280/Starlight_Turtle_helh42.mp4',
    },
    {
      'name': 'Sunfish',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547278/Sunfish_idsijx.mp4',
    },
    {
      'name': 'Sweet_Kraken',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547303/Sweet_Kraken_w9nvqp.mp4',
    },
    {
      'name': 'Vintage_Doll',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547295/Vintage_Doll_t96yzs.mp4',
    },
    {
      'name': 'Whistle_Bird',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547277/Whistle_Bird_rzn85s.mp4',
    },
    {
      'name': 'Yarn_Ball_Cat',
      'videoUrl':
          'https://res.cloudinary.com/dvxshqjev/video/upload/v1774547304/Yarn_Ball_Cat_mvfqrx.mp4',
    },
  ];

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _periodController;
  final AudioPlayer _previewPlayer = AudioPlayer();

  static const List<String> _alarmMusicLinks = [
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508426/1-morning-sun_a2ozu3.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508488/2-tropical-alarm_gs5f1p.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508429/3-bing-crosby_l1jmoy.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508436/4-kirby_iwojce.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508429/5-celestial_dge7af.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508536/6-hi-hat_uutmag.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508523/7-ebin-augustin_czieaq.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508504/8-retro_ayxekn.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508524/9-morning-piano_oganoy.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508494/10-broken_tffbyz.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508446/11-bach-air_by3fxk.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508524/12-negative-energy-and-fresh-start_dw37ci.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508523/13-this-is-our-home_iibwpv.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508455/14-lets-love-and-sway_fo9bew.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508467/15-slow-turn-in-the-lamplight_xqcbut.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508492/16-komm-lieber_c9hoc4.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508521/17-kant-feel-my-face_ghkcnj.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508497/18-gentle-acoustic-guitar_fylhyw.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508497/19-chasing-lights-feat_fkncyr.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508493/20-edge-of-infinity_fcldec.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508458/21-Hacker_Alarm_ary3q3.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508430/22-wake-up-call_hmcgqp.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508427/23-wake-up_gxw7jv.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508437/24-high-alert_amhdzo.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508476/25-railing-to-nature_cuuedw.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508540/26-der-tag_iodqkt.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508496/27-watching-the-time_grwfgh.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508435/28-alarm_idkx2b.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508498/29-czechoslovakia_evgyxg.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508432/30-early-morning_v46tcb.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508439/31-morning-mood_gdwuul.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508507/32-morning-light_nan5i9.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508448/33-morning-routine_wmzrux.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508463/34-early-morning-rise_fwbofh.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508445/35-beautiful-morning_af3sbd.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508500/36-soft-morning_aba3ls.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508533/37-morning-meditation_alk3ru.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508502/38-parrot-wake_gb47a9.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508502/39-grave-secrets_btre7q.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508529/40-haunted-assembly_pq82kv.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508535/41-peaceful-meditation_kqzaxk.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508484/42-deep-meditation_rz7opm.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508533/43-victory-song_oj4spz.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508503/44-gentle-acoustic-guitar_kt6v6j.mp3',
    'https://res.cloudinary.com/dvxshqjev/video/upload/v1774508447/45-Morning_In_the_Forest_glwsbu.mp3',
  ];

  Map<int, String> get _dayNames {
    final l10n = AppLocalizations.of(context);
    return {
      0: l10n.sun,
      1: l10n.mon,
      2: l10n.tue,
      3: l10n.wed,
      4: l10n.thu,
      5: l10n.fri,
      6: l10n.sat,
    };
  }

  @override
  void initState() {
    super.initState();
    _initializeFromAlarm();
    if (_selectedAlarmMusic == 'default') {
      _selectedAlarmMusic = AppConstants.defaultAlarmSoundUrl;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPremiumAndEnforce());
  }

  Future<void> _loadPremiumAndEnforce() async {
    final p = await StorageService.getUserProfile();
    if (!mounted) return;
    setState(() {
      _isPremium = p?.isPremium ?? false;
      if (!_isPremium) _clampSelectionsToFreePlan();
    });
  }

  void _clampSelectionsToFreePlan() {
    _selectedVirtualCharacter = PlanLimits.clampVirtualCharacter(
      _selectedVirtualCharacter,
      _virtualCharacters,
    );
    _selectedAlarmMusic = PlanLimits.clampBundledMusic(
      _selectedAlarmMusic,
      _alarmMusicLinks,
    );
  }

  /// Free plan: unlocked characters first (same relative order), then locked.
  List<int> _virtualCharacterDisplayIndices() {
    if (_isPremium) {
      return List<int>.generate(_virtualCharacters.length, (i) => i);
    }
    final free = PlanLimits.freeVirtualCharacterIndices.toList()..sort();
    final locked = <int>[];
    for (var i = 0; i < _virtualCharacters.length; i++) {
      if (!PlanLimits.isVirtualCharacterIndexFree(i)) locked.add(i);
    }
    return [...free, ...locked];
  }

  /// Free plan: unlocked bundled tracks first (list order), then locked.
  List<int> _bundledMusicDisplayIndices() {
    if (_isPremium) {
      return List<int>.generate(_alarmMusicLinks.length, (i) => i);
    }
    final free = <int>[];
    final locked = <int>[];
    for (var i = 0; i < _alarmMusicLinks.length; i++) {
      if (PlanLimits.isBundledMusicIndexFree(i)) {
        free.add(i);
      } else {
        locked.add(i);
      }
    }
    return [...free, ...locked];
  }

  Future<void> _openPremiumUpgrade() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => const PremiumScreen()),
    );
    await _loadPremiumAndEnforce();
  }

  void _showPremiumRequiredForFeature() {
    final es = AppLocalizations.of(context).isSpanish;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          es ? 'Premium requerido' : 'Premium required',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          es
              ? 'Desbloquea todos los personajes y pistas con Premium. Pago requerido.'
              : 'Unlock every character and alarm track with Premium. Payment required.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(es ? 'Ahora no' : 'Not now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openPremiumUpgrade();
            },
            child: Text(
              es ? 'Ver Premium' : 'View Premium',
              style: const TextStyle(color: _kPrimary),
            ),
          ),
        ],
      ),
    );
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
      _muteVirtualCharacterAudio = alarm.muteVirtualCharacterAudio;
      _snoozeMinutes = alarm.snoozeMinutes;
      _selectedAlarmMusic = alarm.soundPath;
    } else {
      _selectedTime = TimeOfDay.now();
    }

    final hourOfPeriod = _selectedTime.hourOfPeriod;
    _hourController = FixedExtentScrollController(
      initialItem: hourOfPeriod == 0 ? 11 : hourOfPeriod - 1,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedTime.minute,
    );
    _periodController = FixedExtentScrollController(
      initialItem: _selectedTime.period == DayPeriod.am ? 0 : 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundDark,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeSelector(),
                  const SizedBox(height: 16),
                  _buildVirtualCharacterSelection(),
                  const SizedBox(height: 16),
                  _buildAlarmMusicSelection(),
                  const SizedBox(height: 16),
                  _buildLabelInput(),
                  const SizedBox(height: 16),
                  _buildRepeatDays(),
                  const SizedBox(height: 16),
                  _buildWakeupOptions(),
                  const SizedBox(height: 16),
                  _buildSnoozeSettings(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white.withValues(alpha: 0.6),
              size: 28,
            ),
          ),
          Text(
            (widget.alarm != null ? l10n.editAlarm : l10n.addAlarm)
                .toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    const double itemExtent = 64;
    const double wheelHeight = 200.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWheelColumn(
            controller: _hourController,
            itemCount: 12,
            width: 88,
            height: wheelHeight,
            itemExtent: itemExtent,
            labelBuilder: (index) => (index + 1).toString().padLeft(2, '0'),
            fontSize: 44,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: _kPrimary,
              ),
            ),
          ),
          _buildWheelColumn(
            controller: _minuteController,
            itemCount: 60,
            width: 88,
            height: wheelHeight,
            itemExtent: itemExtent,
            labelBuilder: (index) => index.toString().padLeft(2, '0'),
            fontSize: 44,
          ),
          const SizedBox(width: 12),
          _buildWheelColumn(
            controller: _periodController,
            itemCount: 2,
            width: 64,
            height: wheelHeight,
            itemExtent: itemExtent,
            labelBuilder: (index) => index == 0 ? 'AM' : 'PM',
            fontSize: 20,
            isPeriod: true,
          ),
        ],
      ),
    );
  }

  Widget _buildWheelColumn({
    required FixedExtentScrollController controller,
    required int itemCount,
    required double width,
    required double height,
    required double itemExtent,
    required String Function(int index) labelBuilder,
    required double fontSize,
    bool isPeriod = false,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Center(
            child: Container(
              height: itemExtent,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
              ),
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, 0.35, 0.65, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: itemExtent,
              diameterRatio: 1.2,
              perspective: 0.003,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (_) => _onTimeChanged(),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: itemCount,
                builder: (context, index) {
                  return Center(
                    child: Text(
                      labelBuilder(index),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: isPeriod ? _kPrimary : Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTimeChanged() {
    final hour12 = _hourController.selectedItem + 1;
    final minute = _minuteController.selectedItem;
    final isAm = _periodController.selectedItem == 0;

    int hour24;
    if (isAm) {
      hour24 = hour12 == 12 ? 0 : hour12;
    } else {
      hour24 = hour12 == 12 ? 12 : hour12 + 12;
    }

    setState(() {
      _selectedTime = TimeOfDay(hour: hour24, minute: minute);
    });
  }

  Widget _buildVirtualCharacterSelection() {
    final l10n = AppLocalizations.of(context);
    final charOrder = _virtualCharacterDisplayIndices();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.virtualCharacter.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: _kPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 224,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: charOrder.length,
            itemBuilder: (context, displayPos) {
              final index = charOrder[displayPos];
              final characterData = _virtualCharacters[index];
              final rawTitle = (characterData['name'] ?? '').toString();
              final characterName = _formatCharacterTitle(rawTitle);
              final videoUrl = (characterData['videoUrl'] ?? 'default');
              final thumbnailAssetPath = _thumbnailAssetPath(rawTitle);
              bool isSelected = _selectedVirtualCharacter == videoUrl;
              final unlocked =
                  _isPremium || PlanLimits.isVirtualCharacterIndexFree(index);

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    if (!unlocked) {
                      _showPremiumRequiredForFeature();
                      return;
                    }
                    setState(() {
                      if (isSelected) {
                        _selectedVirtualCharacter = 'default';
                      } else {
                        _selectedVirtualCharacter = videoUrl;
                      }
                      isSelected = !isSelected;
                    });
                  },
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withValues(alpha: 0.03),
                      border: Border.all(
                        color: isSelected
                            ? _kPrimary
                            : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 0.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColorFiltered(
                            colorFilter: isSelected && unlocked
                                ? const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.dst,
                                  )
                                : const ColorFilter.matrix(<double>[
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    1,
                                    0,
                                  ]),
                            child: Opacity(
                              opacity: (isSelected && unlocked) ? 0.8 : 0.5,
                              child: Image.asset(
                                thumbnailAssetPath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                      size: 28,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black, Colors.transparent],
                                ),
                              ),
                              child: Text(
                                characterName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected && unlocked
                                      ? _kPrimary
                                      : Colors.white.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (!unlocked)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: _kPrimary.withValues(alpha: 0.95),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _kPrimary.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _muteVirtualCharacterAudio
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: _kPrimary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.isSpanish
                            ? 'Silenciar audio del personaje virtual'
                            : 'Mute virtual character audio',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Switch(
                      value: _muteVirtualCharacterAudio,
                      onChanged: (value) {
                        setState(() {
                          _muteVirtualCharacterAudio = value;
                        });
                      },
                      activeThumbColor: _kPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCharacterTitle(String rawTitle) {
    var title = rawTitle.split('/').last;
    title = title.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    title = title.replaceAll('_', ' ').trim();
    return title;
  }

  String _thumbnailAssetPath(String rawTitle) {
    final fileName = rawTitle.split('/').last;
    final hasExtension = fileName.contains('.');
    final normalized = hasExtension ? fileName : '$fileName.png';
    return 'assets/thumbnail/$normalized';
  }

  Widget _buildLabelInput() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _kPrimary.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.label_outline, color: _kPrimary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.alarmLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _labelController,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.enterLabel,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmMusicSelection() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _kPrimary.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.music_note, color: _kPrimary, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      l10n.isSpanish ? 'Música de alarma' : 'Alarm Music',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _openMusicPickerModal,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _kPrimary.withValues(alpha: 0.2),
                      ),
                      color: Colors.white.withValues(alpha: 0.02),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _alarmMusicDisplayName(_selectedAlarmMusic),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.library_music_outlined,
                          color: _kPrimary.withValues(alpha: 0.9),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _alarmMusicDisplayName(String link) {
    if (link == 'default' || link.isEmpty) {
      return 'Alarm Tone 1';
    }

    if (_isDeviceMusicPath(link)) {
      return _displayNameFromPath(link);
    }

    final fileName = link.split('/').last.replaceAll('.mp3', '');
    final withoutPrefix = fileName.replaceAll(RegExp(r'^[0-9]+-?'), '');
    final parts = withoutPrefix.split('_');
    final core = parts.length > 1 ? parts.sublist(0, parts.length - 1) : parts;
    final words = core.where((w) => w.trim().isNotEmpty).map((w) {
      final lower = w.toLowerCase();
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).toList();
    return words.join(' ');
  }

  bool _isDeviceMusicPath(String path) {
    final lower = path.toLowerCase();
    return lower.startsWith('/') ||
        lower.startsWith('file://') ||
        lower.contains(':\\');
  }

  String _displayNameFromPath(String path) {
    var raw = path.replaceAll('\\', '/');
    if (raw.startsWith('file://')) {
      raw = raw.substring('file://'.length);
    }
    final last = raw.split('/').last;
    return last.isEmpty ? 'Custom Music' : last;
  }

  Future<void> _pickMusicFromDevice({
    required void Function(void Function()) setModalState,
    required void Function(String) onSelected,
    required void Function(String?) onPlayingChanged,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
    );
    if (result == null || result.files.isEmpty) return;

    final pickedPath = result.files.single.path;
    if (pickedPath == null || pickedPath.isEmpty) return;

    onSelected(pickedPath);
    setModalState(() => onPlayingChanged(pickedPath));
    await _previewPlayer.stop();
    await _previewPlayer.play(DeviceFileSource(pickedPath));
  }

  Future<void> _openMusicPickerModal() async {
    if (_alarmMusicLinks.isEmpty) return;

    var tempSelected = _selectedAlarmMusic;
    if (tempSelected == 'default' || tempSelected.isEmpty) {
      tempSelected = _alarmMusicLinks.first;
    }
    String? playingLink;
    final musicOrder = _bundledMusicDisplayIndices();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101010),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context).isSpanish
                            ? 'Seleccionar música'
                            : 'Select Alarm Music',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: musicOrder.length + 1,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final isSelected = _isDeviceMusicPath(
                                tempSelected,
                              );
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                title: Text(
                                  AppLocalizations.of(context).isSpanish
                                      ? 'Elegir desde el teléfono'
                                      : 'Choose from phone',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: isSelected
                                    ? Text(
                                        _displayNameFromPath(tempSelected),
                                        style: TextStyle(
                                          color: _kPrimary.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                trailing: Icon(
                                  Icons.folder_open,
                                  color: _kPrimary,
                                ),
                                onTap: () async {
                                  await _pickMusicFromDevice(
                                    setModalState: setModalState,
                                    onSelected: (value) => tempSelected = value,
                                    onPlayingChanged: (value) =>
                                        playingLink = value,
                                  );
                                },
                              );
                            }

                            final bundleIdx = musicOrder[index - 1];
                            final link = _alarmMusicLinks[bundleIdx];
                            final musicUnlocked = _isPremium ||
                                PlanLimits.isBundledMusicIndexFree(bundleIdx);
                            final isPlaying = playingLink == link;
                            final isSelected = tempSelected == link;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              title: Text(
                                _alarmMusicDisplayName(link),
                                style: TextStyle(
                                  color: Colors.white.withValues(
                                    alpha: musicUnlocked
                                        ? (isSelected ? 1 : 0.85)
                                        : 0.45,
                                  ),
                                  fontWeight: isSelected && musicUnlocked
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: isPlaying && musicUnlocked
                                  ? Text(
                                      AppLocalizations.of(context).isSpanish
                                          ? 'Reproduciendo...'
                                          : 'Playing...',
                                      style: TextStyle(
                                        color: _kPrimary.withValues(alpha: 0.9),
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                              trailing: Icon(
                                musicUnlocked
                                    ? (isPlaying
                                        ? Icons.pause_circle
                                        : Icons.play_circle)
                                    : Icons.lock_outline,
                                color: musicUnlocked
                                    ? _kPrimary
                                    : Colors.white.withValues(alpha: 0.35),
                              ),
                              onTap: () async {
                                if (!musicUnlocked) {
                                  _showPremiumRequiredForFeature();
                                  return;
                                }
                                tempSelected = link;
                                setModalState(() {
                                  playingLink = link;
                                });
                                await _previewPlayer.stop();
                                await _previewPlayer.play(UrlSource(link));
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await _previewPlayer.stop();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context).isSpanish
                                    ? 'Cancelar'
                                    : 'Cancel',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _previewPlayer.stop();
                                if (!mounted) return;
                                setState(() {
                                  _selectedAlarmMusic = tempSelected;
                                });
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                foregroundColor: _kBackgroundDark,
                              ),
                              child: Text(
                                AppLocalizations.of(context).isSpanish
                                    ? 'Confirmar'
                                    : 'Confirm',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRepeatDays() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _kPrimary.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month, color: _kPrimary, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      l10n.repeat,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: _dayNames.entries.map((entry) {
                    final dayIndex = entry.key;
                    final dayName = entry.value;
                    final isSelected = _repeatDays.contains(dayIndex);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: GestureDetector(
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
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _kPrimary
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                dayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? _kBackgroundDark
                                      : Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWakeupOptions() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              // Expanded(
              //   child: _buildCompactToggle(
              //     icon: Icons.lightbulb_outline,
              //     label: l10n.motivationalMessage,
              //     value: _hasMotivation,
              //     onChanged: (v) => setState(() => _hasMotivation = v),
              //   ),
              // ),
              // const SizedBox(width: 16),
              Expanded(
                child: _buildCompactToggle(
                  icon: Icons.auto_awesome,
                  label: l10n.horoscope,
                  value: _hasHoroscope,
                  onChanged: (v) => setState(() => _hasHoroscope = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCompactToggle(
                  icon: Icons.cloud_outlined,
                  label: l10n.weatherInfo,
                  value: _hasWeather,
                  onChanged: (v) => setState(() => _hasWeather = v),
                ),
              ),
            ],
          ),
          // const SizedBox(height: 16),
          // Row(
          //   children: [
          //     Expanded(
          //       child: _buildCompactToggle(
          //         icon: Icons.cloud_outlined,
          //         label: l10n.weatherInfo,
          //         value: _hasWeather,
          //         onChanged: (v) => setState(() => _hasWeather = v),
          //       ),
          //     ),
          //     const SizedBox(width: 16),
          //     const Expanded(child: SizedBox()),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildCompactToggle({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value
                    ? _kPrimary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      icon,
                      color: value
                          ? _kPrimary
                          : Colors.white.withValues(alpha: 0.4),
                      size: 22,
                    ),
                    _buildMiniToggle(value),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: value
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniToggle(bool value) {
    return Container(
      width: 32,
      height: 16,
      decoration: BoxDecoration(
        color: value ? _kPrimary : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: value
                ? _kBackgroundDark
                : Colors.white.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildSnoozeSettings() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _kPrimary.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.snooze, color: _kPrimary, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      l10n.isSpanish ? 'Posponer' : 'Snooze',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [5, 10, 15, 20].map((minutes) {
                    final isSelected = _snoozeMinutes == minutes;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _snoozeMinutes = minutes),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _kPrimary
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${minutes}m',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? _kBackgroundDark
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            l10n.isSpanish ? 'CANCELAR' : 'CANCEL',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _saveAlarm,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        l10n.isSpanish ? 'GUARDAR' : 'SAVE ALARM',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: _kBackgroundDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _previewWakeup,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: BorderSide(color: _kPrimary.withValues(alpha: 0.65)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.previewWakeup.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _previewWakeup() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final profile = await StorageService.getUserProfile();
    final premium = profile?.isPremium ?? false;
    final vc = premium
        ? _selectedVirtualCharacter
        : PlanLimits.clampVirtualCharacter(
            _selectedVirtualCharacter,
            _virtualCharacters,
          );
    final sp = premium
        ? _selectedAlarmMusic
        : PlanLimits.clampBundledMusic(_selectedAlarmMusic, _alarmMusicLinks);

    VideoPlayerController? preloaded;
    if (vc != 'default') {
      preloaded = await preloadVirtualCharacterVideo(
        vc,
        mute: _muteVirtualCharacterAudio,
      );
    }

    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;

    final now = DateTime.now();
    final alarmDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final preview = Alarms(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
      time: alarmDateTime,
      label: _labelController.text.trim(),
      repeatDays: _repeatDays,
      hasHoroscope: _hasHoroscope,
      hasMotivation: _hasMotivation,
      hasWeather: _hasWeather,
      virtualCharacter: vc,
      muteVirtualCharacterAudio: _muteVirtualCharacterAudio,
      soundPath: sp,
      snoozeMinutes: _snoozeMinutes,
      motivationMessage: 'You can do it!',
    );
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => WakeupScreen(
          alarm: preview,
          id: 2147483646,
          isPreview: true,
          preloadedVideoController: preloaded,
        ),
      ),
    );
  }

  void _saveAlarm() async {
    final proceed = await ensureWalletAllowsAlarmSave(context);
    if (!proceed || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final userProfile = await StorageService.getUserProfile();
    final premium = userProfile?.isPremium ?? false;
    final vc = premium
        ? _selectedVirtualCharacter
        : PlanLimits.clampVirtualCharacter(
            _selectedVirtualCharacter,
            _virtualCharacters,
          );
    final sp = premium
        ? _selectedAlarmMusic
        : PlanLimits.clampBundledMusic(_selectedAlarmMusic, _alarmMusicLinks);

    if (!premium && mounted) {
      setState(() {
        _selectedVirtualCharacter = vc;
        _selectedAlarmMusic = sp;
      });
    }

    final now = DateTime.now();
    final alarmDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final existing = widget.alarm;
    final alarm = Alarms(
      id: existing?.id ?? 'alarm_${DateTime.now().millisecondsSinceEpoch}',
      time: alarmDateTime,
      // Saving from add/edit always turns the alarm on (including after editing an inactive one).
      isActive: true,
      label: _labelController.text.trim(),
      repeatDays: _repeatDays,
      hasHoroscope: _hasHoroscope,
      hasMotivation: _hasMotivation,
      hasWeather: _hasWeather,
      virtualCharacter: vc,
      muteVirtualCharacterAudio: _muteVirtualCharacterAudio,
      soundPath: sp,
      snoozeMinutes: _snoozeMinutes,
      motivationMessage: existing?.motivationMessage ?? 'You can do it!',
    );

    try {
      await StorageService.saveAlarm(alarm);
      await AlarmService.scheduleAlarm(alarm);
      if ((_hasHoroscope == true || _hasWeather == true) &&
          userProfile != null) {
        await ContentService.getHoroscopeWeather(userProfile);
      }
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if ((_hasHoroscope == true || _hasWeather == true) &&
          userProfile != null) {
        await ContentService.getHoroscopeWeather(userProfile);
      }
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    _labelController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }
}
