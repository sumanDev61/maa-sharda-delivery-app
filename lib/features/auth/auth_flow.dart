import 'dart:async';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/app_state.dart';
import '../../app/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../ui/primary_button.dart';
import 'dart:convert';

const MethodChannel _deviceUtilsChannel = MethodChannel(
  'maa_sharda/device_utils',
);

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  AuthStep _step = AuthStep.splash;
  String _phone = '';
  String _riderId = '';
  String? _otp;

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
        onContinue: (phone, riderId, otp) => setState(() {
          _phone = phone;
          _riderId = riderId;
          _otp = otp;
          _step = AuthStep.otp;
        }),
        onRegister: (phone) => setState(() {
          _phone = phone;
          _step = AuthStep.register;
        }),
      ),
      AuthStep.register => _RegisterScreen(
        phone: _phone,
        onContinue: (phone, riderId, otp) => setState(() {
          _phone = phone;
          _riderId = riderId;
          _otp = otp;
          _step = AuthStep.otp;
        }),
      ),
      AuthStep.otp => _OtpScreen(
        phone: _phone,
        riderId: _riderId,
        otp: _otp,
        onVerified: () {
          final state = AppStateScope.of(context);
          final next = !state.isOnboardingComplete
              ? '/onboarding'
              : (state.rider.verification == VerificationStatus.verified
                    ? '/home'
                    : '/under-review');
          Navigator.of(context).pushReplacementNamed(next);
        },
        onBack: () => setState(() => _step = AuthStep.login),
      ),
    };
  }
}

