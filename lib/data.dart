// Seeded demo content. Guideline text is only included where the supplied
// design export carries it (Stroke > Referral); every other section shows a
// clearly-labelled placeholder rather than invented clinical text.

sealed class Block {
  const Block();
}

class Para extends Block {
  final String text;
  const Para(this.text);
}

class Callout extends Block {
  final String text;
  const Callout(this.text);
}

class Heading extends Block {
  final String text;
  const Heading(this.text);
}

class Caption extends Block {
  final String text;
  const Caption(this.text);
}

/// Figure 13, drawn natively.
class StrokeFlowchart extends Block {
  const StrokeFlowchart();
}

class TableBlock extends Block {
  final String title;
  final String subtitle;
  final String intro;
  final List<String> header;
  final List<List<String>> rows;
  final String footer;
  const TableBlock(this.title, this.subtitle, this.intro, this.header, this.rows, this.footer);
}

class Section {
  final String id;
  final String title;
  final List<Block> blocks;
  const Section(this.id, this.title, [this.blocks = const []]);
}

class Guideline {
  final String id;
  final String title;
  final String hero; // asset
  final List<Section> sections;
  const Guideline(this.id, this.title, this.hero, this.sections);
}

const _standard = [
  'Management According to Level of Care',
  'Full Content',
  'Introduction',
  'Aetiology',
  'Clinical Presentation',
  'Complications',
  'Referral',
  'Patient Education and Prevention',
];

List<Section> _sections(List<String> titles) =>
    [for (final t in titles) Section(t.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '-'), t)];

const strokeReferral = [
  Para('Ideally all stroke cases should be referred to a Stroke Unit immediately for optimal care from a '
      'multidisciplinary team (MDT = the medical, neurosurgical, nursing, physiotherapy, clinical psychologist, '
      'occupational therapist, dietician, speech and language therapist).'),
  Callout('All stroke cases should be referred to a facility with a physician specialist.'),
  Para('The physician specialist will have to follow the algorithm below to refer to a stroke unit.'),
  Caption('Figure 13: Stroke unit protocol for patient referral (Adapted from the Korle-Bu stroke unit protocol)'),
  StrokeFlowchart(),
  Heading('Discharge plan'),
  Para('Discharge plan should be initiated from day one of admission with the MDT. Scoring for ROSIER scale:'),
  Caption('Table 40: Emergency room stroke recognition (ROSIER)'),
  TableBlock(
    'ROSIER Scale',
    'Stroke Assessment',
    'The aim of this assessment tool is to enable medical and nursing staff to differentiate patients with '
        'stroke and stroke mimics.',
    ['Item', 'Yes', 'No'],
    [
      ['Loss of consciousness or syncope', '−1', '0'],
      ['Seizure activity', '−1', '0'],
      ['Asymmetric facial weakness', '+1', '0'],
      ['Asymmetric arm weakness', '+1', '0'],
      ['Asymmetric leg weakness', '+1', '0'],
      ['Speech disturbance', '+1', '0'],
      ['Visual field defect', '+1', '0'],
    ],
    'Total score (−2 to +5). Stroke is likely if the total is greater than 0.',
  ),
];

final guidelines = <Guideline>[
  Guideline('hypertension', 'Hypertension', 'assets/images/v1-banner-heart-warm.png', _sections(_standard)),
  Guideline('stroke', 'Stroke', 'assets/images/v1-banner-stroke-brain.png', [
    const Section('management-according-to-level-of-care', 'Management According to Level of Care'),
    const Section('full-content', 'Full Content'),
    const Section('introduction', 'Introduction'),
    const Section('clinical-presentation', 'Clinical Presentation'),
    const Section('complications', 'Complications'),
    const Section('referral', 'Referral', strokeReferral),
    const Section('patient-education-and-prevention', 'Patient Education and Prevention'),
  ]),
  Guideline('chest-pain', 'Chest Pain, Coronary Artery Disease And Myocardial Infarction',
      'assets/images/v1-banner-heart-dark.png', _sections(_standard)),
  Guideline('heart-failure', 'Heart Failure', 'assets/images/v1-banner-heart-warm.png', _sections(_standard)),
];

