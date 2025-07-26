import 'dart:io';

import 'package:blog_app/data/repositories/auth_repository.dart';
import 'package:blog_app/data/repositories/blog_repository.dart';
import 'package:blog_app/data/service/auth_service.dart';
import 'package:blog_app/data/service/blog_service.dart';
import 'package:blog_app/routing/router.dart';
import 'package:blog_app/ui/auth/login/bloc/auth_bloc.dart';
import 'package:blog_app/ui/core/theme/app_theme.dart';
import 'package:blog_app/firebase_options.dart';
import 'package:blog_app/l10n/app_localizations.dart';
import 'package:blog_app/ui/core/utils/otp_manager_utils.dart';
import 'package:blog_app/ui/home/bloc/home_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  }
  final authService = AuthService();
  final blogService = BlogService();
  final authRepository = AuthRepository(authService);
  final blogRepository = BlogRepository(blogService);
  final otpManager = OtpManager();
  runApp(
    DevicePreview(
      enabled: !kIsWeb && !Platform.isAndroid,
      builder: (BuildContext context) => MyApp(
        authRepository: authRepository,
        blogRepository: blogRepository,
        otpManager: otpManager,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final BlogRepository blogRepository;
  final OtpManager otpManager;
  const MyApp({
    super.key,
    required this.authRepository,
    required this.blogRepository,
    required this.otpManager,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepository, otpManager)),
        BlocProvider(create: (_) => HomeBloc(blogRepository)),
      ],
      child: MaterialApp.router(
        title: 'Flutter Demo',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: AppRouter.getRouter(),
        debugShowCheckedModeBanner: false,
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
      ),
    );
  }
}
