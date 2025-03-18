import 'dart:math';

import 'package:flutter/material.dart';

import '../data.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: const AppDrawer(),
        bottomNavigationBar: Bars.home(),
        body: ListView(padding: EdgeInsets.zero, children: [
          const WaveHeader(bottom: SearchPill(hint: 'Search Heart Failure')),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(children: [
              for (final (label, ill, route) in [
                ('Read Guidelines', 'v1-ill-guidelines-book', '/guidelines'),
                ('Health Assessors', 'v1-ill-calculator', '/calculators'),
                ('Brain Teasers', 'v1-ill-brain', '/games'),
              ]) ...[
                FeatureBanner(
                  label: label,
                  background: 'assets/images/v1-banner-heart-dark.png',
                  illustration: 'assets/images/$ill.png',
                  onTap: () => Navigator.pushNamed(context, route),
                ),
                const SizedBox(height: 28),
              ],
            ]),
          ),
        ]),
      );
}

class GuidelinesScreen extends StatelessWidget {
  const GuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      bottomNavigationBar: Bars.guidelines(context),
      floatingActionButton: const ContactFab(),
      body: ListenableBuilder(
        listenable: AppState.i,
        builder: (context, _) {
          final last = AppState.i.user?.lastRead;
          final parts = last != null && resolve(last) != null ? last.split('/') : null;
          return ListView(padding: EdgeInsets.zero, children: [
            const WaveHeader(back: true, bottom: SearchPill(hint: 'Search chest pain')),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const TwoTone('Continue', 'reading'),
                const SizedBox(height: 12),
                FeatureBanner(
                  label: parts == null ? 'Start Reading' : 'Continue: ${_sectionTitle(parts)}',
                  background: 'assets/images/v1-banner-heart-warm.png',
                  labelAlign: Alignment.centerLeft,
                  height: 90,
                  onTap: () => parts == null
                      ? Navigator.pushNamed(context, '/sections', arguments: guidelines.first.id)
                      : Navigator.pushNamed(context, '/reader', arguments: (parts[0], parts[1])),
                ),
                const SizedBox(height: 28),
                const Text('Chapters', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.textBrown)),
                const SizedBox(height: 12),
                for (final g in guidelines)
                  RowCard(
                    onTap: () => Navigator.pushNamed(context, '/sections', arguments: g.id),
                    child: Row(children: [
                      Expanded(child: Text(g.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                      const SizedBox(width: 12),
                      const ReadPill(),
                    ]),
                  ),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  static String _sectionTitle(List<String> p) {
    final g = guideline(p[0]);
    return '${g.title.split(',').first} · ${g.sections.firstWhere((s) => s.id == p[1]).title}';
  }
}

class SectionsScreen extends StatelessWidget {
  final String id;
  const SectionsScreen(this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    final g = guideline(id);
    return Scaffold(
      appBar: _ReaderBar(g.title.split(',').first),
      bottomNavigationBar: Bars.guidelines(context),
      body: ListenableBuilder(
        listenable: AppState.i,
        builder: (context, _) => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 150,
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(g.hero, fit: BoxFit.cover),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(g.title.split(',').first,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            shadows: [Shadow(blurRadius: 8, color: Colors.black54)])),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          for (final s in g.sections)
            Builder(builder: (context) {
              final key = '${g.id}/${s.id}';
              final top = topLevelSections.contains(s.id);
              return RowCard(
                onTap: () => Navigator.pushNamed(context, '/reader', arguments: (g.id, s.id)),
                child: Row(children: [
                  Expanded(
                    child: Text(top ? s.title.toUpperCase() : s.title,
                        style: TextStyle(fontSize: top ? 12 : 15, fontWeight: top ? FontWeight.w800 : FontWeight.w600)),
                  ),
                  if (!top)
                    IconButton(
                      tooltip: AppState.i.isBookmarked(key) ? 'Remove bookmark' : 'Bookmark',
                      icon: Icon(AppState.i.isBookmarked(key) ? Icons.bookmark : Icons.bookmark_border,
                          color: C.text, size: 22),
                      onPressed: () => AppState.i.toggleBookmark(key),
                    ),
                  const ReadPill(),
                ]),
              );
            }),
        ]),
      ),
    );
  }
}

/// White app bar with back, title, search and the AA font-size toggle.
class _ReaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _ReaderBar(this.title);

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => AppBar(
        toolbarHeight: 64,
        backgroundColor: C.pageBg,
        surfaceTintColor: Colors.transparent,
        title: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.pushNamed(context, '/search', arguments: '')),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: 'Text size',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  const steps = [1.0, 1.15, 1.3, 0.9];
                  final s = AppState.i.fontScale;
                  AppState.i.setFontScale(steps[(steps.indexOf(s) + 1) % steps.length]);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.muted)),
                  child: const Text('AA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      );
}

