import 'package:coms_india/core/services/api_service.dart';
import 'package:coms_india/core/services/storage_service.dart';
import 'package:coms_india/features/task/controller/task_controller.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/attendance/controllers/attendance_controller.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Services
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // Controllers
  getIt.registerSingleton<AuthController>(AuthController());
  getIt.registerSingleton<TaskStatusController>(TaskStatusController());
  getIt.registerSingleton<AttendanceController>(AttendanceController());
}