/// Top-level rows rendered in caps on the sections screen.
const topLevelSections = {'management-according-to-level-of-care', 'full-content'};

Guideline guideline(String id) => guidelines.firstWhere((g) => g.id == id, orElse: () => guidelines.first);

/// Resolves a persisted "guidelineId/sectionId" key; null if it no longer exists.
(Guideline, Section)? resolve(String key) {
  final p = key.split('/');
  for (final g in guidelines) {
    for (final s in g.sections) {
      if (g.id == p.first && s.id == p.last) return (g, s);
    }
  }
  return null;
}

// ---------------------------------------------------------------- calculators

sealed class Field {
  final String key;
  final String label;
  const Field(this.key, this.label);
}

class NumField extends Field {
  final String unit;
  final double initial;
  final double min, max;
  const NumField(super.key, super.label, this.unit, this.initial, this.min, this.max);
}

class CheckField extends Field {
  final double points;
  const CheckField(super.key, super.label, this.points);
}

/// One-of choice; each option carries its points.
class ChoiceField extends Field {
  final List<(String, double)> options;
  const ChoiceField(super.key, super.label, this.options);
}

typedef Result = ({String value, String note});

class Calculator {
  final String id;
  final String title;
  final String subtitle;
  final List<Field> fields;
  final Result Function(Map<String, double> v)? compute;
  final String? reference; // shown instead of a computed result
  const Calculator(this.id, this.title, this.subtitle, this.fields, {this.compute, this.reference});
}

String _n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

double sumPoints(List<Field> fields, Map<String, double> v) =>
    fields.whereType<CheckField>().fold(0.0, (s, f) => s + (v[f.key] ?? 0)) +
    fields.whereType<ChoiceField>().fold(0.0, (s, f) => s + (v[f.key] ?? 0));

const _wellsDvt = [
  CheckField('cancer', 'Active cancer (treatment within 6 months or palliative)', 1),
  CheckField('bed', 'Bedridden > 3 days or major surgery within 12 weeks', 1),
  CheckField('calf', 'Calf swelling > 3 cm compared with the other leg', 1),
  CheckField('veins', 'Collateral (non-varicose) superficial veins present', 1),
  CheckField('leg', 'Entire leg swollen', 1),
  CheckField('tender', 'Localised tenderness along the deep venous system', 1),
  CheckField('oedema', 'Pitting oedema confined to the symptomatic leg', 1),
  CheckField('paralysis', 'Paralysis, paresis or recent plaster immobilisation of the leg', 1),
  CheckField('prior', 'Previously documented DVT', 1),
  CheckField('alt', 'Alternative diagnosis at least as likely as DVT', -2),
];

const _wellsPe = [
  CheckField('dvt', 'Clinical signs and symptoms of DVT', 3),
  CheckField('likely', 'PE is the most likely diagnosis', 3),
  CheckField('hr', 'Heart rate > 100 bpm', 1.5),
  CheckField('immob', 'Immobilisation ≥ 3 days or surgery in the previous 4 weeks', 1.5),
  CheckField('prior', 'Previous DVT or PE', 1.5),
  CheckField('haemoptysis', 'Haemoptysis', 1),
  CheckField('cancer', 'Malignancy (treatment within 6 months or palliative)', 1),
];

const _chads = [
  ChoiceField('age', 'Age', [('< 65', 0), ('65–74', 1), ('≥ 75', 2)]),
  ChoiceField('sex', 'Sex', [('Male', 0), ('Female', 1)]),
  CheckField('chf', 'Congestive heart failure', 1),
  CheckField('htn', 'Hypertension', 1),
  CheckField('dm', 'Diabetes mellitus', 1),
  CheckField('stroke', 'Prior stroke, TIA or thromboembolism', 2),
  CheckField('vasc', 'Vascular disease (prior MI, peripheral artery disease, aortic plaque)', 1),
];

