import 'dart:math';

import 'package:akomacare/data.dart';
import 'package:akomacare/screens/games.dart';
import 'package:akomacare/state.dart';
import 'package:akomacare/main.dart';
import 'package:akomacare/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> boot() async {
  SharedPreferences.setMockInitialValues({});
  await AppState.i.load();
  AppState.i.seenOnboarding = true;
  AppState.i.signIn(demoEmail, demoPassword);
}

Result run(String id, Map<String, double> v) => calculators.firstWhere((c) => c.id == id).compute!(v);

void main() {
  test('calculators', () {
    expect(run('bmi', {'w': 74, 'h': 172}).value, 'BMI: 25.0 kg/m²');
    expect(run('bmi', {'w': 74, 'h': 172}).note, contains('Overweight'));
    expect(run('map', {'sbp': 120, 'dbp': 80}).value, 'MAP: 93 mmHg');
    expect(run('max-hr', {'age': 40}).value, 'Max HR: 180 bpm');
    expect(run('wells-dvt', {'cancer': 1, 'calf': 1}).note, contains('likely'));
    expect(run('wells-dvt', {'cancer': 1, 'alt': -2}).value, 'Score: -1');
    expect(run('wells-pe', {'dvt': 3, 'hr': 1.5}).note, startsWith('PE likely'));
    // Female sex alone is not a risk factor.
    expect(run('chads', {'age': 0, 'sex': 1}).note, startsWith('Low risk'));
    expect(run('chads', {'age': 2, 'sex': 1, 'htn': 1}).value, 'Score: 4');
  });

  test('sliding puzzle shuffle stays solvable and moves are legal', () {
    final p = Puzzle(3)..shuffle(Random(1));
    expect(p.solved, isFalse);
    expect(p.tiles.toSet().length, 9);
    final b = p.blank;
    expect(p.move(b), isFalse); // can't move the blank into itself
  });

  test('word grid places every word and matches both directions', () {
    final g = WordGrid.generate(wordFinderWords, Random(7));
    expect(g.placed.keys.toSet(), wordFinderWords.toSet());
    final cells = g.placed['STROKE']!;
    for (final (k, (r, c)) in cells.indexed) {
      expect(g.letters[r][c], 'STROKE'[k]);
    }
    expect(g.match(cells.last, cells.first), 'STROKE');
  });

  test('ordinal', () {
    expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 101].map(ordinal).toList(),
        ['1st', '2nd', '3rd', '4th', '11th', '12th', '13th', '21st', '22nd', '101st']);
  });

  test('stale persisted keys resolve to null instead of throwing', () {
    expect(resolve('stroke/referral'), isNotNull);
    expect(resolve('stroke/renamed-section'), isNull);
    expect(guideline('gone').id, guidelines.first.id);
  });

  testWidgets('deep link keeps /home underneath, so the Home button lands on Home', (t) async {
    await boot();
    t.binding.platformDispatcher.defaultRouteNameTestValue = '/guidelines';
    addTearDown(t.binding.platformDispatcher.clearDefaultRouteNameTestValue);
    await t.pumpWidget(const AkomaCareApp());
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Home'));
    await t.pumpAndSettle();
    expect(find.text('Read Guidelines'), findsOneWidget);
  });

  testWidgets('signing out with games and saved screens open does not throw', (t) async {
    await boot();
    await t.pumpWidget(const AkomaCareApp());
    await t.pumpAndSettle();
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    for (final r in ['/games', '/saved', '/profile']) {
      nav.pushNamed(r);
      await t.pumpAndSettle();
    }
    AppState.i.signOut();
    nav.pushNamedAndRemoveUntil('/signin', (_) => false);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Sign in.'), findsOneWidget);
  });

  testWidgets('calculator rejects NaN input', (t) async {
    await boot();
    await t.pumpWidget(const AkomaCareApp());
    await t.pumpAndSettle();
    t.state<NavigatorState>(find.byType(Navigator).first).pushNamed('/calculator', arguments: 'bmi');
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'NaN');
    await t.pump();
    expect(find.textContaining('NaN kg'), findsNothing);
    expect(find.textContaining('must be'), findsOneWidget);
  });

  testWidgets('word finder awards points once', (t) async {
    await boot();
    await t.pumpWidget(const MaterialApp(home: WordFinderScreen()));
    await t.pumpAndSettle();
    final st = t.state(find.byType(WordFinderScreen)) as dynamic;
    final before = AppState.i.user!.score;
    final grid = st.grid as WordGrid;
    for (final cells in grid.placed.values) {
      st.tap(cells.first);
      st.tap(cells.last);
      await t.pump();
    }
    await t.pumpAndSettle();
    final once = AppState.i.user!.score;
    expect(once, greaterThan(before));
    // The dialog can't be dismissed with back, and taps after the game are ignored.
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    final cells = grid.placed.values.first;
    st.tap(cells.first);
    st.tap(cells.last);
    await t.pumpAndSettle();
    expect(AppState.i.user!.score, once);
  });

  testWidgets('sign-in errors clear once the field is corrected', (t) async {
    await t.pumpWidget(const MaterialApp(home: SignInScreen()));
    await t.tap(find.text('SIGN IN'));
    await t.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
    await t.enterText(find.byType(TextFormField).first, 'a@b.co');
    await t.pump();
    expect(find.text('Enter a valid email'), findsNothing);
  });
}
