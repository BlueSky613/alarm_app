import 'package:dawn_weaver/screens/test_screen.dart';
import 'package:flutter/material.dart';
import 'package:dawn_weaver/theme.dart';
import 'package:dawn_weaver/screens/home_screen.dart';
import 'package:alarm/alarm.dart';
import 'package:dawn_weaver/screens/wakeup_screen.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Alarm.init();
  await dotenv.load(fileName: ".env");
  // final prefs = await SharedPreferences.getInstance();

  // if (prefs.getString('config') == null) {
  //   final url = Uri.parse(
  //       '${dotenv.env['base_url']}/api/v1/config'); // Replace with your URL
  //   final response = await http.get(url);
  //   if (response.statusCode == 200) {
  //     await prefs.setString('config', response.body);
  //   }
  // }

  // final alarms = await StorageService.getAlarms();

  // final int? activeAlarmId = prefs.getInt('alarmActive');
  // if (activeAlarmId != null && activeAlarmId != 0) {
  //   final alarm = alarms.firstWhere((a) => a.id.hashCode == activeAlarmId);
  //   bool result = await Alarm.isRinging(activeAlarmId);
  //   if (result) {
  //     runApp(ActiveAlarmApp(alarm: alarm, id: activeAlarmId));
  //   } else {
  //     runApp(const DawnWeaverApp());
  //   }
  // } else {
  //   runApp(const DawnWeaverApp());
  // }
  runApp(const DawnWeaverApp());
}

class DawnWeaverApp extends StatelessWidget {
  const DawnWeaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Dawn Weaver',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const TestScreen(), // Changed to use ApiTestScreen
    );
  }
}

class ActiveAlarmApp extends StatelessWidget {
  final Alarms alarm;
  final int id;

  const ActiveAlarmApp({super.key, required this.alarm, required this.id});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Dawn Weaver',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: WakeupScreen(alarm: alarm, id: id),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'dart:convert';

// // import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:http/http.dart' as http;

// String EL_API_KEY = 'sk_700b7a5b50627a7edf4739ed7bcb5fed1107bb72f64a8486';
// // String EL_API_KEY =
// //     '3c569e61d7907d633435b97c15c5c780b123e1f091551c19164f49ba19d81186';

// Future main() async {
//   // await dotenv.load(fileName: ".env");

//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'TTS Demo',
//       home: MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   TextEditingController _textFieldController = TextEditingController();
//   final player = AudioPlayer(); //audio player obj that will play audio
//   bool _isLoadingVoice = false; //for the progress indicator

//   @override
//   void dispose() {
//     _textFieldController.dispose();
//     player.dispose();
//     super.dispose();
//   }

//   //For the Text To Speech
//   Future<void> playTextToSpeech(String text) async {
//     //display the loading icon while we wait for request
//     setState(() {
//       _isLoadingVoice = true; //progress indicator turn on now
//     });

//     String voiceRachel =
//         '21m00Tcm4TlvDq8ikWAM'; //Rachel voice - change if you know another Voice ID

//     String url = 'https://api.elevenlabs.io/v1/text-to-speech/$voiceRachel';
//     final response = await http.post(
//       Uri.parse(url),
//       headers: {
//         'accept': 'audio/mpeg',
//         'xi-api-key': EL_API_KEY,
//         'Content-Type': 'application/json',
//       },
//       body: json.encode({
//         "text": text,
//         "model_id": "eleven_monolingual_v1",
//         "voice_settings": {"stability": .15, "similarity_boost": .75}
//       }),
//     );

//     setState(() {
//       _isLoadingVoice = false; //progress indicator turn off now
//     });

//     print(response.statusCode);

//     if (response.statusCode == 200) {
//       final bytes = response.bodyBytes; //get the bytes ElevenLabs sent back
//       print(bytes);
//       await player.setAudioSource(MyCustomSource(
//           bytes)); //send the bytes to be read from the JustAudio library
//       player.play(); //play the audio
//     } else {
//       // throw Exception('Failed to load audio');
//       return;
//     }
//   } //getResponse from Eleven Labs

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('EL TTS Demo'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: <Widget>[
//             TextField(
//               controller: _textFieldController,
//               decoration: const InputDecoration(
//                 labelText: 'Enter some text',
//               ),
//             ),
//             const SizedBox(height: 16.0),
//             ElevatedButton(
//               onPressed: () {
//                 playTextToSpeech(_textFieldController.text);
//               },
//               child: _isLoadingVoice
//                   ? const LinearProgressIndicator()
//                   : const Icon(Icons.volume_up),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Feed your own stream of bytes into the player
// class MyCustomSource extends StreamAudioSource {
//   final List<int> bytes;
//   MyCustomSource(this.bytes);

//   @override
//   Future<StreamAudioResponse> request([int? start, int? end]) async {
//     start ??= 0;
//     end ??= bytes.length;
//     return StreamAudioResponse(
//       sourceLength: bytes.length,
//       contentLength: end - start,
//       offset: start,
//       stream: Stream.value(bytes.sublist(start, end)),
//       contentType: 'audio/mpeg',
//     );
//   }
// }
