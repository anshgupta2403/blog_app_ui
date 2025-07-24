import 'dart:async';

import 'package:blog_app/routing/routes.dart';
import 'package:blog_app/ui/auth/login/widgets/forgot_password_screen.dart';
import 'package:blog_app/ui/auth/login/widgets/launch_screen.dart';
import 'package:blog_app/ui/auth/login/widgets/login_screen.dart';
import 'package:blog_app/ui/auth/login/widgets/otp_verification_screen.dart';
import 'package:blog_app/ui/auth/login/widgets/register_user_screen.dart';
import 'package:blog_app/ui/home/widgets/blog_reader_screen.dart';
import 'package:blog_app/ui/home/widgets/create_blog_post_screen.dart';
import 'package:blog_app/ui/home/widgets/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRouter {
  static GoRouter getRouter() {
    final GoRouter router = GoRouter(
      initialLocation: '/', // always start from launch screen
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(
        FirebaseAuth.instance.authStateChanges(),
      ),
      redirect: _redirect,
      routes: [
        GoRoute(
          name: Routes.login,
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          name: Routes.launch,
          path: '/launch',
          builder: (context, state) => const LaunchScreen(),
        ),
        GoRoute(
          name: Routes.home,
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          name: Routes.forgotPassword,
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          name: Routes.registerUser,
          path: '/register-user',
          builder: (context, state) => const RegisterUserScreen(),
        ),
        GoRoute(
          name: Routes.otpVerificationScreen,
          path: '/otp-verification-screen/:email/:password/:name',
          builder: (context, state) {
            final email = state.pathParameters['email']!;
            final password = state.pathParameters['password']!;
            final name = state.pathParameters['name']!;
            return OTPVerificationScreen(
              email: email,
              password: password,
              name: name,
            );
          },
        ),
        GoRoute(
          name: Routes.blogPost,
          path: '/blog-post',
          builder: (context, state) => const CreatePostBlogScreen(),
        ),
        GoRoute(
          name: Routes.blogDetails,
          path: '/blog-details',
          builder: (context, state) {
            final args = state.extra! as Map<String, dynamic>;
            return BlogReaderScreen(
              postId: args['postId'],
              summary: args['summary'],
            );
          },
        ),
      ],
    );

    return router;
  }
}

// 🔁 Notifier to trigger GoRouter re-evaluation on auth state change
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// 🚦 Dynamic redirect logic based on user login state and current route
Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  final user = FirebaseAuth.instance.currentUser;
  final path = state.uri.toString();

  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  // 1. If it's the first launch, go to /launch only if we're not already on it
  if (isFirstLaunch && path != '/launch') {
    return '/launch';
  }

  // 2. If on launch screen and it's not first launch anymore, send to login or home
  if (!isFirstLaunch && path == '/launch') {
    return user == null ? '/login' : '/';
  }

  // 3. Auth routes logic
  final isAuthRoute =
      path.startsWith('/login') ||
      path.startsWith('/register-user') ||
      path.startsWith('/forgot-password') ||
      path.startsWith('/otp-verification-screen');

  if (user == null && !isAuthRoute && path != '/launch') {
    return '/login';
  }

  if (user != null && isAuthRoute) {
    return '/';
  }

  return null;
}
