import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

const String _baseUrl = "https://flicksize.com/krishi_plus/";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TestApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16A34A),
          brightness: Brightness.light,
        ),
      ),
      home: const _AuthGate(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _loading = true;
  bool _goHome = false;

  @override
  void initState() {
    super.initState();
    _resolveStartPage();
  }

  Future<bool> _checkAlreadySubscribed(String phone) async {
    try {
      final response = await http
          .post(
            Uri.parse('${_baseUrl}check_subscription.php'),
            body: {'user_mobile': phone},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return false;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      final status =
          decoded['subscriptionStatus']?.toString().trim().toUpperCase() ?? '';
      final isSubscribed = status == 'REGISTERED';

      return isSubscribed;
    } catch (e) {
      return false;
    }
  }

  Future<void> _resolveStartPage() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final phone = prefs.getString('userPhone') ?? '';

    var shouldGoHome = false;
    if (isLoggedIn && phone.isNotEmpty) {
      try {
        shouldGoHome = await _checkAlreadySubscribed(phone);

        if (!shouldGoHome) {
          // User lost subscription - clear credentials
          await prefs.remove('isLoggedIn');
          await prefs.remove('userPhone');
        }
      } catch (e) {
        shouldGoHome = false;
      }
    }

    if (!mounted) return;
    setState(() {
      _goHome = shouldGoHome;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _goHome ? const HomePage() : const LoginPage();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Hello Developers')));
  }
}
