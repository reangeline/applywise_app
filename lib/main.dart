import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/transitions.dart';
import 'config/theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/pipeline_provider.dart';
import 'providers/resume_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/analytics_service.dart';
import 'services/storage_service.dart';
import 'services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required by Analytics, Messaging, etc.)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize storage
  await StorageService().init();

  // Initialize home widget shared container (non-fatal if native side not configured yet)
  await WidgetService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => ResumeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PipelineProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Hirefy',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          navigatorObservers: [
            AnalyticsService.instance.observer,
          ],
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialRoute();
    });
  }

  Future<void> _checkInitialRoute() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    // Inicializa notificações cedo para mostrar o prompt de permissão
    try {
      await notificationProvider.initialize();
    } catch (e) {
      debugPrint('⚠️ Notifications init skipped: $e');
    }

    if (!mounted) return;

    // Load persisted pipeline data
    final pipelineProvider = Provider.of<PipelineProvider>(context, listen: false);
    await pipelineProvider.load();

    if (!mounted) return;

    // Wire push-notification → pipeline card auto-update
    notificationProvider.setOptimizationCompleteHandler(
      pipelineProvider.handleOptimizationNotification,
    );

    final storageService = StorageService();
    storageService.isFirstLaunch(); // keeps first-launch flag logic intact

    if (authProvider.isAuthenticated) {
      // Go to home
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.loadSubscription();
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        AppTransitions.fadeSlide(const HomeScreen()),
      );
    } else {
      // Not authenticated: always show onboarding (new user or logged out/deleted)
      Navigator.of(context).pushReplacement(
        AppTransitions.fadeSlide(const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/logo.png',
              width: 120,
              height: 120,

            ),
            const SizedBox(height: 24),
            Text(
              'Hirefy',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI Resume Optimizer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