const _hasBled = [
  CheckField('h', 'Uncontrolled hypertension (systolic > 160 mmHg)', 1),
  CheckField('renal', 'Abnormal renal function', 1),
  CheckField('liver', 'Abnormal liver function', 1),
  CheckField('s', 'Prior stroke', 1),
  CheckField('b', 'Prior major bleeding or predisposition to bleeding', 1),
  CheckField('l', 'Labile INR', 1),
  CheckField('e', 'Elderly (age > 65)', 1),
  CheckField('drugs', 'Medication predisposing to bleeding (antiplatelets, NSAIDs)', 1),
  CheckField('alcohol', 'Alcohol use (≥ 8 drinks a week)', 1),
];

final calculators = <Calculator>[
  Calculator('bmi', 'BMI Calculator', 'Body Mass Index clinical risk check (kg/m²)', const [
    NumField('w', 'Weight', 'kg', 74, 20, 300),
    NumField('h', 'Height', 'cm', 172, 100, 230),
  ], compute: (v) {
    final m = v['h']! / 100, bmi = v['w']! / (m * m);
    final c = bmi < 18.5
        ? 'Underweight (< 18.5)'
        : bmi < 25
            ? 'Normal weight (18.5–24.9)'
            : bmi < 30
                ? 'Overweight (25.0–29.9)'
                : 'Obese (≥ 30.0)';
    return (value: 'BMI: ${bmi.toStringAsFixed(1)} kg/m²', note: 'Classification: $c');
  }),
  Calculator('wells-dvt', "Wells' Criteria for DVT", 'Deep Vein Thrombosis risk assessment', _wellsDvt,
      compute: (v) {
    final s = sumPoints(_wellsDvt, v);
    return (value: 'Score: ${_n(s)}', note: s >= 2 ? 'DVT likely (score ≥ 2)' : 'DVT unlikely (score < 2)');
  }),
  Calculator('wells-pe', "Wells' Criteria for Pulmonary Embolism", 'Pulmonary Embolism probability assessment',
      _wellsPe, compute: (v) {
    final s = sumPoints(_wellsPe, v);
    return (value: 'Score: ${_n(s)}', note: s > 4 ? 'PE likely (score > 4)' : 'PE unlikely (score ≤ 4)');
  }),
  Calculator('chads', 'CHA₂DS₂-VASc Score for Atrial Fibrillation Stroke Risk',
      'Stroke risk assessment in atrial fibrillation', _chads, compute: (v) {
    final s = sumPoints(_chads, v);
    final female = (v['sex'] ?? 0) == 1;
    final risk = s - (female ? 1 : 0); // sex alone is not a risk factor
    final note = risk <= 0
        ? 'Low risk: anticoagulation generally not indicated'
        : risk == 1
            ? 'Anticoagulation should be considered'
            : 'Anticoagulation recommended';
    return (value: 'Score: ${_n(s)}', note: note);
  }),
  Calculator('map', 'Mean Arterial Pressure (MAP)', 'Average arterial pressure over one cardiac cycle', const [
    NumField('sbp', 'Systolic BP', 'mmHg', 120, 40, 300),
    NumField('dbp', 'Diastolic BP', 'mmHg', 80, 20, 200),
  ], compute: (v) {
    final map = (v['sbp']! + 2 * v['dbp']!) / 3;
    return (
      value: 'MAP: ${map.toStringAsFixed(0)} mmHg',
      note: map < 65 ? 'Below 65 mmHg: organ perfusion may be inadequate' : 'MAP = (SBP + 2 × DBP) ÷ 3'
    );
  }),
  Calculator('has-bled', 'HAS-BLED Score for Major Bleeding Risk', 'One-year major bleeding risk on anticoagulation',
      _hasBled, compute: (v) {
    final s = sumPoints(_hasBled, v);
    return (
      value: 'Score: ${_n(s)}',
      note: s >= 3 ? 'High bleeding risk: review modifiable factors' : 'Low to moderate bleeding risk'
    );
  }),
  Calculator('max-hr', 'Maximum heart rate estimation (during exercise or treadmill test)',
      'Age-predicted maximum heart rate', const [NumField('age', 'Age', 'years', 45, 10, 110)], compute: (v) {
    final hr = 220 - v['age']!;
    return (
      value: 'Max HR: ${hr.toStringAsFixed(0)} bpm',
      note: '85% target: ${(hr * .85).toStringAsFixed(0)} bpm  (220 − age)'
    );
  }),
  const Calculator(
    'who-ish',
    'World Health Organization/International Society of Hypertension risk prediction chart',
    '10-year cardiovascular risk',
    [],
    reference: 'The WHO/ISH chart reads 10-year risk from age, sex, systolic BP, smoking, diabetes and '
        'cholesterol on region-specific charts (Ghana: WHO AFR region). Use the chart in the guideline text; '
        'this build does not compute it.',
  ),
];

