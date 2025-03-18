import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'state.dart';
import 'theme.dart';

const site = 'https://akomacare.org';

Future<void> openUrl(BuildContext context, String url) async {
  if (!await launchUrl(Uri.parse(url)) && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}

/// Red wireframe-wave header with greeting, avatar and a bottom slot
/// (search pill or tab chip). Spec: DESIGN-2023 §4.1.
class WaveHeader extends StatelessWidget {
  final bool back;
  final Widget bottom;
  const WaveHeader({super.key, this.back = false, required this.bottom});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(
        color: C.headerRed,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        image: DecorationImage(image: AssetImage('assets/images/v1-header-wave.png'), fit: BoxFit.cover),
      ),
      padding: EdgeInsets.fromLTRB(8, top + 8, 16, 14),
      child: Column(children: [
        Row(children: [
          back
              ? IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.maybePop(context))
              : IconButton(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer()),
          Expanded(
            child: ListenableBuilder(
              listenable: AppState.i,
              builder: (_, _) => Text('Hi, ${AppState.i.firstName}',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500)),
            ),
          ),
          const Avatar(),
        ]),
        const SizedBox(height: 10),
        Padding(padding: const EdgeInsets.only(left: 8), child: bottom),
      ]),
    );
  }
}

class Avatar extends StatelessWidget {
  final double size;
  final String asset;
  const Avatar({super.key, this.size = 46, this.asset = 'assets/images/v1-avatar-john.png'});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Profile',
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
            ),
          ),
        ),
      );
}

class SearchPill extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? initial;
  final bool autofocus;
  const SearchPill(
      {super.key, required this.hint, this.onSubmitted, this.onChanged, this.initial, this.autofocus = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: TextFormField(
          initialValue: initial,
          autofocus: autofocus,
          onFieldSubmitted: onSubmitted ?? (q) => Navigator.pushNamed(context, '/search', arguments: q),
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: slab(14, C.muted),
            prefixIcon: const Icon(Icons.search, color: C.muted),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: C.redDark)),
          ),
        ),
      );
}

/// Calculators variant of the header slot: white chip with pink label + heart-hand.
class TabChip extends StatelessWidget {
  final String label;
  const TabChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(999)),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: C.calcTab, fontWeight: FontWeight.w700, fontSize: 15))),
          Image.asset('assets/images/logo.png', height: 22),
        ]),
      );
}

/// Red circular "read" pill (glasses) inside a pale-pink halo.
class ReadPill extends StatelessWidget {
  const ReadPill({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: C.readPillHalo, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: C.red, shape: BoxShape.circle),
          child: CustomPaint(painter: _Glasses()),
        ),
      );
}

class _Glasses extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final c = s.center(Offset.zero);
    canvas.drawCircle(c.translate(-4.5, 0), 3.6, p);
    canvas.drawCircle(c.translate(4.5, 0), 3.6, p);
    canvas.drawLine(c.translate(-1, 0), c.translate(1, 0), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// White rounded row card.
class RowCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minHeight;
  final Color color;
  const RowCard({super.key, required this.child, this.onTap, this.minHeight = 60, this.color = C.card});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), child: child),
            ),
          ),
        ),
      );
}

/// Dark banner tile with an illustration overflowing the top-left and a
/// darker underlay card peeking out beneath (stacked-deck look).
class FeatureBanner extends StatelessWidget {
  final String label;
  final String background;
  final String? illustration;
  final VoidCallback onTap;
  final Alignment labelAlign;
  final double height;
  const FeatureBanner({
    super.key,
    required this.label,
    required this.background,
    required this.onTap,
    this.illustration,
    this.labelAlign = Alignment.bottomRight,
    this.height = 84,
  });

  @override
  Widget build(BuildContext context) {
    final overflow = illustration == null ? 0.0 : 48.0;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: height + overflow + 10,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: 10,
            right: 10,
            bottom: 0,
            height: height,
            child: DecoratedBox(
                decoration: BoxDecoration(color: C.bannerShadow, borderRadius: BorderRadius.circular(6))),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: overflow,
            height: height,
            child: Material(
              color: C.bannerDark,
              borderRadius: BorderRadius.circular(6),
              clipBehavior: Clip.antiAlias,
              child: Ink.image(
                image: AssetImage(background),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: onTap,
                  child: Align(
                    alignment: labelAlign,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              shadows: [Shadow(blurRadius: 8, color: Colors.black54)])),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (illustration != null)
            Positioned(
              left: 18,
              top: 0,
              height: overflow + height * .78,
              child: IgnorePointer(child: Image.asset(illustration!, fit: BoxFit.contain)),
            ),
        ]),
      ),
    );
  }
}

typedef NavTab = (IconData icon, String label, VoidCallback onTap);

