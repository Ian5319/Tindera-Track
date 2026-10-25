import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    runApp(const _FirebaseConfigurationErrorApp());
    return;
  }
  runApp(buildAppProviders(const TinderaTrackApp()));
}

class _FirebaseConfigurationErrorApp extends StatelessWidget {
  const _FirebaseConfigurationErrorApp();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Firebase is not configured for this platform. '
            'Please add the platform configuration before running TinderaTrack.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
