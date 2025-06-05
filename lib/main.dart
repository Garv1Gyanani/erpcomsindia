import 'package:coms_india/core/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:coms_india/config/router/app_router.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  try {
    final prefs = await SharedPreferences.getInstance();
    print('SharedPreferences initialized successfully: ${prefs.getKeys()}');
  } catch (e) {
    print('Error initializing SharedPreferences: $e');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ERP Coms India Pvt. India',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
