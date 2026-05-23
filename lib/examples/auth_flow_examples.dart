import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../screens/main_screen.dart';
import '../../screens/auth/welcome_screen.dart';
import '../../screens/auth/signin_screen.dart';

/// This file demonstrates different ways to set up your authentication flow
/// Choose the approach that best fits your app's needs

// ============================================================================
// APPROACH 1: Two-Step Flow (Welcome → Sign In)
// Best for: Marketing your app, showcasing features first
// ============================================================================

class AppWithWelcomeScreen extends StatelessWidget {
  const AppWithWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KharchaBook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Start with welcome screen (landing page)
      home: const WelcomeScreen(),
      routes: {'/signin': (context) => const SignInScreen()},
    );
  }
}

// ============================================================================
// APPROACH 2: Direct to Sign In
// Best for: Returning users, faster onboarding
// ============================================================================

class AppDirectToSignIn extends StatelessWidget {
  const AppDirectToSignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KharchaBook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Skip welcome, go straight to sign in
      home: const SignInScreen(),
    );
  }
}

// ============================================================================
// APPROACH 3: Smart Detection (First Time vs Returning)
// Best for: Best user experience - shows welcome once, then remembers
// ============================================================================

class AppWithSmartDetection extends StatefulWidget {
  const AppWithSmartDetection({super.key});

  @override
  State<AppWithSmartDetection> createState() => _AppWithSmartDetectionState();
}

class _AppWithSmartDetectionState extends State<AppWithSmartDetection> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KharchaBook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: _isFirstTime(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          final isFirstTime = snapshot.data ?? true;

          // First time: show welcome with features
          if (isFirstTime) {
            return const WelcomeScreen();
          }

          // Returning: go straight to sign in
          return const SignInScreen();
        },
      ),
    );
  }

  Future<bool> _isFirstTime() async {
    // Check if user has seen welcome screen before
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;

    if (!hasSeenWelcome) {
      // Mark as seen for next time
      await prefs.setBool('hasSeenWelcome', true);
      return true;
    }

    return false;
  }
}

// ============================================================================
// APPROACH 4: Check Auth State
// Best for: Apps with persistent login
// ============================================================================

class AppWithAuthCheck extends StatelessWidget {
  const AppWithAuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KharchaBook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<AuthState>(
        future: _checkAuthState(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          final authState = snapshot.data ?? AuthState.notAuthenticated;

          switch (authState) {
            case AuthState.authenticated:
              // User is signed in, go to main screen
              return MainScreen(currency: '₹', onSettingsChanged: () {});

            case AuthState.firstTime:
              // First time user, show welcome
              return const WelcomeScreen();

            case AuthState.notAuthenticated:
              // User has been here before but not signed in
              return const SignInScreen();
          }
        },
      ),
    );
  }

  Future<AuthState> _checkAuthState() async {
    await AuthService.initialize();

    if (AuthService.isSignedIn) {
      return AuthState.authenticated;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;

    return hasSeenWelcome ? AuthState.notAuthenticated : AuthState.firstTime;
  }
}

enum AuthState { authenticated, notAuthenticated, firstTime }

// ============================================================================
// Helper: Simple Splash Screen
// ============================================================================

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'KharchaBook',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// COMPARISON GUIDE
// ============================================================================

/// WHICH APPROACH SHOULD YOU USE?
///
/// ┌─────────────────────────────────────────────────────────────────┐
/// │ APPROACH                │ PROS              │ CONS              │
/// ├─────────────────────────────────────────────────────────────────┤
/// │ 1. Two-Step Flow        │ • Shows features  │ • Extra step      │
/// │    (Welcome → Sign In)  │ • Marketing       │ • Slightly slower │
/// │                         │ • Beautiful       │                   │
/// ├─────────────────────────────────────────────────────────────────┤
/// │ 2. Direct Sign In       │ • Fast           │ • No intro        │
/// │                         │ • Simple          │ • Less engaging   │
/// ├─────────────────────────────────────────────────────────────────┤
/// │ 3. Smart Detection      │ • Best UX         │ • More complex    │
/// │    (First time check)   │ • Welcome once    │ • Requires prefs  │
/// ├─────────────────────────────────────────────────────────────────┤
/// │ 4. Auth Check           │ • Auto login      │ • Most complex    │
/// │    (Persistent login)   │ • Seamless        │ • More code       │
/// └─────────────────────────────────────────────────────────────────┘
///
/// RECOMMENDATION:
/// - New app? → Approach 1 (Two-Step Flow)
/// - Utility app? → Approach 4 (Auth Check)
/// - Beta testing? → Approach 2 (Direct Sign In)
/// - Production ready? → Approach 3 or 4

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/// EXAMPLE 1: Basic Setup
///
/// In your main.dart:
/// ```dart
/// void main() {
///   runApp(const AppWithWelcomeScreen());
/// }
/// ```

/// EXAMPLE 2: With Firebase Initialization
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   await AuthService.initialize();
///   runApp(const AppWithAuthCheck());
/// }
/// ```

/// EXAMPLE 3: Custom Routing
///
/// ```dart
/// MaterialApp(
///   initialRoute: '/',
///   routes: {
///     '/': (context) => const WelcomeScreen(),
///     '/signin': (context) => const SignInScreen(),
///     '/home': (context) => MainScreen(...),
///   },
/// )
/// ```

// ============================================================================
// ADVANCED: Custom Welcome Screen
// ============================================================================

class CustomWelcomeFlow extends StatefulWidget {
  const CustomWelcomeFlow({super.key});

  @override
  State<CustomWelcomeFlow> createState() => _CustomWelcomeFlowState();
}

class _CustomWelcomeFlowState extends State<CustomWelcomeFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Onboarding pages
          PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: [
              _buildOnboardingPage(
                icon: Icons.account_balance_wallet,
                title: 'Track Expenses',
                description: 'Monitor your spending effortlessly',
              ),
              _buildOnboardingPage(
                icon: Icons.group,
                title: 'Share with Family',
                description: 'Collaborate on family finances',
              ),
              _buildOnboardingPage(
                icon: Icons.insights,
                title: 'Get Insights',
                description: 'Understand your financial patterns',
              ),
            ],
          ),

          // Page indicators
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // Next/Get Started button
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < 2) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  // Last page, navigate to sign in
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  );
                }
              },
              child: Text(_currentPage < 2 ? 'Next' : 'Get Started'),
            ),
          ),

          // Skip button
          Positioned(
            top: 50,
            right: 24,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              },
              child: const Text('Skip', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purple.shade300],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 120, color: Colors.white),
              const SizedBox(height: 40),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Import this file to see all examples
// Then choose the approach that fits your needs!
// ============================================================================
