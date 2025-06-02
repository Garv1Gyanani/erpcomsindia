import 'package:coms_india/features/task/controller/task_controller.dart';
import 'package:get_it/get_it.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../features/auth/controllers/auth_controller.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Services
  // final storageService = await StorageService().init();
  getIt.registerLazySingleton<StorageService>(() => StorageService());

  getIt.registerSingleton<ApiService>(ApiService());

  // Controllers
  getIt.registerSingleton<AuthController>(AuthController());
  getIt.registerSingleton<TaskStatusController>(TaskStatusController());
  // getIt.registerSingleton<DashboardController>(DashboardController());
}
