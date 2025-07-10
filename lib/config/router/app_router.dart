import 'package:coms_india/features/employee/views/add_contact.dart';
import 'package:coms_india/features/employee/views/education_details.dart';
import 'package:coms_india/features/employee/views/employee_details.dart';
import 'package:coms_india/features/employee/views/employee_list.dart';
import 'package:coms_india/features/employee/views/employment_screen.dart';
import 'package:coms_india/features/employee/views/employment_details.dart';
import 'package:coms_india/features/employee/views/esic_declaration_form.dart';
import 'package:coms_india/features/employee/views/epf_declaration_form.dart';
import 'package:coms_india/features/employee/views/govt_details.dart';
import 'package:coms_india/features/employee/views/nomination_form.dart';
import 'package:coms_india/features/employee/views/basic_info.dart';
import 'package:coms_india/features/home/view/team_page.dart';
import 'package:coms_india/features/task/view/task_page.dart';
import 'package:coms_india/features/alerts/view/alerts_page.dart';
import 'package:coms_india/features/tickets/view/ticket_page.dart';
import 'package:coms_india/features/shift/views/shift_list_page.dart';
import 'package:coms_india/features/shift/views/add_shift_page.dart';
import 'package:coms_india/features/shift/views/assign_shift_page.dart';
import 'package:coms_india/features/shift/views/site_shifts_page.dart';
import 'package:coms_india/features/shift/views/assign_employee_page.dart';
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
      // Team page (Home/Dashboard) - Index 0
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
      // Tasks page - Index 1
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) => GlobalBottomNavigation(
          currentRoute: state.uri.path,
          child: const TaskListPage(),
        ),
      ),
      // Alerts page - Index 2
      GoRoute(
        path: '/alerts',
        name: 'alerts',
        builder: (context, state) => GlobalBottomNavigation(
          currentRoute: state.uri.path,
          child: const AlertsPage(),
        ),
      ),
      // Tickets page - Index 3
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
      // Shift Management Routes
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
      final AuthController authController = getIt<AuthController>();

      // Splash screen handling
      if (state.matchedLocation == '/splash') {
        // Check login status
        final isLoggedIn = await authController.checkLoginStatus();
        print('Redirect from splash - isLoggedIn: $isLoggedIn');

        if (isLoggedIn) {
          return '/team';
        } else {
          return '/login';
        }
      }

      // Prevent access to protected pages when not logged in
      if ((state.matchedLocation == '/home' ||
              state.matchedLocation == '/team' ||
              state.matchedLocation == '/tasks' ||
              state.matchedLocation == '/alerts' ||
              state.matchedLocation == '/tickets' ||
              state.matchedLocation == '/shifts' ||
              state.matchedLocation == '/assign-shift' ||
              state.matchedLocation == '/site-shifts' ||
              state.matchedLocation == '/assign-employee' ||
              state.matchedLocation == '/profile') &&
          authController.currentUser.value == null) {
        print('Redirecting to login from protected page');
        return '/login';
      }

      // Prevent going to login page when already logged in
      if (state.matchedLocation == '/login' &&
          authController.currentUser.value != null) {
        print('Redirecting to team from login page');
        return '/team';
      }

      // No redirect needed
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Text('No route defined for ${state.uri.path}'),
      ),
    ),
  );
}
