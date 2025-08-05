import 'package:coms_india/client/client_controller.dart';
import 'package:coms_india/core/di/service_locator.dart';
import 'package:coms_india/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:coms_india/config/router/app_router.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coms_india/core/widgets/network_check_widget.dart';
import 'package:provider/provider.dart';
import 'package:coms_india/features/employee/controllers/employee_provider.dart';
import 'package:coms_india/features/attendance/controllers/attendance_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔄 Starting app initialization...');

  // Setup service locator first
  try {
    await setupServiceLocator();

    print('✅ Service locator setup completed');
  } catch (e) {
    print('❌ Error setting up service locator: $e');
    return; // Don't run the app if service locator fails
  }

  // Register GetX controllers
  try {
    // Register AuthController
    Get.put(AuthController());
    print('✅ AuthController registered');

    // Register AttendanceController if not already registered in service locator
    if (!Get.isRegistered<AttendanceController>()) {
      Get.put(getIt<AttendanceController>());
      Get.put(ClientDashboardController());

      print('✅ AttendanceController registered with GetX');
    }
  } catch (e) {
    print('❌ Error registering controllers: $e');
  }

  // Test SharedPreferences
  try {
    final prefs = await SharedPreferences.getInstance();
    print('✅ SharedPreferences initialized successfully: ${prefs.getKeys()}');
  } catch (e) {
    print('❌ Error initializing SharedPreferences: $e');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('🚀 Starting app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => EmployeeProvider()),
        // Use a safer provider registration for AttendanceController
        ChangeNotifierProvider(
          create: (context) {
            try {
              // Try to get from GetIt first, fallback to creating new instance
              if (getIt.isRegistered<AttendanceController>()) {
                return getIt<AttendanceController>();
              } else {
                print(
                    '⚠️ AttendanceController not found in GetIt, creating new instance');
                return AttendanceController();
              }
            } catch (e) {
              print('❌ Error getting AttendanceController: $e');
              // Fallback to creating a new instance
              return AttendanceController();
            }
          },
        ),
      ],
      child: NetworkCheckWidget(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'ERP Coms India Pvt. India',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