// ---------------------------------------------------------------------- games

class QuizQ {
  final String q;
  final List<String> options;
  final int answer;
  const QuizQ(this.q, this.options, this.answer);
}

/// Questions are drawn only from the scoring rules implemented above.
const quiz = [
  QuizQ('A ROSIER total greater than which value makes stroke likely?', ['−1', '0', '2', '5'], 1),
  QuizQ('A BMI of 27.0 kg/m² is classified as…', ['Normal weight', 'Overweight', 'Obese', 'Underweight'], 1),
  QuizQ('Mean arterial pressure is calculated as…',
      ['(SBP + DBP) ÷ 2', '(2 × SBP + DBP) ÷ 3', '(SBP + 2 × DBP) ÷ 3', 'SBP − DBP'], 2),
  QuizQ('In CHA₂DS₂-VASc, which item scores 2 points?',
      ['Hypertension', 'Diabetes', 'Prior stroke or TIA', 'Female sex'], 2),
  QuizQ("In Wells' criteria for PE, a heart rate above 100 bpm scores…", ['1', '1.5', '2', '3'], 1),
  QuizQ("In Wells' criteria for DVT, an equally likely alternative diagnosis scores…", ['+1', '0', '−1', '−2'], 3),
  QuizQ('A HAS-BLED score of at least what indicates high bleeding risk?', ['1', '2', '3', '5'], 2),
  QuizQ('Age-predicted maximum heart rate for a 40-year-old is…', ['160 bpm', '180 bpm', '200 bpm', '220 bpm'], 1),
];

const wordFinderWords = ['STROKE', 'HEART', 'PULSE', 'AORTA', 'ANGINA', 'STENT', 'ECHO', 'VALVE'];

const puzzleImages = [
  ('Chest X-ray', 'assets/images/v1-thumb-xray.png'),
  ('Echo', 'assets/images/v1-puzzle-echo.png'),
  ('CT', 'assets/images/v1-thumb-ct.png'),
];

// ------------------------------------------------------------- demo accounts

/// Demo sign-in for the mock auth layer. Not a real account.
const demoEmail = 'john.doe@demo.akomacare';
const demoPassword = 'demo1234';
const demoName = 'Mr. John Doe';

/// Seeded leaderboard players (handles from the 2023 store captures). Demo data.
const boards = {
  'LEADER BOARD': [('K-TEE', 730), ('AKOMA', 270), ('HORLI', 220), ('DAVID', 203), ('WONIT', 196), ('ESIVI', 170), ('KOJO', 80)],
  'MASTER BOARD': [('AKOMA', 42), ('DAVID', 37), ('K-TEE', 30), ('ESIVI', 22), ('HORLI', 18), ('WONIT', 9), ('KOJO', 4)],
  'LOYALTY BOARD': [('WONIT', 64), ('HORLI', 51), ('AKOMA', 40), ('K-TEE', 33), ('KOJO', 21), ('DAVID', 12), ('ESIVI', 7)],
};
