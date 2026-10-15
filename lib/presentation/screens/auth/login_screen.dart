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
  final _identifier = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();

    await auth.login(
      _identifier.text,
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

  Future<String?> _askForPasswordResetIdentifier() async {
    return showDialog<String>(
      context: context,
      builder: (_) => _PasswordResetDialog(
        initialValue: _identifier.text.trim().contains('@')
            ? _identifier.text.trim()
            : '',
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final identifier = await _askForPasswordResetIdentifier();
    if (!mounted || identifier == null) return;

    final auth = context.read<AuthProvider>();
    await auth.sendPasswordReset(identifier);

    if (!mounted) return;

    final message = auth.error ??
        'Password reset link sent. Check your email and follow the instructions.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
    auth.clearError();
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
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(
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
                    controller: _identifier,
                    validator: Validators.phoneOrUsername,
                    decoration: const InputDecoration(
                      labelText: 'Username / phone number',
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
                      labelText: 'Password / PIN',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),
                      suffixIcon: IconButton(
                        tooltip: _obscure
                            ? 'Show password'
                            : 'Hide password',
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

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

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

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
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
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          validator: Validators.passwordResetIdentifier,
          onFieldSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Email, username, or phone number',
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_outlined),
          label: const Text('Send link'),
        ),
      ],
    );
  }
}