class ReaderScreen extends StatefulWidget {
  final String gid, sid;
  const ReaderScreen(this.gid, this.sid, {super.key});
  @override
  State<ReaderScreen> createState() => _ReaderState();
}

class _ReaderState extends State<ReaderScreen> {
  late Guideline g = guideline(widget.gid);
  late int index = max(0, g.sections.indexWhere((s) => s.id == widget.sid));

  Section get s => g.sections[index];
  String get key => '${g.id}/${s.id}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => AppState.i.markRead(key));
  }

  void go(int d) {
    setState(() => index += d);
    AppState.i.markRead(key);
  }

  Future<void> editNote() async {
    final c = TextEditingController(text: AppState.i.user!.notes[key]);
    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Note · ${s.title}'),
        content: TextField(
          controller: c,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Write a note for this section', fillColor: C.pageBg),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
              onPressed: () => Navigator.pop(context, c.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (text != null) AppState.i.setNote(key, text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _ReaderBar(g.title.split(',').first),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'note',
        tooltip: 'Add note',
        backgroundColor: C.card,
        foregroundColor: C.red,
        onPressed: editNote,
        child: const Icon(Icons.sticky_note_2_outlined),
      ),
      bottomNavigationBar: SafeArea(
        child: Row(children: [
          IconButton(
              tooltip: 'Previous section',
              icon: const Icon(Icons.chevron_left, color: C.red, size: 32),
              onPressed: index > 0 ? () => go(-1) : null),
          const Spacer(),
          Text('${index + 1} / ${g.sections.length}', style: const TextStyle(color: C.muted)),
          const Spacer(),
          IconButton(
              tooltip: 'Next section',
              icon: const Icon(Icons.chevron_right, color: C.red, size: 32),
              onPressed: index < g.sections.length - 1 ? () => go(1) : null),
        ]),
      ),
      body: ListenableBuilder(
        listenable: AppState.i,
        builder: (context, _) {
          final note = AppState.i.user?.notes[key];
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(MediaQuery.textScalerOf(context).scale(AppState.i.fontScale))),
            child: ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 88), children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Expanded(child: Text(s.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                  IconButton(
                    tooltip: AppState.i.isBookmarked(key) ? 'Remove bookmark' : 'Bookmark',
                    icon: Icon(AppState.i.isBookmarked(key) ? Icons.bookmark : Icons.bookmark_border),
                    onPressed: () => AppState.i.toggleBookmark(key),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (note != null) _NoteCard(note, onTap: editNote),
                  if (s.blocks.isEmpty)
                    const Text(
                      'This section\'s guideline text isn\'t included in this build. It loads from the '
                      'National Guidelines for the Management of Cardiovascular Diseases in production. '
                      'Open Stroke › Referral for a complete sample section.',
                      style: TextStyle(color: C.muted, height: 1.5),
                    ),
                  for (final b in s.blocks) Padding(padding: const EdgeInsets.only(bottom: 12), child: _block(b)),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _block(Block b) => switch (b) {
        Para(:final text) => Text(text, style: const TextStyle(fontSize: 15, height: 1.5)),
        Callout(:final text) => Text('→ $text',
            style: const TextStyle(fontSize: 15, height: 1.45, color: C.red, fontWeight: FontWeight.w700)),
        Heading(:final text) => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        Caption(:final text) => Text(text, style: const TextStyle(fontSize: 12, color: C.muted, fontStyle: FontStyle.italic)),
        StrokeFlowchart() => const _Flowchart(),
        TableBlock() => _Table(b),
      };
}

class _NoteCard extends StatelessWidget {
  final String note;
  final VoidCallback onTap;
  const _NoteCard(this.note, {required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: C.readPillHalo,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.sticky_note_2_outlined, color: C.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(note)),
              ]),
            ),
          ),
        ),
      );
}

