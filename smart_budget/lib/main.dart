import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/speech_service.dart';
import 'services/ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/transaction/transaction_bloc.dart';
import 'features/transaction/transaction_event.dart';
import 'screens/main_screen.dart';

// KRİTİK EKLENTİ: flutterfire configure ile oluşan dosya
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. DotEnv yüklemesi (AI Servisi için)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: Failed to load .env file: $e");
  }

  // 2. FIREBASE BAŞLATMA (Web/Mobil uyumlu hale getirildi)
  await Firebase.initializeApp(
    // Oluşturulan Web ayarlarını kullanır
    options: DefaultFirebaseOptions.currentPlatform, 
  );
  
  await NotificationService().init();
  runApp(const FinoraApp());
}

class FinoraApp extends StatelessWidget {
  const FinoraApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionBloc>(
          create: (context) =>
              TransactionBloc(FirestoreService())..add(LoadTransactions()),
        ),

        Provider<AIService>(create: (_) => AIService()),
        Provider<SpeechService>(create: (_) => SpeechService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Finora',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.grey[50],
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}