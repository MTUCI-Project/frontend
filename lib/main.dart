import 'package:flutter/material.dart';
import 'Auth/auth_screen.dart';
import 'Internet/connectivity_service.dart';
import 'Internet/noInternetScreen.dart';
import 'Main/mainScreen.dart';
import 'Register/registerScreen.dart';
import 'Register/registerScreencCode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OncastApp());
}

class OncastApp extends StatefulWidget {
  const OncastApp({super.key});

  @override
  State<OncastApp> createState() => _OncastAppState();
}

class _OncastAppState extends State<OncastApp> {
  late final ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _connectivityService.addListener(_handleConnectivityChanged);
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_handleConnectivityChanged);
    _connectivityService.dispose();
    super.dispose();
  }

  void _handleConnectivityChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'oncast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF66DEDD)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/register': (context) => const RegisterScreen(),
        '/register-code': (context) => const RegisterCodeScreen(),
        '/home': (context) => const MainScreen(),
      },
      builder: (context, child) {
        final showOffline = !_connectivityService.isOnline;
        return Stack(
          children: [
            if (child != null) child,
            if (showOffline)
              const Positioned.fill(
                child: NoInternetScreen(),
              ),
          ],
        );
      },
    );
  }
}

