import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'forecast_page.dart';
import 'krishok_page.dart';
import 'live_services_page.dart';
import 'login.dart';
import 'providers/admin_notification_provider.dart';
import 'providers/app_provider.dart';
import 'providers/forecast_provider.dart';
import 'providers/weather_provider.dart';
import 'services/notification_service.dart';
import 'widgets/app_drawer.dart';
import 'widgets/signal_aura.dart';

const String _baseUrl = "https://flicksize.com/krishi_plus/";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(
          create: (_) => AdminNotificationProvider()..load(),
        ),
        ChangeNotifierProxyProvider<AppProvider, ForecastProvider>(
          create: (_) => ForecastProvider(),
          update: (_, app, forecast) {
            final fp = forecast ?? ForecastProvider();
            fp.fetchForLocation(app.latitude, app.longitude);
            return fp;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Krishi Plus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF16A34A),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        ),
        home: const _AuthGate(),
        routes: {
          '/login': (_) => const LoginPage(),
          '/home': (_) => const _AppInitializer(),
        },
      ),
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
    return _goHome ? const _AppInitializer() : const LoginPage();
  }
}

class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _loading = true;
  Timer? _timer;
  late final NotificationService _notifService;

  @override
  void initState() {
    super.initState();
    _notifService = NotificationService();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _notifService.initialize(context, () {});
      await context.read<AppProvider>().fetchCurrentLocation();
      if (mounted) {
        final app = context.read<AppProvider>();
        context.read<WeatherProvider>().loadWeather(
          app.latitude,
          app.longitude,
        );
        _startClock();
        setState(() => _loading = false);
      }
    });
  }

  void _startClock() {
    context.read<AppProvider>().refreshDateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) context.read<AppProvider>().refreshDateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const _MainNavigator();
  }
}

class _MainNavigator extends StatefulWidget {
  const _MainNavigator();

  @override
  State<_MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<_MainNavigator> {
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _goto(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      KrishokPage(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
      ForecastPage(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
      LiveServicesPage(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    ];

    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawer: const AppDrawer(),
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _goto,
            backgroundColor: Colors.white,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.agriculture_outlined),
                selectedIcon: Icon(Icons.agriculture_rounded),
                label: 'কৃষক সেবা',
              ),
              NavigationDestination(
                icon: Icon(Icons.cloud_outlined),
                selectedIcon: Icon(Icons.cloud_rounded),
                label: 'আবহাওয়া',
              ),
              NavigationDestination(
                icon: Icon(Icons.language_outlined),
                selectedIcon: Icon(Icons.language_rounded),
                label: 'লাইভ সেবা',
              ),
            ],
          ),
        ),
        const SignalAuraOverlay(),
      ],
    );
  }
}
