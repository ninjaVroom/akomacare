import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

const _games = [
  ('Quiz', 'Play Quiz Game', 'assets/images/v1-game-quiz.png', '/quiz'),
  ('Word finder', 'Play Word finder Game', 'assets/images/v1-game-word-finder.png', '/wordfinder'),
  ('Sliding Puzzle', 'Play Sliding Puzzle Game', 'assets/images/v1-game-sliding-puzzle.png', '/puzzle'),
];

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.pageBgGames,
        bottomNavigationBar: Bars.games(context),
        appBar: AppBar(
          backgroundColor: C.card,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: ListenableBuilder(
            listenable: AppState.i,
            builder: (_, _) => Text(
                'Ranking: ${ordinal(AppState.i.leaderRank)}\nScore: ${AppState.i.user!.score}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ),
        body: ListenableBuilder(listenable: AppState.i, builder: (context, _) => ListView(padding: const EdgeInsets.fromLTRB(10, 16, 10, 24), children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Avatar(size: 58, asset: 'assets/images/v1-avatar-pope.png'),
              const SizedBox(width: 12),
              Text('HEY ${AppState.i.firstName.toUpperCase()}#${AppState.i.leaderRank}',
                  style: const TextStyle(color: C.goldText, fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 28),
          for (final (i, (title, sub, img, route)) in _games.indexed) ...[
            _GameCard(title: title, sub: sub, img: img, imageRight: i.isOdd, onTap: () => Navigator.pushNamed(context, route)),
            const SizedBox(height: 22),
          ],
          Center(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: C.teal,
                  minimumSize: const Size(210, 52),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: C.tealIcon, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              ),
              label: const Text("Let's have some fun"),
              onPressed: () => Navigator.pushNamed(context, _games[Random().nextInt(_games.length)].$4),
            ),
          ),
        ])),
      );
}

class _GameCard extends StatelessWidget {
  final String title, sub, img;
  final bool imageRight;
  final VoidCallback onTap;
  const _GameCard({required this.title, required this.sub, required this.img, required this.imageRight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(img, width: 84, height: 72, fit: BoxFit.contain);
    const chevron = Icon(Icons.chevron_right, color: C.goldTitle);
    final text = Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: C.goldTitle, fontSize: 17, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    );
    return Material(
      color: C.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Row(
            children: imageRight
                ? [chevron, const SizedBox(width: 24), text, image]
                : [image, const SizedBox(width: 16), text, chevron],
          ),
        ),
      ),
    );
  }
}

/// Shown when a game ends; records the points once.
Future<void> _finish(BuildContext context, String title, int points, VoidCallback again) async {
  AppState.i.addScore(points);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (c) => PopScope(
      canPop: false,
      child: AlertDialog(
      title: Text(title),
      content: Text('+$points points\nTotal score: ${AppState.i.user!.score}'),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(c);
              Navigator.pop(context);
            },
            child: const Text('Back to games')),
        FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () {
              Navigator.pop(c);
              again();
            },
            child: const Text('Play again')),
      ],
    ),
    ),
  );
}

// ----------------------------------------------------------------------- quiz

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizState();
}