/// Figure 13: stroke unit referral protocol, as native boxes and connectors.
class _Flowchart extends StatelessWidget {
  const _Flowchart();

  @override
  Widget build(BuildContext context) {
    Widget box(String t, {Color fill = C.card}) => Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: fill, border: Border.all(color: C.text), borderRadius: BorderRadius.circular(4)),
          child: Text(t, style: const TextStyle(fontSize: 12.5, height: 1.35)),
        );
    Widget down() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward, size: 18, color: C.text));
    return Column(children: [
      box('Initiate management and call/consult stroke team', fill: C.oliveLight),
      down(),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: box('Previous stroke with other medical conditions')),
          const SizedBox(width: 10),
          Expanded(
              child: box('Review by stroke team\nAdmission criteria:\n• ROSIER > 0 (Table 40)\n• ABCD² > 6 (TIA)\n'
                  '• Head CT confirmed\n• 1st & 2nd strokes')),
        ]),
      ),
      Row(children: [Expanded(child: Center(child: down())), const SizedBox(width: 10), Expanded(child: Center(child: down()))]),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: box('Admit to general ward with stroke team')),
          const SizedBox(width: 10),
          Expanded(
              child: box('Admit to stroke unit\nMDT & pre-discharge:\n• Nursing • Physio\n• Speech + language\n'
                  '• Dietician • Medical')),
        ]),
      ),
    ]);
  }
}

class _Table extends StatelessWidget {
  final TableBlock t;
  const _Table(this.t);

  @override
  Widget build(BuildContext context) {
    Widget cell(String s, {bool bold = false, TextAlign align = TextAlign.left}) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text(s, textAlign: align, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : null)),
        );
    return Container(
      decoration: BoxDecoration(border: Border.all(color: C.olive)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(color: C.olive, child: cell(t.title, bold: true)),
        Container(color: C.oliveLight, child: cell(t.subtitle, bold: true)),
        cell(t.intro),
        Table(
          columnWidths: const {0: FlexColumnWidth(), 1: FixedColumnWidth(52), 2: FixedColumnWidth(52)},
          border: const TableBorder(horizontalInside: BorderSide(color: C.oliveLight)),
          children: [
            TableRow(
                decoration: const BoxDecoration(color: C.oliveLight),
                children: [for (final (i, h) in t.header.indexed) cell(h, bold: true, align: i == 0 ? TextAlign.left : TextAlign.center)]),
            for (final r in t.rows)
              TableRow(children: [for (final (i, c) in r.indexed) cell(c, align: i == 0 ? TextAlign.left : TextAlign.center)]),
          ],
        ),
        Container(color: C.oliveLight, child: cell(t.footer, bold: true)),
      ]),
    );
  }
}

class SearchScreen extends StatefulWidget {
  final String query;
  const SearchScreen(this.query, {super.key});
  @override
  State<SearchScreen> createState() => _SearchState();
}

class _SearchState extends State<SearchScreen> {
  late String q = widget.query;

  @override
  Widget build(BuildContext context) {
    final terms = q.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    bool hit(String hay) => terms.every(hay.toLowerCase().contains);
    final results = [
      for (final g in guidelines)
        for (final s in g.sections)
          if (terms.isNotEmpty &&
              hit('${g.title} ${s.title} ${s.blocks.map((b) => switch (b) {
                    Para(:final text) || Callout(:final text) || Heading(:final text) || Caption(:final text) => text,
                    _ => '',
                  }).join(' ')}'))
            (g, s),
      for (final c in calculators)
        if (terms.isNotEmpty && hit('${c.title} ${c.subtitle}')) c,
    ];
    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        WaveHeader(
            back: true,
            bottom: SearchPill(
                hint: 'Search guidelines',
                initial: widget.query,
                autofocus: widget.query.isEmpty,
                onChanged: (v) => setState(() => q = v),
                onSubmitted: (v) => setState(() => q = v))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(terms.isEmpty ? 'Type to search guidelines and assessors' : '${results.length} results',
                style: const TextStyle(color: C.muted)),
            const SizedBox(height: 12),
            for (final r in results)
              switch (r) {
                (Guideline g, Section s) => RowCard(
                    onTap: () => Navigator.pushNamed(context, '/reader', arguments: (g.id, s.id)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(g.title, style: const TextStyle(color: C.muted, fontSize: 12)),
                        ]),
                      ),
                      const ReadPill(),
                    ])),
                Calculator c => RowCard(
                    onTap: () => Navigator.pushNamed(context, '/calculator', arguments: c.id),
                    child: Row(children: [
                      Expanded(child: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                      const Icon(Icons.chevron_right, color: C.muted),
                    ])),
                _ => const SizedBox(),
              },
          ]),
        ),
      ]),
    );
  }
}