/// Blush bottom bar with a FAB sitting half above it.
class BottomBar extends StatelessWidget {
  final IconData fabIcon;
  final String fabLabel;
  final Color fabColor;
  final VoidCallback onFab;
  final bool fabCenter;
  final List<NavTab> tabs;
  const BottomBar({
    super.key,
    required this.fabIcon,
    required this.fabLabel,
    required this.onFab,
    required this.tabs,
    this.fabColor = C.red,
    this.fabCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget tab(NavTab t) => Expanded(
          child: InkResponse(
            onTap: t.$3,
            radius: 32,
            child: SizedBox(
              height: 56,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(t.$1, size: 20, color: fabColor == C.gold ? C.goldText : C.text),
                const SizedBox(height: 2),
                Text(t.$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        );
    const fabSlot = Expanded(child: SizedBox());
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: SizedBox(
        height: 84,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            top: 24,
            child: Container(
              decoration: BoxDecoration(
                  color: C.bottomNavBg, borderRadius: BorderRadius.circular(14), boxShadow: C.shadow),
              child: Row(children: fabCenter ? [tab(tabs[0]), fabSlot, tab(tabs[1])] : [fabSlot, ...tabs.map(tab)]),
            ),
          ),
          Align(
            alignment: fabCenter ? Alignment.topCenter : const Alignment(-0.8, -1),
            child: Tooltip(
              message: fabLabel,
              child: Material(
                color: fabColor,
                shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 3)),
                elevation: 3,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onFab,
                  child: SizedBox(width: 56, height: 56, child: Icon(fabIcon, color: Colors.white)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Bottom bars shared across sections (DESIGN-2023 §4.7).
class Bars {
  static Widget home() => Builder(
        builder: (c) => BottomBar(
          fabIcon: Icons.grid_view_rounded,
          fabLabel: 'Menu',
          onFab: () => Scaffold.of(c).openDrawer(),
          tabs: [
            (Icons.person_outline, 'Profile', () => Navigator.pushNamed(c, '/profile')),
            (Icons.language, 'Website', () => openUrl(c, site)),
          ],
        ),
      );

  static Widget guidelines(BuildContext c) => BottomBar(
        fabIcon: Icons.home_outlined,
        fabLabel: 'Home',
        onFab: () => Navigator.popUntil(c, ModalRoute.withName('/home')),
        tabs: [
          (Icons.edit_outlined, 'Highlights', () => Navigator.pushNamed(c, '/saved', arguments: 'notes')),
          (Icons.bookmark_border, 'Bookmarks', () => Navigator.pushNamed(c, '/saved', arguments: 'bookmarks')),
        ],
      );

  static Widget games(BuildContext c) => BottomBar(
        fabIcon: Icons.sports_esports_outlined,
        fabLabel: 'Games',
        fabColor: C.gold,
        onFab: () => Navigator.popUntil(c, (r) => r.settings.name == '/games' || r.settings.name == '/home'),
        tabs: [
          (Icons.leaderboard_outlined, 'Rankings', () => Navigator.pushNamed(c, '/rankings')),
          (Icons.person_outline, 'Profile', () => Navigator.pushNamed(c, '/profile')),
        ],
      );
}

/// Side menu reached from the hamburger and the home FAB.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    void go(String route) {
      Navigator.pop(context);
      Navigator.pushNamed(context, route);
    }

    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            color: C.headerRed,
            image: DecorationImage(image: AssetImage('assets/images/v1-header-wave.png'), fit: BoxFit.cover),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text('AkomaCare',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
        for (final (icon, label, route) in [
          (Icons.menu_book_outlined, 'Read Guidelines', '/guidelines'),
          (Icons.calculate_outlined, 'Health Assessors', '/calculators'),
          (Icons.sports_esports_outlined, 'Brain Teasers', '/games'),
          (Icons.leaderboard_outlined, 'Rankings', '/rankings'),
          (Icons.bookmark_border, 'Bookmarks', '/saved'),
          (Icons.person_outline, 'Profile', '/profile'),
        ])
          ListTile(leading: Icon(icon, color: C.red), title: Text(label), onTap: () => go(route)),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: C.muted),
          title: const Text('Sign out'),
          onTap: () {
            AppState.i.signOut();
            Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
          },
        ),
      ]),
    );
  }
}

/// Small white circular "Call Center" action (guidelines screens).
class ContactFab extends StatelessWidget {
  const ContactFab({super.key});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton.small(
          heroTag: 'contact',
          tooltip: 'Contact AkomaCare',
          backgroundColor: C.card,
          foregroundColor: C.red,
          shape: const CircleBorder(),
          onPressed: () => openUrl(context, 'mailto:info@akomacare.org'),
          child: const Icon(Icons.support_agent),
        ),
        const Text('Call Center', style: TextStyle(color: C.red, fontSize: 11)),
      ]);
}

/// Two-tone section title, e.g. "Continue **reading**".
class TwoTone extends StatelessWidget {
  final String a, b;
  const TwoTone(this.a, this.b, {super.key});

  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.textBrown),
        children: [TextSpan(text: '$a  '), TextSpan(text: b, style: const TextStyle(color: C.red))],
      ));
}
