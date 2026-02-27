import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../ui/primary_button.dart';
import 'dart:convert';

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  AuthStep _step = AuthStep.splash;
  String _phone = '';

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _step = AuthStep.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      AuthStep.splash => const _SplashScreen(),
      AuthStep.login => _LoginScreen(
        onContinue: (phone) => setState(() {
          _phone = phone;
          _step = AuthStep.otp;
        }),
      ),
      AuthStep.otp => _OtpScreen(
        phone: _phone,
        onVerified: () {
          final state = AppStateScope.of(context);
          final next = state.isOnboardingComplete ? '/home' : '/onboarding';
          Navigator.of(context).pushReplacementNamed(next);
        },
        onBack: () => setState(() => _step = AuthStep.login),
      ),
    };
  }
}

enum AuthStep { splash, login, otp }

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Rider',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 10),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen({required this.onContinue});

  final ValueChanged<String> onContinue;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _controller.text.trim();
    if (raw.length < 10) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _loading = false);
    widget.onContinue(raw);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.delivery_dining,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text('Welcome, rider', style: textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Login with your phone number to start receiving orders.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_android),
                  hintText: 'Phone number',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'By continuing, you agree to the Terms and Privacy Policy.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PrimaryButton(
                  label: 'Continue',
                  isLoading: _loading,
                  onPressed: _controller.text.trim().length < 10
                      ? null
                      : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpScreen extends StatefulWidget {
  const _OtpScreen({
    required this.phone,
    required this.onVerified,
    required this.onBack,
  });

  final String phone;
  final VoidCallback onVerified;
  final VoidCallback onBack;

  @override
  State<_OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<_OtpScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_controller.text.trim().length != 4) return;
    setState(() => _loading = true);
    
    try {
      final res = await ApiClient().post('/v1/delivery/login', body: {
        'phone': widget.phone,
        'password': _controller.text.trim(),
      });
      
      if (!mounted) return;
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token'] as String;
        final riderId = data['rider']['id'].toString();
        final name = data['rider']['name'] as String;
        final phone = data['rider']['phone'] as String;
        
        await ApiClient().setAuthSession(token, riderId);
        
        final state = AppStateScope.of(context);
        await state.login(phone: phone);
        state.updateGeneralInfo(name: name);
        
        widget.onVerified();
      } else {
        setState(() => _loading = false);
        final msg = jsonDecode(res.body)['error'] ?? 'Invalid credentials';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Verify'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              Text('Enter OTP', style: textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('Sent to +91 ${widget.phone}', style: textTheme.bodySmall),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 4,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _verify(),
                decoration: const InputDecoration(
                  counterText: '',
                  prefixIcon: Icon(Icons.lock_outline),
                  hintText: '4-digit OTP',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text("Didn't receive?", style: textTheme.bodySmall),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: _loading ? null : () {},
                    child: const Text('Resend'),
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PrimaryButton(
                  label: 'Verify & continue',
                  isLoading: _loading,
                  onPressed: _controller.text.trim().length == 4
                      ? _verify
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
