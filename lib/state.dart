import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

class Profile {
  String name, email, facility;
  int score, games;
  Set<String> days; // yyyy-mm-dd the user opened the app
  Set<String> bookmarks; // "guidelineId/sectionId"
  Map<String, String> notes; // same key -> note text
  String? lastRead;

  Profile(this.name, this.email, this.facility,
      {this.score = 0, this.games = 0, Set<String>? days, Set<String>? bookmarks, Map<String, String>? notes, this.lastRead})
      : days = days ?? {},
        bookmarks = bookmarks ?? {},
        notes = notes ?? {};

  Map<String, dynamic> toJson() => {
        'name': name, 'email': email, 'facility': facility, 'score': score, 'games': games,
        'days': days.toList(), 'bookmarks': bookmarks.toList(), 'notes': notes, 'lastRead': lastRead,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(j['name'], j['email'], j['facility'] ?? '',
      score: j['score'] ?? 0,
      games: j['games'] ?? 0,
      days: {...(j['days'] as List? ?? []).cast<String>()},
      bookmarks: {...(j['bookmarks'] as List? ?? []).cast<String>()},
      notes: Map<String, String>.from(j['notes'] ?? {}),
      lastRead: j['lastRead']);
}

/// Mock auth + on-device persistence. No backend.
// whole state saved as one JSON blob per change; fine for a handful of profiles.
class AppState extends ChangeNotifier {
  AppState._();
  static final i = AppState._();

  late SharedPreferences _p;
  bool seenOnboarding = false;
  double fontScale = 1;
  final Map<String, Profile> accounts = {};
  String? _email;

  Profile? get user => _email == null ? null : accounts[_email];
  String get firstName {
    final parts = (user?.name ?? 'there').split(' ').where((w) => !w.endsWith('.')).toList();
    return parts.isEmpty ? 'there' : parts.first;
  }

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p.getString('state');
    if (raw != null) {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      seenOnboarding = j['seenOnboarding'] ?? false;
      fontScale = (j['fontScale'] ?? 1).toDouble();
      for (final a in (j['accounts'] as Map<String, dynamic>).values) {
        final p = Profile.fromJson(a);
        accounts[p.email] = p;
      }
      _email = j['email'];
    }
    accounts.putIfAbsent(
        demoEmail,
        () => Profile(demoName, demoEmail, 'Senior Nursing Officer, Korle-Bu Teaching Hospital',
            score: 1090, games: 26, days: {for (var d = 1; d <= 18; d++) 'seed-$d'}));
    _touchDay();
    _save(); // persist today's visit for the loyalty board
  }

  void _save({bool notify = true}) {
    _p.setString(
        'state',
        jsonEncode({
          'seenOnboarding': seenOnboarding,
          'fontScale': fontScale,
          'email': _email,
          'accounts': {for (final e in accounts.entries) e.key: e.value.toJson()},
        }));
    if (notify) notifyListeners();
  }

  void _touchDay() {
    final d = DateTime.now().toIso8601String().substring(0, 10);
    user?.days.add(d);
  }

  void finishOnboarding() {
    seenOnboarding = true;
    _save();
  }

  /// Returns an error message, or null on success.
  String? signIn(String email, String password) {
    final e = email.trim().toLowerCase();
    if (!accounts.containsKey(e)) return 'No account for that email. Sign up first.';
    if (e == demoEmail ? password != demoPassword : password.length < 6) return 'Incorrect password.';
    _email = e;
    _touchDay();
    _save();
    return null;
  }

  String? signUp(String name, String email, String facility, String password) {
    final e = email.trim().toLowerCase();
    if (accounts.containsKey(e)) return 'An account with that email already exists.';
    accounts[e] = Profile(name.trim(), e, facility.trim());
    return signIn(e, password);
  }

  bool hasAccount(String email) => accounts.containsKey(email.trim().toLowerCase());

  /// Callers navigate to /signin right after. Not notifying avoids open
  /// screens rebuilding once with no user before they're removed.
  void signOut() {
    _email = null;
    _save(notify: false);
  }

  void setFontScale(double v) {
    fontScale = v;
    _save();
  }

  bool isBookmarked(String key) => user?.bookmarks.contains(key) ?? false;

  void toggleBookmark(String key) {
    final b = user!.bookmarks;
    b.contains(key) ? b.remove(key) : b.add(key);
    _save();
  }

  void setNote(String key, String text) {
    text.trim().isEmpty ? user!.notes.remove(key) : user!.notes[key] = text.trim();
    _save();
  }

  void markRead(String key) {
    user!.lastRead = key;
    _save();
  }

  void addScore(int points) {
    user!
      ..score += points
      ..games += 1;
    _save();
  }

  /// Board rows sorted descending, with the signed-in user merged in.
  List<(String, int, bool)> board(String name) {
    final u = user!;
    final mine = switch (name) { 'LEADER BOARD' => u.score, 'MASTER BOARD' => u.games, _ => u.days.length };
    final rows = [
      for (final (n, s) in boards[name]!) (n, s, false),
      (u.name, mine, true),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return rows;
  }

  int get leaderRank => board('LEADER BOARD').indexWhere((r) => r.$3) + 1;
}

String ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  return '$n${switch (n % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' }}';
}
