import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/analytics_service.dart';
import '../../services/share_service.dart';
import '../resume/resume_optimizer_screen.dart';
import '../resume/resume_list_screen.dart';
import '../settings/settings_screen.dart';
import 'home_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _sharedJobText;

  // Memoized screens that must not be recreated on every build.
  // HomeDashboard and ResumeListScreen are stable — recreating them
  // would trigger initState/_loadData again and create extra provider reads.
  late final HomeDashboard _homeDashboard;
  late final ResumeListScreen _resumeListScreen;
  late final SettingsScreen _settingsScreen;

  static const _screenNames = ['home', 'resumes', 'optimizer', 'settings'];

  @override
  void initState() {
    super.initState();
    _homeDashboard = HomeDashboard(
      onAddJobTap: () => setState(() => _currentIndex = 2),
    );
    _resumeListScreen = const ResumeListScreen();
    _settingsScreen = const SettingsScreen();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsService.instance.logScreenView('home');
    // Check for shared text when the screen first loads
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForSharedText());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when app comes back to foreground after Share Extension writes to App Group.
    // Small delay ensures the native MethodChannel bridge is ready before we read.
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 300), _checkForSharedText);
    }
  }

  Future<void> _checkForSharedText() async {
    final text = await ShareService.getSharedText();
    if (text != null && mounted) {
      setState(() {
        _sharedJobText = text;
        _currentIndex = 2; // Switch to Optimize tab
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all screens in the widget tree (just hidden) so
      // switching tabs never destroys State — HomeDashboard's initState and
      // _loadData are called exactly once for the lifetime of HomeScreen.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _homeDashboard,
          _resumeListScreen,
          ResumeOptimizerScreen(
            initialJobDescription: _sharedJobText,
            onJobAdded: () => setState(() => _currentIndex = 0),
          ),
          _settingsScreen,
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) async {
            // When tapping Optimize tab, check for pending shared text first
            if (index == 2) {
              final text = await ShareService.getSharedText();
              if (mounted) {
                setState(() {
                  if (text != null) _sharedJobText = text;
                  _currentIndex = index;
                });
              }
            } else {
              setState(() {
                _currentIndex = index;
                if (index != 2) _sharedJobText = null;
              });
            }
            AnalyticsService.instance.logScreenView(_screenNames[index]);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textTertiary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description),
              label: 'Resumes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Optimize',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
