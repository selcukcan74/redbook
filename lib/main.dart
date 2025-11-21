import 'package:flutter/material.dart';
//import 'package:redbook/pages/auth/login_page.dart';
import 'package:redbook/pages/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/verify_quote_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        //'/': (context) => const LoginPage(),
        //'/home': (context) => const HomePage(),
        '/': (context) => const HomePage(),
        '/verify': (context) => const VerifyQuotePage(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF), // Modern Mor – Premium
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
    );
  }
}
