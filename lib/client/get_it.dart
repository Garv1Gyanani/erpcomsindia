// import 'package:coms_india/core/services/api_service.dart';
// import 'package:coms_india/core/services/storage_service.dart';
// import 'package:get_it/get_it.dart';
// import 'package:dio/dio.dart';
// import '../../features/attendance/controllers/attendance_controller.dart';

// final GetIt getIt = GetIt.instance;

// Future<void> setupServiceLocator() async {
//   try {
//     print('🔄 Setting up service locator...');

//     // Register Dio instance
//     getIt.registerLazySingleton<Dio>(() {
//       final dio = Dio();

//       // Configure Dio with interceptors, timeouts, etc.
//       dio.options.connectTimeout = const Duration(seconds: 30);
//       dio.options.receiveTimeout = const Duration(seconds: 30);
//       dio.options.sendTimeout = const Duration(seconds: 30);

//       // Add logging interceptor for debugging
//       dio.interceptors.add(LogInterceptor(
//         requestBody: true,
//         responseBody: true,
//         requestHeader: true,
//         responseHeader: true,
//         error: true,
//       ));

//       return dio;
//     });

//     // Register StorageService first (no dependencies)
//     getIt.registerLazySingleton<StorageService>(() => StorageService());
//     print('✅ StorageService registered');

//     // Register ApiService (depends on Dio)
//     getIt.registerLazySingleton<ApiService>(() => ApiService());
//     print('✅ ApiService registered');

//     // Register AttendanceController (depends on ApiService and StorageService)
//     getIt.registerLazySingleton<AttendanceController>(
//         () => AttendanceController());
//     print('✅ AttendanceController registered');

//     // Wait for all services to be ready
//     await getIt.allReady();

//     print('✅ Service locator initialized successfully');
//     print('🔍 Registered services: ${getIt.allReadySync()}');
//   } catch (e) {
//     print('❌ Error setting up service locator: $e');
//     rethrow;
//   }
// }
