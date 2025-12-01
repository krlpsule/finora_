import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/speech_service.dart';
import 'services/ai_service.dart';

// TODO: Add your Firebase options or configure with google-services files.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();
  runApp(FinoraApp());
}

class FinoraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<SpeechService>(create: (_) => SpeechService()),
        Provider<AIService>(create: (_) => AIService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Finora',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.grey[50],
        ),
        home: DashboardPage(),
      ),
    );
  }
}