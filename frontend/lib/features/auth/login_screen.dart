import 'package:flutter/material.dart';

import '../../services/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final auth = AuthScope.of(context);
    try {
      await auth.signIn(
        username: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _register() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final auth = AuthScope.of(context);
    try {
      await auth.register(
        username: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _error = null);
    final auth = AuthScope.of(context);
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCE9DC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.agriculture_rounded,
                            size: 34,
                            color: Color(0xFF2E6748),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'AgriProject AI',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Crop planning, pricing insights, and field-ready recommendations in one place.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Welcome back',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to continue with market intelligence and farm planning.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: auth.working ? null : _googleSignIn,
                              icon: const Icon(Icons.login_rounded),
                              label: Text(
                                auth.working
                                    ? 'Please wait…'
                                    : 'Continue with Google',
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    'or',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                              validator: (value) {
                                final trimmed = (value ?? '').trim();
                                if (trimmed.isEmpty) {
                                  return 'Please enter your email.';
                                }
                                if (!trimmed.contains('@')) {
                                  return 'Please enter a valid email.';
                                }
                                return null;
                              },
                              enabled: !auth.working,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                              ),
                              onFieldSubmitted: (_) => _submit(),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Please enter a password.';
                                }
                                if ((value ?? '').length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                              enabled: !auth.working,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: auth.working ? null : _submit,
                              child: Text(
                                  auth.working ? 'Signing in…' : 'Sign in'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: auth.working ? null : _register,
                              child: Text(
                                auth.working
                                    ? 'Please wait…'
                                    : 'Create account',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
