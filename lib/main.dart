import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:blog_app/data/repositories/auth_repository.dart';
import 'package:blog_app/data/repositories/blog_repository.dart';
import 'package:blog_app/data/service/auth_service.dart';
import 'package:blog_app/data/service/blog_service.dart';
import 'package:blog_app/data/service/firebase_notifications_service.dart';
import 'package:blog_app/firebase_options.dart';
import 'package:blog_app/l10n/app_localizations.dart';
import 'package:blog_app/routing/router.dart';
import 'package:blog_app/ui/auth/login/bloc/auth_bloc.dart';
import 'package:blog_app/ui/core/theme/app_theme.dart';
import 'package:blog_app/ui/core/utils/otp_manager_utils.dart';
import 'package:blog_app/ui/home/bloc/home_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load environment variables
  await dotenv.load(fileName: '.env');

  if (kDebugMode) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  }

  final authService = AuthService();
  final blogService = BlogService();
  final authRepository = AuthRepository(authService);
  final blogRepository = BlogRepository(blogService);
  final otpManager = OtpManager();

  FirebaseMessaging.onBackgroundMessage(
    FirebaseNotificationsService.firebaseBackgroundHandler,
  );

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

class MyApp extends StatefulWidget {
  final AuthRepository authRepository;
  final BlogRepository blogRepository;
  final OtpManager otpManager;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.blogRepository,
    required this.otpManager,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _uriLinkSub;

  @override
  void initState() {
    super.initState();

    // Handle initial deep link
    _handleInitialUri();

    // Handle any stream updates (while app is running)
    _uriLinkSub = _appLinks.uriLinkStream.listen((Uri uri) {
      _navigateToDeepLink(uri);
    });
  }

  Future<void> _handleInitialUri() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      // Delay until GoRouter is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToDeepLink(uri);
      });
    }
  }

  void _navigateToDeepLink(Uri uri) {
    final id = uri
        .queryParameters['id']; // or uri.pathSegments if your URL is like /blog/123
    if (id != null) {
      // Wait until navigation system is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          GoRouter.of(
            ctx,
          ).pushNamed(uri.path, extra: {'postId': id, 'summary': null});
        } else {
          debugPrint('Context is null when navigating to deep link.');
        }
      });
    }
  }

  @override
  void dispose() {
    _uriLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(widget.authRepository, widget.otpManager),
        ),
        BlocProvider(create: (_) => HomeBloc(widget.blogRepository)),
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
