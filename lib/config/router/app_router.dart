import 'package:coms_india/client/deshboard.dart';
import 'package:coms_india/features/employee/views/add_contact.dart';
import 'package:coms_india/features/employee/views/education_details.dart';
import 'package:coms_india/features/employee/views/employee_details.dart';
import 'package:coms_india/features/employee/views/employee_edit.dart';
import 'package:coms_india/features/employee/views/employee_list.dart';
import 'package:coms_india/features/employee/views/employment_screen.dart';
import 'package:coms_india/features/employee/views/employment_details.dart';
import 'package:coms_india/features/employee/views/esic_declaration_form.dart';
import 'package:coms_india/features/employee/views/epf_declaration_form.dart';
import 'package:coms_india/features/employee/views/govt_details.dart';
import 'package:coms_india/features/employee/views/nomination_form.dart';
import 'package:coms_india/features/employee/views/basic_info.dart';
import 'package:coms_india/features/employee/views/weekend_assignment_page.dart';
import 'package:coms_india/features/home/view/team_page.dart';
import 'package:coms_india/features/shift/controllers/rotationl_shift.dart';
import 'package:coms_india/features/shift/views/weekendlist.dart';
import 'package:coms_india/features/task/view/task_page.dart';
import 'package:coms_india/features/alerts/view/alerts_page.dart';
import 'package:coms_india/features/tickets/view/ticket_page.dart';
import 'package:coms_india/features/shift/views/shift_list_page.dart';
import 'package:coms_india/features/shift/views/add_shift_page.dart';
import 'package:coms_india/features/shift/views/assign_shift_page.dart';
import 'package:coms_india/features/shift/views/site_shifts_page.dart';
import 'package:coms_india/features/shift/views/assign_employee_page.dart';
import 'package:coms_india/features/attendance/views/attendance_page.dart';
import 'package:coms_india/features/attendance/views/employee_attendance_details_page.dart';
import 'package:coms_india/features/attendance/models/attendance_model.dart';
import 'package:coms_india/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coms_india/features/auth/view/login_page.dart';
import 'package:coms_india/features/auth/view/OTP_verification.dart';
import 'package:coms_india/features/profile/view/profile.dart';
import 'package:coms_india/core/di/service_locator.dart';
import 'package:coms_india/features/auth/controllers/auth_controller.dart';
import 'package:coms_india/global_sheet.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/verify-otp/:phoneNumber',
        name: 'verifyOTP',
        builder: (context, state) {
          final phoneNumber = state.pathParameters['phoneNumber'] ?? '';
          return OTPVerificationScreen(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: '/client-dashboard',
        name: 'client-dashboard',
        builder: (context, state) => const ClientDashboardPage(),
      ),
      GoRoute(
        path: '/team',
        name: 'team',
        builder: (context, state) => GlobalBottomNavigation(
          currentRoute: state.uri.path,
          child: const SupervisorHomePage(),
        ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const SupervisorHomePage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) => GlobalBottomNavigation(
          currentRoute: state.uri.path,
          child: const TaskListPage(),
        ),
      ),
      GoRoute(
        path: '/alerts',
        name: 'alerts',
        builder: (context, state) => GlobalBottomNavigation(
          currentRoute: state.uri.path,
          child: const AlertsPage(),
        ),
      ),
      GoRoute(
        path: '/tickets',
        name: 'tickets',
        builder: (context, state) => GlobalBottomNavigation(
          currentRoute: state.uri.path,
          child: const TicketsPage(),
        ),
      ),
      GoRoute(
        path: '/employees',
        name: 'employees',
        builder: (context, state) => GlobalBottomNavigation(
          currentRoute: state.uri.path,
          child: const EmployeeListPage(),
        ),
      ),
      GoRoute(
        path: '/attendance',
        name: 'attendance',
        builder: (context, state) => const AttendancePage(),
      ),
      GoRoute(
        path: '/employee-attendance-details/:userId',
        name: 'employeeAttendanceDetails',
        builder: (context, state) {
          final userId = int.tryParse(state.pathParameters['userId'] ?? '');
          final attendanceRecordsJson =
              state.extra as List<Map<String, dynamic>>?;

          if (userId == null || attendanceRecordsJson == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid attendance details')),
            );
          }

          final attendanceRecords = attendanceRecordsJson
              .map((json) => AttendanceDetail.fromJson(json))
              .toList();

          final user = attendanceRecords.isNotEmpty
              ? attendanceRecords.first.user
              : null;

          if (user == null) {
            return const Scaffold(
              body: Center(child: Text('User information not found')),
            );
          }

          return EmployeeAttendanceDetailsPage(
            attendanceRecords: attendanceRecords,
            user: user,
          );
        },
      ),
      GoRoute(
        path: '/employee/:id',
        name: 'employeeDetails',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          final name = state.extra as String?;
          if (id != null) {
            return EmployeeDetailsPage(
              userId: id,
              employeeName: name ?? 'Employee Details',
            );
          }
          return const Scaffold(
            body: Center(
              child: Text('Invalid Employee ID'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/employee/edit/:id',
        name: 'employeeEdit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          final Map<String, dynamic> extra =
              state.extra as Map<String, dynamic>;
          final name = extra['employeeName'] as String;
          // final employeeData = extra['employeeData'] as Map<String, dynamic>;

          if (id != null) {
            return EmployeeEditPage(
              userId: id,
              employeeName: name,
            );
          }
          return const Scaffold(
            body: Center(
              child: Text('Invalid Employee ID'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/add-employee',
        name: 'addEmployee',
        builder: (context, state) => const AddEmployeePage(),
      ),
      GoRoute(
        path: '/employment-details',
        name: 'employment_details',
        builder: (context, state) => const EmploymentDetailsSection(),
      ),
      GoRoute(
        path: '/previous-employment',
        name: 'previous_employment',
        builder: (context, state) => const EmploymentDetailsScreen(),
      ),
      GoRoute(
        path: '/contact-details',
        name: 'contact_details',
        builder: (context, state) => ContactFormScreen(),
      ),
      GoRoute(
        path: '/education-details',
        name: 'education_details',
        builder: (context, state) => EducationalDetailsSection(),
      ),
      GoRoute(
        path: '/govt-bank-details',
        name: 'govt_bank_details',
        builder: (context, state) => GovernmentBankForm(),
      ),
      GoRoute(
        path: '/esic-declaration',
        name: 'esic_declaration',
        builder: (context, state) => EsicDeclarationForm(),
      ),
      GoRoute(
        path: '/epf-declaration',
        name: 'epf_declaration',
        builder: (context, state) => EpfDeclarationForm(),
      ),
      GoRoute(
        path: '/nomination-form',
        name: 'nomination_form',
        builder: (context, state) => NominationFormScreen(),
      ),
      GoRoute(
        path: '/shift-rotational',
        name: 'shift-rotational',
        builder: (context, state) => RotationalShiftPage(),
      ),
      GoRoute(
        path: '/weekend',
        name: 'weekend',
        builder: (context, state) => GlobalBottomNavigation(
          currentRoute: state.uri.path,
          child: WeekendAssignmentPage(),
        ),
      ),
      GoRoute(
        path: '/weekendlist',
        name: 'weekendlist',
        builder: (context, state) => GlobalBottomNavigation(
          currentRoute: state.uri.path,
          child: WeekendListPage(),
        ),
      ),
      GoRoute(
        path: '/shifts',
        name: 'shifts',
        builder: (context, state) => GlobalBottomNavigation(
          currentRoute: state.uri.path,
          child: const ShiftListPage(),
        ),
      ),
      GoRoute(
        path: '/site-shifts',
        name: 'site-shifts',
        builder: (context, state) => GlobalBottomNavigation(
          currentRoute: state.uri.path,
          child: const SiteShiftsPage(),
        ),
      ),
      GoRoute(
        path: '/assign-employee',
        name: 'assign-employee',
        builder: (context, state) => const AssignEmployeePage(),
      ),
      GoRoute(
        path: '/assign-shift',
        name: 'assignShift',
        builder: (context, state) {
          final preSelectedSite = state.uri.queryParameters['site'];
          return AssignShiftPage(preSelectedSite: preSelectedSite);
        },
      ),
      GoRoute(
        path: '/add-shift',
        name: 'addShift',
        builder: (context, state) => const AddShiftPage(),
      ),
      GoRoute(
        path: '/edit-shift/:id',
        name: 'editShift',
        builder: (context, state) {
          final shiftId = state.pathParameters['id'];
          return AddShiftPage(shiftId: shiftId);
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) async {
      try {
        final AuthController authController = getIt<AuthController>();
        final currentLocation = state.matchedLocation;

        print('🔄 Router redirect - Location: $currentLocation');

        if (currentLocation == '/splash') {
          final isLoggedIn = await authController.checkLoginStatus();
          print(
              '✅ Redirect from splash - isLoggedIn: $isLoggedIn, loginAs: ${authController.loginAs.value}');

          if (isLoggedIn) {
            if (authController.isClient()) {
              print('🏢 Redirecting client to dashboard');
              return '/client-dashboard';
            } else {
              print('👥 Redirecting employee to team');
              return '/team';
            }
          } else {
            print('🔐 Redirecting to login');
            return '/login';
          }
        }

        final hasToken = authController.token.value.isNotEmpty;
        final hasUser = authController.currentUser.value != null;
        final isUserLoggedIn = hasToken && hasUser;
        final isClientUser = authController.isClient();

        print(
            '📊 Auth status - Token: $hasToken, User: $hasUser, Logged in: $isUserLoggedIn, Is client: $isClientUser');
        print('  Token: ${authController.token.value}');
        print('  User: ${authController.currentUser.value}');
        print(
            '  Logged in: ${authController.token.value.isNotEmpty && authController.currentUser.value != null}');

        if ((hasToken && !hasUser) || (!hasToken && hasUser)) {
          print('⚠️ Inconsistent auth state detected, redirecting to login');
          return '/login';
        }

        final employeeOnlyRoutes = [
          '/team',
          '/home',
          '/tasks',
          '/alerts',
          '/tickets',
          '/attendance',
          '/shifts',
          '/weekends',
          '/assign-shift',
          '/site-shifts',
          '/assign-employee',
          '/employees',
          '/weekend',
          '/weekendlist',
          '/shift-rotational',
        ];

        final clientOnlyRoutes = [
          '/client-dashboard',
        ];

        final commonProtectedRoutes = [
          '/profile',
        ];

        final isEmployeeRoute = employeeOnlyRoutes.contains(currentLocation);
        final isClientRoute = clientOnlyRoutes.contains(currentLocation);
        final isCommonRoute = commonProtectedRoutes.contains(currentLocation);
        final isProtectedRoute =
            isEmployeeRoute || isClientRoute || isCommonRoute;

        if (isProtectedRoute && !isUserLoggedIn) {
          print(
              '🚫 Redirecting to login - accessing protected route without authentication');
          return '/login';
        }

        if (isEmployeeRoute && isUserLoggedIn && isClientUser) {
          print(
              '🚫 Client trying to access employee route, redirecting to client dashboard');
          return '/client-dashboard';
        }

        if (isClientRoute && isUserLoggedIn && !isClientUser) {
          print(
              '🚫 Employee trying to access client route, redirecting to team');
          return '/team';
        }

        if (currentLocation == '/login' && isUserLoggedIn) {
          if (isClientUser) {
            print('🏢 Logged in client redirected from login to dashboard');
            return '/client-dashboard';
          } else {
            print('👥 Logged in employee redirected from login to team');
            return '/team';
          }
        }

        if (currentLocation.startsWith('/verify-otp/')) {
          print('✅ Allowing access to OTP verification');
          return null;
        }

        print('✅ No redirect needed for: $currentLocation');
        return null;
      } catch (e) {
        print('❌ Error in router redirect: $e');
        return '/login';
      }
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No route defined for ${state.uri.path}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                try {
                  final AuthController authController = getIt<AuthController>();
                  if (authController.currentUser.value != null) {
                    if (authController.isClient()) {
                      context.go('/client-dashboard');
                    } else {
                      context.go('/team');
                    }
                  } else {
                    context.go('/login');
                  }
                } catch (e) {
                  context.go('/login');
                }
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
