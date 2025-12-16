import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/ai_chat_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/auth_bloc.dart';
import 'features/auth/auth_event.dart';
import 'features/auth/auth_state.dart';
import 'screens/login_screen.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Failed to load .env file: $e");
  }

  // Setup Firebase (PRD Madde 5.1)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.init();

  await notificationService.scheduleDailyQuote();

  runApp(const FinoraApp());
}

class FinoraApp extends StatelessWidget {
  const FinoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // CHANGE: Use MultiProvider instead of MultiBlocProvider
    return MultiProvider( 
      providers: [
        ChangeNotifierProvider(create: (_) => AIChatProvider()),

        // Blocs
        BlocProvider<TransactionBloc>(
          create: (context) =>
              TransactionBloc(FirestoreService())..add(LoadTransactions()),
        ),
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(FirebaseAuth.instance)..add(AppStarted()),
        ),

        // Services
        Provider<AIService>(create: (_) => AIService()),
        Provider<SpeechService>(create: (_) => SpeechService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Finora',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.light,
            secondary: Colors.teal,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              // If logged in, redirect to the main screen (MainScreen containing Dashboard)
              return const MainScreen();
            } else if (state is Unauthenticated) {
              // If no login has been made, redirect to the Login page
              return const LoginScreen();
            }
            // Show the loading screen at startup or during loading
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          },
        ),
      ),
    );
  }
}
