import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: const AppDrawer(),
        bottomNavigationBar: Bars.home(),
        body: ListView(padding: EdgeInsets.zero, children: [
          const WaveHeader(back: true, bottom: TabChip('Calculators')),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(children: [
              for (final c in calculators)
                RowCard(
                  minHeight: 56,
                  onTap: () => Navigator.pushNamed(context, '/calculator', arguments: c.id),
                  child: Row(children: [
                    Image.asset('assets/images/stethoscope.png', width: 22, height: 22),
                    const SizedBox(width: 14),
                    Expanded(child: Text(c.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600))),
                    const Icon(Icons.chevron_right, color: C.text),
                  ]),
                ),
            ]),
          ),
        ]),
      );
}

class CalculatorScreen extends StatefulWidget {
  final String id;
  const CalculatorScreen(this.id, {super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorState();
}

class _CalculatorState extends State<CalculatorScreen> {
  late final calc = calculators.firstWhere((c) => c.id == widget.id);
  late final Map<String, double> values = {
    for (final f in calc.fields)
      f.key: switch (f) { NumField(:final initial) => initial, ChoiceField(:final options) => options.first.$2, _ => 0 },
  };
  late final Map<String, TextEditingController> ctrls = {
    for (final f in calc.fields.whereType<NumField>()) f.key: TextEditingController(text: f.initial.toStringAsFixed(1)),
  };

  /// Null when every number input is valid and in range.
  String? get invalid {
    for (final f in calc.fields.whereType<NumField>()) {
      final v = double.tryParse(ctrls[f.key]!.text);
      if (v == null || !v.isFinite || v < f.min || v > f.max) return '${f.label} must be ${f.min.toInt()}–${f.max.toInt()} ${f.unit}';
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final err = invalid;
    final result = calc.compute == null || err != null ? null : calc.compute!(values);
    return Scaffold(
      drawer: const AppDrawer(),
      bottomNavigationBar: Bars.home(),
      body: ListView(padding: EdgeInsets.zero, children: [
        const WaveHeader(back: true, bottom: TabChip('Calculators')),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(calc.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(calc.subtitle, style: const TextStyle(color: C.muted)),
              const SizedBox(height: 16),
              for (final f in calc.fields) _field(f),
              if (calc.reference != null) Text(calc.reference!, style: const TextStyle(height: 1.5)),
              if (err != null) Text(err, style: const TextStyle(color: C.redDark)),
              if (result != null)
                Semantics(
                  liveRegion: true,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: C.readPillHalo,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: C.red.withValues(alpha: .3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(result.value, style: const TextStyle(color: C.red, fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(result.note, style: const TextStyle(color: C.redDark)),
                    ]),
                  ),
                ),
              const SizedBox(height: 18),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('BACK TO CALCULATORS')),
              const SizedBox(height: 10),
              const Text('Decision support only. Confirm against the full guideline and clinical judgement.',
                  style: TextStyle(color: C.muted, fontSize: 12)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _field(Field f) => switch (f) {
        NumField(:final key, :final label, :final unit) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: TextField(
              controller: ctrls[key],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: '$label ($unit)', fillColor: C.pageBg),
              onChanged: (s) => setState(() {
                final v = double.tryParse(s);
                if (v != null) values[key] = v;
              }),
            ),
          ),
        CheckField(:final key, :final label, :final points) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: C.red,
            value: values[key] != 0,
            title: Text(label, style: const TextStyle(fontSize: 14)),
            secondary: Text(points > 0 ? '+${_fmt(points)}' : _fmt(points),
                style: const TextStyle(color: C.muted, fontWeight: FontWeight.w600)),
            onChanged: (on) => setState(() => values[key] = on! ? points : 0),
          ),
        ChoiceField(:final key, :final label, :final options) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                for (final (name, pts) in options)
                  ChoiceChip(
                    label: Text(name),
                    selected: values[key] == pts,
                    selectedColor: C.readPillHalo,
                    onSelected: (_) => setState(() => values[key] = pts),
                  ),
              ]),
            ]),
          ),
      };

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
