import 'package:coms_india/employee/add_contact.dart';
import 'package:coms_india/employee/education_details.dart';
import 'package:coms_india/employee/employee.dart';
import 'package:coms_india/employee/employement_screen.dart';
import 'package:coms_india/employee/govt_details.dart';
import 'package:coms_india/features/home/view/team_page.dart';
import 'package:coms_india/features/task/view/task_page.dart';
import 'package:coms_india/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coms_india/features/auth/view/login_page.dart';
import 'package:coms_india/features/auth/view/OTP_verification.dart';
import 'package:coms_india/features/profile/view/profile.dart';
import 'package:coms_india/core/di/service_locator.dart';
import 'package:coms_india/features/auth/controllers/auth_controller.dart';

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
        builder: (context, state) => const TaskListPage(),
      ),
      GoRoute(
        path: '/employees',
        name: 'employees',
        builder: (context, state) => const EmployeeListPage(),
      ),
      GoRoute(
        path: '/employeeDetails',
        name: 'employeeDetails',
        builder: (context, state) {
          return EmploymentDetailsSection();
        },
      ),

      GoRoute(
        path: '/add-contact',
        name: 'addContact',
        builder: (context, state) =>  ContactFormScreen(),
      ),
      GoRoute(
        path: '/education-details',
        name: 'educationDetails',
        builder: (context, state) =>  EducationalDetailsSection(),
      ),
      GoRoute(
        path: '/govt-details',
        name: 'govtDetails',
        builder: (context, state) =>  GovernmentBankForm(),
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
          return '/home';
        } else {
          return '/login';
        }
      }

      // Prevent access to protected pages when not logged in
      if ((state.matchedLocation == '/home' ||
              state.matchedLocation == '/profile') &&
          authController.currentUser.value == null) {
        print('Redirecting to login from protected page');
        return '/login';
      }

      // Prevent going to login page when already logged in
      if (state.matchedLocation == '/login' &&
          authController.currentUser.value != null) {
        print('Redirecting to home from login page');
        return '/home';
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
