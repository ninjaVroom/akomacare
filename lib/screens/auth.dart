import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

const _pages = [
  'Ultimate guide on handling heart-related diseases for health workers.',
  'Risk calculators and assessors at the point of care.',
  'Learn with quizzes and puzzles, and climb the rankings.',
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen> {
  int page = 0;

  void done() {
    AppState.i.finishOnboarding();
    Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.red,
      body: Stack(children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Image.asset('assets/images/onboarding-nurse.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: done,
              child: const Text('Skip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ClipPath(
            clipper: _CurveTop(),
            child: Container(
              color: C.card,
              padding: EdgeInsets.fromLTRB(28, 48, 16, 16 + MediaQuery.paddingOf(context).bottom),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/images/logo.png', height: 40, semanticLabel: 'AkomaCare'),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250),
                  child: Text(_pages[page],
                      key: ValueKey(page),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.35)),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (var i = 0; i < _pages.length; i++)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == page ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: i == page ? C.red : C.readPillHalo, borderRadius: BorderRadius.circular(3)),
                        ),
                    ]),
                  ),
                  IconButton(
                    tooltip: page == _pages.length - 1 ? 'Get started' : 'Next',
                    icon: const Icon(Icons.chevron_right, color: C.red, size: 30),
                    onPressed: () => page == _pages.length - 1 ? done() : setState(() => page++),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

Widget _blob(double size, Color color) =>
    Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

class _CurveTop extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 36)
    ..quadraticBezierTo(s.width / 2, -20, s.width, 36)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();
  @override
  bool shouldReclip(_) => false;
}

/// Shared shell: grey page with red blobs, logo and a light-weight title.
class _AuthShell extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _AuthShell({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          Positioned(top: -90, right: -60, child: _blob(220, C.red)),
          Positioned(top: 150, right: -70, child: _blob(110, C.red)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ListView(padding: const EdgeInsets.fromLTRB(24, 72, 24, 24), children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset('assets/images/logo.png', height: 52, semanticLabel: 'AkomaCare')),
                  const SizedBox(height: 18),
                  Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w300)),
                  const SizedBox(height: 28),
                  ...children,
                ]),
              ),
            ),
          ),
        ]),
      );
}

String? _email(String? v) =>
    v != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? null : 'Enter a valid email';
String? _password(String? v) => (v ?? '').length >= 6 ? null : 'At least 6 characters';
String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;

Widget _gap() => const SizedBox(height: 14);

Widget _footer(BuildContext context, String lead, String action, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Center(
        child: Text.rich(TextSpan(text: '$lead ', style: const TextStyle(color: C.muted), children: [
          TextSpan(
            text: action,
            style: const TextStyle(color: C.red, fontWeight: FontWeight.w700),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ])),
      ),
    );

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInState();
}

class _SignInState extends State<SignInScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), pass = TextEditingController();
  bool hide = true;
  String? error;

  void submit() {
    if (!form.currentState!.validate()) return;
    final e = AppState.i.signIn(email.text, pass.text);
    if (e != null) return setState(() => error = e);
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) => _AuthShell(title: 'Sign in.', children: [
        Form(
          key: form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: AutofillGroup(
            child: Column(children: [
              TextFormField(
                controller: email,
                validator: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              _gap(),
              TextFormField(
                controller: pass,
                validator: _password,
                obscureText: hide,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => submit(),
                decoration: InputDecoration(
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: hide ? 'Show password' : 'Hide password',
                    icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => hide = !hide),
                  ),
                ),
              ),
            ]),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forgot'),
            child: const Text('Forgot Password?', style: TextStyle(color: C.red)),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(error!, style: const TextStyle(color: C.redDark)),
          ),
        FilledButton(onPressed: submit, child: const Text('SIGN IN')),
        _footer(context, 'New User?', 'Sign up', () => Navigator.pushReplacementNamed(context, '/signup')),
      ]);
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpState();
}

class _SignUpState extends State<SignUpScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      facility = TextEditingController(),
      pass = TextEditingController();
  String? error;

  void submit() {
    if (!form.currentState!.validate()) return;
    final e = AppState.i.signUp(name.text, email.text, facility.text, pass.text);
    if (e != null) return setState(() => error = e);
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) => _AuthShell(title: 'Create account.', children: [
        Form(
          key: form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(children: [
            TextFormField(
                controller: name,
                validator: _required,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(hintText: 'Full Name (e.g., Dr. John Mensah)')),
            _gap(),
            TextFormField(
                controller: email,
                validator: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(hintText: 'Email Address')),
            _gap(),
            TextFormField(controller: facility, decoration: const InputDecoration(hintText: 'Facility / Cadre')),
            _gap(),
            TextFormField(
                controller: pass,
                validator: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => submit(),
                decoration: const InputDecoration(hintText: 'Password')),
          ]),
        ),
        const SizedBox(height: 20),
        if (error != null)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(error!, style: const TextStyle(color: C.redDark))),
        FilledButton(onPressed: submit, child: const Text('SIGN UP')),
        _footer(context, 'Already have an account?', 'Sign in.',
            () => Navigator.pushReplacementNamed(context, '/signin')),
      ]);
}

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});
  @override
  State<ForgotScreen> createState() => _ForgotState();
}

class _ForgotState extends State<ForgotScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();

  @override
  Widget build(BuildContext context) => _AuthShell(title: 'Reset password.', children: [
        const Text('Enter your registered clinician email to receive a password reset link.',
            style: TextStyle(color: C.muted)),
        const SizedBox(height: 18),
        Form(
          key: form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
              controller: email,
              validator: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Email')),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () {
            if (!form.currentState!.validate()) return;
            // Mock auth: nothing is sent. Same message either way so the screen
            // doesn't reveal which emails are registered.
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('If that email is registered, a reset link is on its way.')));
            _backToSignIn(context);
          },
          child: const Text('SEND RESET LINK'),
        ),
        Center(
          child: TextButton(
              onPressed: () => _backToSignIn(context),
              child: const Text('Back to Sign in', style: TextStyle(color: C.red))),
        ),
      ]);
}

/// Pops back to sign-in, or replaces with it when /forgot was opened directly.
void _backToSignIn(BuildContext context) =>
    Navigator.canPop(context) ? Navigator.pop(context) : Navigator.pushReplacementNamed(context, '/signin');
