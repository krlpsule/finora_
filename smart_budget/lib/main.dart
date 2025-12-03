// lib/main.dart (Nihai Versiyon)

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Yüklü
import 'package:flutter_bloc/flutter_bloc.dart'; // Yüklü
import 'screens/main_screen.dart'; // Yüklü
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/speech_service.dart';
import 'services/ai_service.dart';
import 'features/transaction/transaction_bloc.dart';
import 'features/transaction/transaction_event.dart';

// ---------------------------------------------
// KRİTİK DÜZELTME: Servislerin doğru sırayla başlatılması
// ---------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. DOTENV YÜKLEME (AI Servisi için hayati)
  // Bu, AIService constructor'ı çağrılmadan önce anahtarı kullanılabilir yapar.
  try {
    await dotenv.load(fileName: ".env"); 
  } catch (e) {
    // Eğer .env dosyası bulunamazsa bile uygulamayı durdurmayalım
    print("Warning: Failed to load .env file: $e");
  }

  // 2. FIREBASE BAŞLATMA
  await Firebase.initializeApp();
  
  // 3. SERVİS İLK BAŞLATMALARI (Bildirimler)
  // Arkadaşınız bu kısmı tamamlayacaktır. Şimdilik sadece init çağrısı kalsın.
  await NotificationService().init(); 
  
  runApp(const FinoraApp()); // runApp çağrılırken, FinoraApp içinde Provider'lar kurulur.
}

class FinoraApp extends StatelessWidget {
  const FinoraApp({super.key}); // const constructor eklendi
  
  @override
  Widget build(BuildContext context) {
    // MultiBlocProvider, tüm servisleri ve BLoC'ları sağlar.
    return MultiBlocProvider(
      providers: [
        // BLoC'lar
        BlocProvider<TransactionBloc>(
          create: (context) =>
              TransactionBloc(FirestoreService())..add(LoadTransactions()),
        ),

        // Diğer Servisler (AIService dahil)
        // AIService çağrısı, dotenv yüklendiği için artık güvenlidir.
        Provider<AIService>(create: (_) => AIService()), 
        Provider<SpeechService>(create: (_) => SpeechService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()), // Gerekirse
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