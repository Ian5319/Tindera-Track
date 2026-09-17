import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    await auth.signUp(_name.text, _email.text, _password.text);
    if (!mounted) return;
    if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!)));
      auth.clearError();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(appBar: AppBar(title: const Text('Create Account')), body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Set up your store account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Keep it simple. You can start managing inventory and utang right away.'),
      const SizedBox(height: 24),
      TextFormField(controller: _name, validator: (v) => Validators.requiredField(v, 'Full name'), decoration: const InputDecoration(labelText: 'Full name', helperText: 'Use your everyday store-owner name', prefixIcon: Icon(Icons.badge_outlined))),
      const SizedBox(height: 16),
      TextFormField(controller: _email, validator: Validators.email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', helperText: 'Example: ate@example.com', prefixIcon: Icon(Icons.email_outlined))),
      const SizedBox(height: 16),
      TextFormField(controller: _password, validator: Validators.strongPassword, obscureText: _obscure, decoration: InputDecoration(labelText: 'Password', helperText: 'Use 8+ characters with a mix of letters, numbers, symbols', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
      const SizedBox(height: 24),
      CustomButton(label: 'Sign Up', icon: Icons.person_add_alt_1, onPressed: _signUp, loading: auth.loading),
      const SizedBox(height: 10),
      Center(child: TextButton(onPressed: () => context.go('/login'), child: const Text('Already have an account? Sign In'))),
      const SizedBox(height: 18),
      Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(16)), child: const Text('Phase 1 demo stores account data locally in Hive. Use a real backend before production deployment.')),
    ]))))));
  }
}