class _QuizState extends State<QuizScreen> {
  static const seconds = 20;
  late List<QuizQ> qs;
  int i = 0, points = 0, left = seconds;
  int? picked;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    qs = [...quiz]..shuffle();
    i = points = 0;
    _next();
  }

  void _next() {
    picked = null;
    left = seconds;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => left--);
      if (left <= 0) answer(-1);
    });
    setState(() {});
  }

  void answer(int choice) {
    if (picked != null) return;
    timer?.cancel();
    setState(() {
      picked = choice;
      if (choice == qs[i].answer) points += 10 + left;
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      if (i == qs.length - 1) {
        _finish(context, 'Quiz complete', points, () => setState(start));
      } else {
        i++;
        _next();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = qs[i];
    return Scaffold(
      backgroundColor: C.pageBgGames,
      appBar: AppBar(backgroundColor: C.pageBgGames, title: const Text('Quiz', style: TextStyle(color: C.goldTitle))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Text('Question ${i + 1} of ${qs.length}', style: const TextStyle(color: C.muted)),
          const Spacer(),
          Icon(Icons.timer_outlined, size: 18, color: left <= 5 ? C.red : C.muted),
          const SizedBox(width: 4),
          Text('${left}s', style: TextStyle(color: left <= 5 ? C.red : C.muted, fontWeight: FontWeight.w700)),
          const SizedBox(width: 16),
          Text('$points pts', style: const TextStyle(color: C.goldText, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: left / seconds, color: C.gold, backgroundColor: C.card, minHeight: 6),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)),
          child: Text(q.q, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.35)),
        ),
        const SizedBox(height: 16),
        for (final (k, o) in q.options.indexed)
          RowCard(
            minHeight: 54,
            color: picked == null
                ? C.card
                : k == q.answer
                    ? const Color(0xFFDDF1E4)
                    : k == picked
                        ? C.rankRowMe
                        : C.card,
            onTap: picked == null ? () => answer(k) : null,
            child: Row(children: [
              Expanded(child: Text(o, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
              if (picked != null && k == q.answer) const Icon(Icons.check_circle, color: C.playGreen),
              if (picked == k && k != q.answer) const Icon(Icons.cancel, color: C.red),
            ]),
          ),
        if (picked == -1) const Text("Time's up.", style: TextStyle(color: C.red, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ---------------------------------------------------------------- word finder

typedef Cell = (int r, int c);

class WordGrid {
  static const n = 8; // 8 columns keeps cells ~40dp wide on a 360dp phone
  final List<List<String>> letters;
  final Map<String, List<Cell>> placed;
  WordGrid(this.letters, this.placed);

  /// Places each word forward horizontally, vertically or diagonally.
  factory WordGrid.generate(List<String> words, Random rnd) {
    const dirs = [(0, 1), (1, 0), (1, 1)];
    final g = List.generate(n, (_) => List.filled(n, ''));
    final placed = <String, List<Cell>>{};
    for (final w in words) {
      for (var tries = 0; tries < 500 && !placed.containsKey(w); tries++) {
        final (dr, dc) = dirs[rnd.nextInt(dirs.length)];
        final r = rnd.nextInt(n - dr * (w.length - 1)), c = rnd.nextInt(n - dc * (w.length - 1));
        final cells = [for (var k = 0; k < w.length; k++) (r + dr * k, c + dc * k)];
        if (cells.indexed.every((e) => g[e.$2.$1][e.$2.$2] == '' || g[e.$2.$1][e.$2.$2] == w[e.$1])) {
          for (final (k, (rr, cc)) in cells.indexed) {
            g[rr][cc] = w[k];
          }
          placed[w] = cells;
        }
      }
    }
    const abc = 'ABCDEFGHIJKLMNOPRSTUVWY';
    for (final row in g) {
      for (var c = 0; c < n; c++) {
        if (row[c] == '') row[c] = abc[rnd.nextInt(abc.length)];
      }
    }
    return WordGrid(g, placed);
  }

  /// The word spanned by a straight line from a to b (either direction), if any.
  String? match(Cell a, Cell b) {
    for (final e in placed.entries) {
      final cells = e.value;
      if ((cells.first == a && cells.last == b) || (cells.first == b && cells.last == a)) return e.key;
    }
    return null;
  }
}

class WordFinderScreen extends StatefulWidget {
  const WordFinderScreen({super.key});
  @override
  State<WordFinderScreen> createState() => _WordFinderState();
}

class _WordFinderState extends State<WordFinderScreen> {
  late WordGrid grid;
  final found = <String>{};
  Cell? start;

  @override
  void initState() {
    super.initState();
    reset();
  }

  void reset() {
    grid = WordGrid.generate(wordFinderWords, Random());
    found.clear();
    start = null;
  }

  void tap(Cell cell) {
    if (found.length == grid.placed.length) return; // game over, points already awarded
    if (start == null) return setState(() => start = cell);
    final w = grid.match(start!, cell);
    setState(() {
      start = null;
      if (w != null) found.add(w);
    });
    if (w == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Not a word. Tap the first letter, then the last.'), duration: Duration(seconds: 1)));
    } else if (found.length == grid.placed.length) {
      _finish(context, 'All words found!', found.length * 15, () => setState(reset));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hit = {for (final w in found) ...grid.placed[w]!};
    return Scaffold(
      backgroundColor: C.pageBgGames,
      appBar: AppBar(backgroundColor: C.pageBgGames, title: const Text('Word finder', style: TextStyle(color: C.goldTitle))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Tap the first letter of a word, then its last letter.', style: TextStyle(color: C.muted)),
        const SizedBox(height: 12),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.gold, width: 3)),
              child: GridView.count(
                crossAxisCount: WordGrid.n,
                padding: EdgeInsets.zero, // else it inherits the bottom safe-area inset
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var r = 0; r < WordGrid.n; r++)
                    for (var c = 0; c < WordGrid.n; c++)
                      Semantics(
                        button: true,
                        label: 'Row ${r + 1}, column ${c + 1}, ${grid.letters[r][c]}',
                        child: InkWell(
                          onTap: () => tap((r, c)),
                          child: Container(
                            margin: const EdgeInsets.all(1.5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: start == (r, c)
                                  ? C.gold
                                  : hit.contains((r, c))
                                      ? C.teal.withValues(alpha: .25)
                                      : null,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(grid.letters[r][c], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final w in grid.placed.keys)
            Chip(
              label: Text(w,
                  style: TextStyle(
                      decoration: found.contains(w) ? TextDecoration.lineThrough : null,
                      color: found.contains(w) ? C.muted : C.text,
                      fontWeight: FontWeight.w600)),
              backgroundColor: found.contains(w) ? C.teal.withValues(alpha: .18) : C.card,
              side: BorderSide.none,
            ),
        ]),
      ]),
    );
  }
}

// -------------------------------------------------------------- sliding puzzle

/// Board state: tiles[pos] = tile id; id n*n-1 is the blank.
class Puzzle {
  final int n;
  final List<int> tiles;
  Puzzle(this.n) : tiles = List.generate(n * n, (i) => i);

  int get blank => tiles.indexOf(n * n - 1);
  bool get solved => tiles.indexed.every((e) => e.$1 == e.$2);

  bool canMove(int pos) {
    final b = blank;
    return (pos ~/ n == b ~/ n && (pos - b).abs() == 1) || (pos % n == b % n && (pos - b).abs() == n);
  }

  bool move(int pos) {
    if (!canMove(pos)) return false;
    final b = blank;
    tiles[b] = tiles[pos];
    tiles[pos] = n * n - 1;
    return true;
  }

  /// Random legal moves from solved, so the result is always solvable.
  void shuffle(Random rnd, [int steps = 150]) {
    for (var s = 0; s < steps || solved; s++) {
      final options = [for (var p = 0; p < n * n; p++) if (canMove(p)) p];
      move(options[rnd.nextInt(options.length)]);
    }
  }
}

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});
  @override
  State<PuzzleScreen> createState() => _PuzzleState();
}

class _PuzzleState extends State<PuzzleScreen> {
  int image = 1, moves = 0;
  late Puzzle p;

  @override
  void initState() {
    super.initState();
    reset();
  }

  void reset([int? img]) {
    image = img ?? image;
    moves = 0;
    p = Puzzle(3)..shuffle(Random());
  }

  void tap(int pos) {
    if (p.solved || !p.move(pos)) return; // solved: points already awarded
    setState(() => moves++);
    if (p.solved) _finish(context, 'Puzzle solved in $moves moves', max(20, 120 - moves), () => setState(reset));
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final asset = puzzleImages[image].$2;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9CC48A), C.puzzleGreen, Color(0xFF4F7A45)]),
        ),
        child: SafeArea(
          child: Column(children: [
            Row(children: [
              const SizedBox(width: 16),
              const Text('Sliding Puzzle', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(moves == 1 ? '1 move' : '$moves moves', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              IconButton(
                tooltip: 'Close',
                icon: const CircleAvatar(backgroundColor: Colors.white, radius: 16, child: Icon(Icons.close, color: C.red, size: 18)),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            Expanded(
              child: Center(
                child: LayoutBuilder(builder: (context, box) {
                  final size = min(min(box.maxWidth - 32, box.maxHeight - 16), 480.0);
                  final tile = (size - 16) / p.n;
                  return Container(
                    width: size,
                    height: size,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4423),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF8B5A2B), width: 4),
                    ),
                    child: Stack(children: [
                      for (var pos = 0; pos < p.tiles.length; pos++)
                        if (p.tiles[pos] != p.n * p.n - 1)
                          AnimatedPositioned(
                            key: ValueKey(p.tiles[pos]),
                            duration: reduce ? Duration.zero : const Duration(milliseconds: 140),
                            left: (pos % p.n) * tile,
                            top: (pos ~/ p.n) * tile,
                            width: tile,
                            height: tile,
                            child: Semantics(
                              button: true,
                              label: 'Tile ${p.tiles[pos] + 1}',
                              child: GestureDetector(
                                onTap: () => tap(pos),
                                child: Container(
                                  margin: const EdgeInsets.all(1),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: _slice(asset, p.tiles[pos], p.n, size - 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ]),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: Row(children: [
                _arrow(Icons.chevron_left, 'Previous image', () => setState(() => reset((image + 2) % 3))),
                for (final (k, (label, a)) in puzzleImages.indexed)
                  Expanded(
                    child: Column(children: [
                      Container(
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: k == image ? C.gold : Colors.white54, width: 2),
                          borderRadius: BorderRadius.circular(6),
                          image: DecorationImage(image: AssetImage(a), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: C.playGreen, minimumSize: const Size(64, 32), shape: const StadiumBorder()),
                        onPressed: () => setState(() => reset(k)),
                        child: Text('Play', semanticsLabel: 'Play $label'),
                      ),
                    ]),
                  ),
                _arrow(Icons.chevron_right, 'Next image', () => setState(() => reset((image + 1) % 3))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  static Widget _arrow(IconData i, String tip, VoidCallback onTap) => IconButton(
        tooltip: tip,
        onPressed: onTap,
        icon: CircleAvatar(backgroundColor: C.playGreen, child: Icon(i, color: Colors.white)),
      );

  /// The [id]th of n×n slices of the image.
  static Widget _slice(String asset, int id, int n, double board) {
    final r = id ~/ n, c = id % n;
    return OverflowBox(
      maxWidth: board,
      maxHeight: board,
      alignment: Alignment(n == 1 ? 0 : -1 + 2 * c / (n - 1), n == 1 ? 0 : -1 + 2 * r / (n - 1)),
      child: Image.asset(asset, width: board, height: board, fit: BoxFit.cover),
    );
  }
}

// -------------------------------------------------------------------- ranking

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});
  @override
  State<RankingsScreen> createState() => _RankingsState();
}

class _RankingsState extends State<RankingsScreen> {
  String board = boards.keys.first;

  @override
  Widget build(BuildContext context) {
    final rows = AppState.i.board(board);
    final me = rows.indexWhere((r) => r.$3);
    final top = rows.take(3).toList();
    return Scaffold(
      backgroundColor: C.pageBgRankings,
      bottomNavigationBar: BottomBar(
        fabIcon: Icons.leaderboard_outlined,
        fabLabel: 'Rankings',
        fabColor: C.gold,
        fabCenter: true,
        onFab: () {},
        tabs: [
          (Icons.sports_esports_outlined, 'Games', () => Navigator.pushNamed(context, '/games')),
          (Icons.person_outline, 'Profile', () => Navigator.pushNamed(context, '/profile')),
        ],
      ),
      appBar: AppBar(
        backgroundColor: C.card,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Rankings', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'About the boards',
            icon: const Icon(Icons.info_outline, color: C.rankB),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(
                title: Text('Boards'),
                content: Text('Leader board: total points.\nMaster board: games completed.\n'
                    'Loyalty board: days you opened the app.\n\nOther players are demo data.'),
              ),
            ),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(10, 16, 10, 16), children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: C.rankTabBar, borderRadius: BorderRadius.circular(999)),
          child: Row(children: [
            for (final b in boards.keys)
              Expanded(
                child: Semantics(
                  selected: b == board,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() => board = b),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: b == board ? C.card : null, borderRadius: BorderRadius.circular(999)),
                      child: Text(b, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
          decoration: BoxDecoration(color: C.podiumCard, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (top.length > 1) Expanded(child: _Podium(top[1], 'assets/images/v1-podium-2nd.png', 64)),
              Expanded(child: _Podium(top[0], 'assets/images/v1-podium-1st.png', 96)),
              if (top.length > 2) Expanded(child: _Podium(top[2], 'assets/images/v1-podium-3rd.png', 64)),
            ]),
            const SizedBox(height: 20),
            _RankRow(me + 1, rows[me], me: true),
            for (final (k, r) in rows.indexed)
              if (k >= 3 && !r.$3) _RankRow(k + 1, r),
          ]),
        ),
      ]),
    );
  }
}

class _Podium extends StatelessWidget {
  final (String, int, bool) row;
  final String img;
  final double size;
  const _Podium(this.row, this.img, this.size);

  @override
  Widget build(BuildContext context) => Column(children: [
        Image.asset(img, height: size * 1.15, semanticLabel: row.$1),
        const SizedBox(height: 6),
        Text(row.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        _Pill('${row.$2}'),
      ]);
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(gradient: C.scorePill, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
}

class _RankRow extends StatelessWidget {
  final int rank;
  final (String, int, bool) row;
  final bool me;
  const _RankRow(this.rank, this.row, {this.me = false});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: me ? C.rankRowMe : C.rankRow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: me ? C.rankA : C.rankRowMe),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(gradient: C.rankBadge, borderRadius: BorderRadius.circular(8)),
            child: Text(ordinal(rank), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(row.$1, style: const TextStyle(fontWeight: FontWeight.w600))),
          _Pill('${row.$2}'),
        ]),
      );
}
