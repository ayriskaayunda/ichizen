import 'package:ichizen/routes/app_routes.dart';
import 'package:ichizen/screens/attendance/request_screen.dart';
import 'package:ichizen/screens/auth/forgot_password_screen.dart';
import 'package:ichizen/screens/auth/login_screen.dart';
import 'package:ichizen/screens/auth/register_screen.dart';
import 'package:ichizen/screens/auth/reset_password_with_otp_screen.dart';
import 'package:ichizen/screens/main_bottom_navigation_bar.dart';
import 'package:ichizen/screens/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      initialRoute: AppRoutes.initial,
      routes: {
        AppRoutes.initial: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.main: (context) => MainBottomNavigationBar(),
        AppRoutes.request: (context) => RequestScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.resetPasswordWithOtp: (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          if (email == null) {
            // Handle case where email is not passed, maybe navigate back or show error
            return const Text('Error: Email not provided for password reset.');
          }
          return ResetPasswordWithOtpScreen(email: email);
        },
        // AppRoutes.attendanceList: (context) => AttendanceListScreen(),
        // AppRoutes.report: (context) => const PersonReportScreen(),
        // AppRoutes.profile: (context) => const ProfileScreen(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}
