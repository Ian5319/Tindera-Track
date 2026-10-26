import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();

    await auth.login(
      _username.text,
      _email.text,
      _password.text,
    );

    if (!mounted) return;

    if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
        ),
      );

      auth.clearError();
    }
  }

  Future<bool?> _showPasswordResetDialog() {
    final auth = context.read<AuthProvider>();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PasswordResetDialog(
        initialValue:
            _email.text.trim().contains('@') ? _email.text.trim() : '',
        sendPasswordReset: auth.sendPasswordReset,
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final sent = await _showPasswordResetDialog();
    if (!mounted || sent != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Password reset link sent. Check your email and follow the instructions.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 480,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                  ),
                  Text(
                    AppStrings.tagline,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to manage your store inventory and customer utang.',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _username,
                    validator: Validators.loginUsername,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'e.g. tindera_ana',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(
                        Icons.person_outline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    validator: Validators.password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: auth.loading ? null : _forgotPassword,
                      child: const Text(
                        'Forgot Password?',
                      ),
                    ),
                  ),
                  CustomButton(
                    label: 'Log In',
                    icon: Icons.login,
                    onPressed: _login,
                    loading: auth.loading,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text(
                        'Create Account',
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

class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({
    super.key,
    required this.initialValue,
    required this.sendPasswordReset,
  });

  final String initialValue;
  final Future<String?> Function(String identifier) sendPasswordReset;

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    final error = await widget.sendPasswordReset(_controller.text.trim());
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _sending = false;
        _error = error;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset your password'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          enabled: !_sending,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          validator: Validators.passwordResetIdentifier,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onFieldSubmitted: _sending ? null : (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Email address',
            hintText: 'name@example.com',
            prefixIcon: const Icon(Icons.alternate_email),
            errorText: _error,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _sending ? null : _submit,
          icon: _sending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: Text(_sending ? 'Sending…' : 'Send link'),
        ),
      ],
    );
  }
}
