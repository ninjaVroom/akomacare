import 'package:flutter/material.dart';

import 'screens/auth.dart';
import 'screens/calculators.dart';
import 'screens/games.dart';
import 'screens/guides.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.i.load();
  runApp(const AkomaCareApp());
}

class AkomaCareApp extends StatelessWidget {
  const AkomaCareApp({super.key});

  static const _auth = {'/onboarding', '/signin', '/signup', '/forgot'};

  static Widget _page(RouteSettings s) {
    final a = s.arguments;
    // Signed-out users can only reach onboarding and auth.
    if (AppState.i.user == null && !_auth.contains(s.name)) return const SignInScreen();
    // Routes that need arguments fall back to their parent list when opened
    // without them (web refresh / typed URL).
    return switch (s.name) {
      '/onboarding' => const OnboardingScreen(),
      '/signin' => const SignInScreen(),
      '/signup' => const SignUpScreen(),
      '/forgot' => const ForgotScreen(),
      '/sections' when a is String => SectionsScreen(a),
      '/reader' when a is (String, String) => ReaderScreen(a.$1, a.$2),
      '/guidelines' || '/sections' || '/reader' => const GuidelinesScreen(),
      '/search' => SearchScreen(a is String ? a : ''),
      '/saved' => SavedScreen(a is String ? a : 'bookmarks'),
      '/profile' => const ProfileScreen(),
      '/calculator' when a is String => CalculatorScreen(a),
      '/calculators' || '/calculator' => const CalculatorsScreen(),
      '/games' => const GamesScreen(),
      '/quiz' => const QuizScreen(),
      '/wordfinder' => const WordFinderScreen(),
      '/puzzle' => const PuzzleScreen(),
      '/rankings' => const RankingsScreen(),
      _ => const HomeScreen(),
    };
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AkomaCare',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        initialRoute: !AppState.i.seenOnboarding
            ? '/onboarding'
            : AppState.i.user == null
                ? '/signin'
                : '/home',
        // A deep link (web URL / refresh) always sits on top of /home so
        // back, Home and "Back to games" never empty the stack.
        onGenerateInitialRoutes: (r) => [
          for (final name in {if (AppState.i.user != null && !_auth.contains(r)) '/home', r == '/' ? '/home' : r})
            MaterialPageRoute(settings: RouteSettings(name: name), builder: (_) => _page(RouteSettings(name: name))),
        ],
        onGenerateRoute: (s) => MaterialPageRoute(settings: s, builder: (_) => _page(s)),
      );
}