/// Bookmarks and notes ("Highlights"). [tab] is 'bookmarks' or 'notes'.
class SavedScreen extends StatefulWidget {
  final String tab;
  const SavedScreen(this.tab, {super.key});
  @override
  State<SavedScreen> createState() => _SavedState();
}

class _SavedState extends State<SavedScreen> {
  String filter = '';

  @override
  Widget build(BuildContext context) {
    final notes = widget.tab == 'notes';
    return Scaffold(
      bottomNavigationBar: Bars.guidelines(context),
      body: ListenableBuilder(
        listenable: AppState.i,
        builder: (context, _) {
          final u = AppState.i.user!;
          final keys = (notes ? u.notes.keys : u.bookmarks).toList();
          final items = [
            for (final k in keys)
              if (resolve(k) case (final g, final s)
                  when '${g.title} ${s.title} ${u.notes[k] ?? ''}'.toLowerCase().contains(filter.toLowerCase()))
                (k, g, s),
          ];
          return ListView(padding: EdgeInsets.zero, children: [
            WaveHeader(
                back: true,
                bottom: SearchPill(
                    hint: notes ? 'Search notes' : 'Search saved bookmarks',
                    onChanged: (v) => setState(() => filter = v),
                    onSubmitted: (v) => setState(() => filter = v))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(notes ? 'Highlights & Notes' : 'Saved Bookmarks',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.textBrown)),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      notes
                          ? 'No notes yet. In the reader, tap the note button to write one.'
                          : 'No bookmarks yet. Tap the bookmark icon on any section to save it here.',
                      style: const TextStyle(color: C.muted),
                    ),
                  ),
                for (final (k, g, s) in items)
                  RowCard(
                    onTap: () => Navigator.pushNamed(context, '/reader', arguments: (g.id, s.id)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${g.title.split(',').first} · ${s.title}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          if (notes)
                            Text(u.notes[k]!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      const ReadPill(),
                    ]),
                  ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AppState.i,
        builder: (context, _) => AppState.i.user == null ? const Scaffold() : _build(context, AppState.i.user!),
      );

  Widget _build(BuildContext context, Profile u) {
    Widget link(IconData i, String t, VoidCallback onTap) => RowCard(
        minHeight: 52,
        onTap: onTap,
        child: Row(children: [
          Icon(i, color: C.red, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600))),
          const Icon(Icons.chevron_right, color: C.muted),
        ]));
    return Scaffold(
      drawer: const AppDrawer(),
      bottomNavigationBar: Bars.home(),
      body: ListView(padding: EdgeInsets.zero, children: [
        const WaveHeader(back: true, bottom: TabChip('AkomaCare Clinician Profile')),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Avatar(size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      if (u.facility.isNotEmpty) Text(u.facility, style: const TextStyle(color: C.muted)),
                      Text(u.email, style: const TextStyle(color: C.muted, fontSize: 12)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),
                Text('Gamer Ranking: ${ordinal(AppState.i.leaderRank)}   Score: ${u.score} pts',
                    style: const TextStyle(color: C.goldText, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 16),
            link(Icons.bookmark_border, 'Saved Bookmarks', () => Navigator.pushNamed(context, '/saved')),
            link(Icons.sticky_note_2_outlined, 'Highlights & Notes',
                () => Navigator.pushNamed(context, '/saved', arguments: 'notes')),
            link(Icons.leaderboard_outlined, 'Gamer Rankings & Leaderboard', () => Navigator.pushNamed(context, '/rankings')),
            link(Icons.privacy_tip_outlined, 'Privacy policy',
                () => openUrl(context, 'https://admin.akomacare.org/privacy-policy')),
            link(Icons.logout, 'Sign out', () {
              AppState.i.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
            }),
          ]),
        ),
      ]),
    );
  }
}