enum AuthStep { splash, login, register, otp }

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
  const _LoginScreen({required this.onContinue, required this.onRegister});

  final void Function(String phone, String riderId, String? otp) onContinue;
  final void Function(String phone) onRegister;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;
  List<String> _simNumbers = const [];
  bool _isDetectingSim = false;

  @override
  void initState() {
    super.initState();
    _loadSimNumbers();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _digitsOnly(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

  String _lastTenDigits(String input) {
    final digits = _digitsOnly(input);
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  bool _isEnteredNumberFromDeviceSim(String enteredPhone) {
    if (_simNumbers.isEmpty) return true;
    final entered = _lastTenDigits(enteredPhone);
    if (entered.length < 10) return false;
    return _simNumbers.any((sim) => _lastTenDigits(sim) == entered);
  }

  Future<void> _loadSimNumbers() async {
    setState(() => _isDetectingSim = true);
    try {
      final phonePermission = await Permission.phone.request();
      if (!phonePermission.isGranted) return;
      final result = await _deviceUtilsChannel.invokeMethod<List<dynamic>>(
        'getSimNumbers',
      );
      final values = (result ?? const <dynamic>[])
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      if (!mounted) return;
      setState(() => _simNumbers = values);
      if (_simNumbers.length == 1 && _controller.text.trim().isEmpty) {
        _controller.text = _lastTenDigits(_simNumbers.first);
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    } catch (_) {
      // Best-effort SIM detection only.
    } finally {
      if (mounted) setState(() => _isDetectingSim = false);
    }
  }

  Future<void> _suggestSimNumber() async {
    if (_simNumbers.isEmpty) {
      await _loadSimNumbers();
    }
    if (!mounted || _simNumbers.isEmpty) return;
    if (_simNumbers.length == 1) {
      _controller.text = _lastTenDigits(_simNumbers.first);
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Choose SIM Number',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ..._simNumbers.asMap().entries.map((entry) {
              final i = entry.key;
              final number = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(number),
                onTap: () {
                  _controller.text = _lastTenDigits(number);
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _controller.text.length),
                  );
                  Navigator.pop(sheetContext);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final raw = _controller.text.trim();
    final digits = _digitsOnly(raw);
    if (digits.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 10-digit mobile number')),
      );
      return;
    }
    if (!_isEnteredNumberFromDeviceSim(digits)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This mobile number is not available in this phone. Please enter your active SIM number.',
          ),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiClient().post(
        '/v1/delivery/login',
        body: {'phone': digits},
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final d = (data['data'] as Map?)?.cast<String, dynamic>() ?? {};
        final riderId = d['rider_id']?.toString() ?? '';
        if (riderId.isEmpty) {
          throw Exception('Invalid response');
        }
        setState(() => _loading = false);
        widget.onContinue(digits, riderId, null);
        return;
      }

      if (res.statusCode == 404) {
        setState(() => _loading = false);
        widget.onRegister(digits);
        return;
      }

      setState(() => _loading = false);
      final msg =
          (jsonDecode(res.body) as Map?)?['error']?.toString() ??
          'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                onTap: _suggestSimNumber,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone_android),
                  hintText: _isDetectingSim
                      ? 'Detecting SIM numbers...'
                      : (_simNumbers.isNotEmpty
                            ? 'Tap to pick SIM number'
                            : 'Phone number'),
                  suffixIcon: _simNumbers.isNotEmpty
                      ? IconButton(
                          onPressed: _suggestSimNumber,
                          icon: const Icon(Icons.sim_card, size: 20),
                          tooltip: 'Choose SIM number',
                        )
                      : null,
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

class _RegisterScreen extends StatefulWidget {
  const _RegisterScreen({required this.phone, required this.onContinue});

  final String phone;
  final void Function(String phone, String riderId, String? otp) onContinue;

  @override
  State<_RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<_RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and email')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiClient().post(
        '/v1/delivery/register',
        body: {'phone': widget.phone, 'name': name, 'email': email},
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final d = (data['data'] as Map?)?.cast<String, dynamic>() ?? {};
        final riderId = d['rider_id']?.toString() ?? '';
        if (riderId.isEmpty) {
          throw Exception('Invalid response');
        }
        setState(() => _loading = false);
        widget.onContinue(widget.phone, riderId, null);
        return;
      }

      setState(() => _loading = false);
      final msg =
          (jsonDecode(res.body) as Map?)?['error']?.toString() ??
          'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Text('New here?', style: textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Create your account to continue.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Phone: ${widget.phone}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Your name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'name@example.com',
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PrimaryButton(
                  label: 'Continue',
                  isLoading: _loading,
                  onPressed: _register,
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
    required this.riderId,
    required this.otp,
    required this.onVerified,
    required this.onBack,
  });

  final String phone;
  final String riderId;
  final String? otp;
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

  @override
  void initState() {
    super.initState();
    final otp = widget.otp?.trim();
    if (otp != null && otp.isNotEmpty) {
      _controller.text = otp;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: otp.length),
      );
    }
  }

  Future<void> _verify() async {
    if (_controller.text.trim().length != 6) return;
    setState(() => _loading = true);

    try {
      final res = await ApiClient().post(
        '/v1/delivery/verify-otp',
        body: {'rider_id': widget.riderId, 'otp': _controller.text.trim()},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token'] as String;
        final riderId = data['rider']['id'].toString();
        final name = (data['rider']['name'] as String?) ?? '';
        final phone = (data['rider']['phone'] as String?) ?? widget.phone;
        final approval =
            (data['rider']['approval_status'] as String?) ?? 'inReview';

        await ApiClient().setAuthSession(token, riderId);

        final state = AppStateScope.of(context);
        await state.login(phone: phone);
        if (name.isNotEmpty) {
          await state.updateGeneralInfo(name: name);
        }
        state.setBackgroundVerification(
          approval.toLowerCase() == 'approved'
              ? VerificationStatus.verified
              : VerificationStatus.inReview,
        );

        widget.onVerified();
      } else {
        setState(() => _loading = false);
        final msg = jsonDecode(res.body)['error'] ?? 'Verification failed';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
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
              // OTP is delivered via SMS (MessageCentral).
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _verify(),
                decoration: const InputDecoration(
                  counterText: '',
                  prefixIcon: Icon(Icons.lock_outline),
                  hintText: '6-digit OTP',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text("Didn't receive?", style: textTheme.bodySmall),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            setState(() => _loading = true);
                            try {
                              final res = await ApiClient().post(
                                '/v1/delivery/login',
                                body: {'phone': widget.phone},
                              );
                              if (!mounted) return;
                              if (res.statusCode == 200) {
                                // OTP resent via SMS
                              }
                            } catch (_) {}
                            if (mounted) setState(() => _loading = false);
                          },
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
                  onPressed: _controller.text.trim().length == 6
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
