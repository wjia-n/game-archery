import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/range_art.dart';
import 'theme/range_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = RangeSettings();
  await settings.load();
  final audio = RangeAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(ArcheryApp(settings: settings, audio: audio));
}

class ArcheryApp extends StatefulWidget {
  final RangeSettings settings;
  final RangeAudio audio;
  const ArcheryApp({super.key, required this.settings, required this.audio});

  @override
  State<ArcheryApp> createState() => _ArcheryAppState();
}

class _ArcheryAppState extends State<ArcheryApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Archery',
        debugShowCheckedModeBanner: false,
        theme: Range.theme(RangeThemes.byId(widget.settings.themeId,
            custom: widget.settings.customTheme)),
        home: SplashScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
  }
}
