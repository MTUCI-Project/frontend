import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'Api/apiService.dart';
import 'Auth/authMain.dart';
import 'Auth/authScreen.dart';
import 'Internet/internetService.dart';
import 'Internet/noInternetScreen.dart';
import 'Main/mainScreen.dart';
import 'Register/registerMain.dart';
import 'Register/registerScreen.dart';
import 'welcome/WelcomeScreen.dart';
import 'welcome/nextInfo.dart';
import 'welcome/userFinal.dart';
import 'welcome/userInfo1.dart';
import 'welcome/userInfo2.dart';
import 'welcome/userInfo3.dart';
import 'welcome/userInfo4.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await ApiService.instance.initialize();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final InternetService _internetService = InternetService();
  late Future<Map<String, dynamic>> _initialRoute = _determineInitialRoute();

  Future<Map<String, dynamic>> _determineInitialRoute() async {
    if (!await ApiService.instance.restoreSession()) {
      return {'route': '/auth', 'partnerName': null};
    }
    final answers = await ApiService.instance.partnerAnswers();
    if (answers['partner.completed'] == true) {
      final basic = answers['partner.basic'] as Map<String, dynamic>? ?? {};
      return {
        'route': '/mainScreen',
        'partnerName': basic['name'] ?? 'Партнёр',
      };
    }
    return {'route': '/welcome', 'partnerName': null};
  }

  void _recheckRoute() {
    setState(() {
      _initialRoute = _determineInitialRoute();
    });
  }

  Future<void> _continueAfterSignIn(BuildContext context) async {
    final answers = await ApiService.instance.partnerAnswers();
    if (!context.mounted) return;

    if (answers['partner.completed'] == true) {
      final basic = answers['partner.basic'] as Map<String, dynamic>? ?? {};
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/mainScreen',
        (_) => false,
        arguments: {'partnerName': basic['name'] ?? 'Партнёр'},
      );
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
  }

  @override
  void dispose() {
    _internetService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _initialRoute,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final data = snapshot.data!;
        final initialRoute = data['route'] as String;
        final partnerName = data['partnerName'] as String?;
        return StreamBuilder<bool>(
          stream: _internetService.connectionStatusStream,
          initialData: true,
          builder: (context, connection) {
            return MaterialApp(
              title: 'Relia',
              debugShowCheckedModeBanner: false,
              home: initialRoute == '/mainScreen'
                  ? MainScreen(
                      partnerId: 1,
                      partnerName: partnerName ?? 'Партнёр',
                    )
                  : null,
              initialRoute: initialRoute == '/mainScreen' ? null : initialRoute,
              routes: _routes(),
              builder: (context, child) => Stack(
                children: [
                  if (child != null) child,
                  if (!(connection.data ?? true))
                    const Positioned.fill(child: NoInternetScreen()),
                ],
              ),
              theme: ThemeData(
                useMaterial3: true,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFFFAEDCD),
                  foregroundColor: Colors.brown,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, WidgetBuilder> _routes() => {
    '/auth': (context) => AuthScreen(
      authMain: BackendAuthMain(),
      onSignedIn: () => _continueAfterSignIn(context),
      onRegisterPressed: () => Navigator.pushNamed(context, '/register'),
    ),
    '/register': (context) => RegisterScreen(
      registerMain: BackendRegisterMain(),
      onRegistered: () {
        _recheckRoute();
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
      },
    ),
    '/welcome': (context) => WelcomeScreen(
      onStartPressed: () => Navigator.pushNamed(context, '/home'),
    ),
    '/home': (context) => NextInfo(
      onContinuePressed: () => Navigator.pushNamed(context, '/userInfo1'),
    ),
    '/userInfo1': (context) => UserInfo1(
      onNextPressed: (_) => Navigator.pushNamed(
        context,
        '/userInfo2',
        arguments: const {'partnerId': 1},
      ),
      onBackPressed: () => Navigator.pop(context),
    ),
    '/userInfo2': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      return UserInfo2(
        partnerId: args['partnerId'] as int,
        onNextPressed: (id) => Navigator.pushNamed(
          context,
          '/userInfo3',
          arguments: {'partnerId': id},
        ),
        onBackPressed: () => Navigator.pop(context),
      );
    },
    '/userInfo3': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      return UserInfo3(
        partnerId: args['partnerId'] as int,
        onNextPressed: (id) => Navigator.pushNamed(
          context,
          '/userInfo4',
          arguments: {'partnerId': id},
        ),
        onBackPressed: () => Navigator.pop(context),
      );
    },
    '/userInfo4': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      return UserInfo4(
        partnerId: args['partnerId'] as int,
        onCompletePressed: () async {
          final answers = await ApiService.instance.partnerAnswers();
          final basic = answers['partner.basic'] as Map<String, dynamic>? ?? {};
          if (!context.mounted) return;
          Navigator.pushNamed(
            context,
            '/userFinal',
            arguments: {'partnerName': basic['name'] ?? 'Партнёр'},
          );
        },
        onBackPressed: () => Navigator.pop(context),
      );
    },
    '/userFinal': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      final name = args['partnerName'] as String? ?? 'Партнёр';
      return UserFinal(
        partnerId: 1,
        partnerName: name,
        onCompletePressed: () {
          _recheckRoute();
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/mainScreen',
            (_) => false,
            arguments: {'partnerName': name},
          );
        },
      );
    },
    '/mainScreen': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      return MainScreen(
        partnerId: 1,
        partnerName: args?['partnerName'] as String? ?? 'Партнёр',
      );
    },
  };
}
