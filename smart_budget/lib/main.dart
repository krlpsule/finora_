import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/ai_chat_provider.dart'; 


import 'screens/dashboard.dart';
import 'screens/main_screen.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/speech_service.dart';
import 'services/ai_service.dart';


import 'features/transaction/transaction_bloc.dart';
import 'features/transaction/transaction_event.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. DotEnv Yüklemesi (AI Servisi için - PRD Madde 5.1)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Failed to load .env file: $e");
  }

  // 2. Firebase Başlatma (PRD Madde 6 - Teknik Gereksinimler)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Bildirim Servisi Başlatma ve Planlama (PRD Madde 5.6)
  final notificationService = NotificationService();
 // await notificationService.init();
  
  // Uygulama her açıldığında günlük motivasyon sözü bildirimini planlar.
  // Bu, PRD'deki "Daily motivational financial quote"  gereksinimi içindir.
  //await notificationService.scheduleDailyQuote();

  runApp(const FinoraApp());
}

class FinoraApp extends StatelessWidget {
  const FinoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AIChatProvider()),
        // TransactionBloc: İşlem yönetimi için (PRD Madde 5.4)
        BlocProvider<TransactionBloc>(
          create: (context) =>
              TransactionBloc(FirestoreService())..add(LoadTransactions()),
        ),
        
        // Dependency Injection ile Servislerin Dağıtımı
        Provider<AIService>(create: (_) => AIService()),
        Provider<SpeechService>(create: (_) => SpeechService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Finora',
        
        // PRD Madde 7 - UX/UI Requirements 
        // "Soft gradients (blue-purple-green)" ve "Youth-friendly" arayüz
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF), // Genç/Modern Mor-Mavi tonu
            brightness: Brightness.light,
            secondary: Colors.teal, // Yeşil tonları için ikincil renk
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Yumuşak gri/beyaz
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent, // Modern görünüm
            titleTextStyle: TextStyle(
              color: Colors.black87, 
              fontSize: 20, 
              fontWeight: FontWeight.bold
            ),
          ),
        ),
        
        // Başlangıç Ekranı
        home: const MainScreen(),
      ),
    );
  }
}
