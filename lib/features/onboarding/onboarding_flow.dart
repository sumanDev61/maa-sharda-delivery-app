import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme/app_theme.dart';
import '../../ui/primary_button.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[
      _PersonalStep(onNext: () => setState(() => _step = 1)),
      _VehicleStep(
        onBack: () => setState(() => _step = 0),
        onNext: () => setState(() => _step = 2),
      ),
      _BankStep(
        onBack: () => setState(() => _step = 1),
        onNext: () => setState(() => _step = 3),
      ),
      _DocumentsStep(
        onBack: () => setState(() => _step = 2),
        onFinish: () {
          final state = AppStateScope.of(context);
          state.setBackgroundVerification(VerificationStatus.inReview);
          Navigator.of(context).pushReplacementNamed('/home');
        },
      ),
    ];

    return steps[_step];
  }
}

class _OnboardingScaffold extends StatelessWidget {
  const _OnboardingScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryEnabled = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool primaryEnabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete profile'),
        leading: onSecondary == null
            ? null
            : IconButton(
                onPressed: onSecondary,
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(subtitle, style: textTheme.bodySmall),
              const SizedBox(height: 14),
              Expanded(child: child),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PrimaryButton(
                  label: primaryLabel,
                  onPressed: primaryEnabled ? onPrimary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalStep extends StatefulWidget {
  const _PersonalStep({required this.onNext});

  final VoidCallback onNext;

  @override
  State<_PersonalStep> createState() => _PersonalStepState();
}

class _PersonalStepState extends State<_PersonalStep> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return _OnboardingScaffold(
      title: 'Personal details',
      subtitle: 'Name and address help with delivery operations.',
      primaryLabel: 'Continue',
      primaryEnabled: _nameController.text.trim().isNotEmpty,
      onPrimary: () {
        state.updateGeneralInfo(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
        );
        widget.onNext();
      },
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.person, color: AppColors.primary, size: 34),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Profile photo', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Upload later in Profile', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('Upload'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline),
                      labelText: 'Full name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_android),
                      labelText: 'Phone',
                      hintText: state.rider.session.phone,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined),
                      labelText: 'Email (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on_outlined),
                      labelText: 'Address',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleStep extends StatefulWidget {
  const _VehicleStep({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<_VehicleStep> createState() => _VehicleStepState();
}

class _VehicleStepState extends State<_VehicleStep> {
  VehicleType _type = VehicleType.bike;
  final _numberController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return _OnboardingScaffold(
      title: 'Vehicle details',
      subtitle: 'We use this to assign deliveries and verify RC.',
      secondaryLabel: 'Back',
      onSecondary: widget.onBack,
      primaryLabel: 'Continue',
      primaryEnabled: _numberController.text.trim().isNotEmpty,
      onPrimary: () {
        state.updateVehicle(type: _type, number: _numberController.text.trim());
        widget.onNext();
      },
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicle type', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ChoiceChip(
                        label: 'Bike',
                        selected: _type == VehicleType.bike,
                        onTap: () => setState(() => _type = VehicleType.bike),
                      ),
                      _ChoiceChip(
                        label: 'Scooter',
                        selected: _type == VehicleType.scooter,
                        onTap: () => setState(() => _type = VehicleType.scooter),
                      ),
                      _ChoiceChip(
                        label: 'Cycle',
                        selected: _type == VehicleType.cycle,
                        onTap: () => setState(() => _type = VehicleType.cycle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _numberController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                      labelText: 'Vehicle number',
                      hintText: 'e.g. MP09AB1234',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'RC upload will be requested in Documents step.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.background,
                child: Icon(Icons.verified_user_outlined, color: AppColors.primary),
              ),
              title: const Text('Background verification'),
              subtitle: Text(_statusLabel(state.rider.verification)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pending => 'Pending',
      VerificationStatus.inReview => 'In review',
      VerificationStatus.verified => 'Verified',
      VerificationStatus.rejected => 'Rejected',
    };
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFCE7E9) : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.primary : AppColors.outline),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w800, color: selected ? AppColors.primary : AppColors.text),
        ),
      ),
    );
  }
}

class _BankStep extends StatefulWidget {
  const _BankStep({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<_BankStep> createState() => _BankStepState();
}

class _BankStepState extends State<_BankStep> {
  final _holderController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();

  @override
  void dispose() {
    _holderController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  bool get _valid =>
      _holderController.text.trim().isNotEmpty &&
      _accountController.text.trim().isNotEmpty &&
      _ifscController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return _OnboardingScaffold(
      title: 'Bank details',
      subtitle: 'Payments will be deposited to this account.',
      secondaryLabel: 'Back',
      onSecondary: widget.onBack,
      primaryLabel: 'Continue',
      primaryEnabled: _valid,
      onPrimary: () {
        state.updateBank(
          holder: _holderController.text.trim(),
          account: _accountController.text.trim(),
          ifsc: _ifscController.text.trim(),
        );
        widget.onNext();
      },
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _holderController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline),
                      labelText: 'Account holder name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accountController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_balance_outlined),
                      labelText: 'Account number',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ifscController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                      labelText: 'IFSC code',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.background,
                    child: Icon(Icons.security_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your bank details are encrypted and used only for payouts.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsStep extends StatefulWidget {
  const _DocumentsStep({required this.onBack, required this.onFinish});

  final VoidCallback onBack;
  final VoidCallback onFinish;

  @override
  State<_DocumentsStep> createState() => _DocumentsStepState();
}

class _DocumentsStepState extends State<_DocumentsStep> {
  bool _uploading = false;

  bool _isComplete(AppState state) => state.rider.profile.documents.mandatoryComplete;

  Future<void> _upload(AppState state, DocumentType type) async {
    setState(() => _uploading = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    state.setDocumentStatus(type, DocumentStatus.pending);
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final docs = state.rider.profile.documents;
    return _OnboardingScaffold(
      title: 'Documents',
      subtitle: 'Upload required documents to start receiving orders.',
      secondaryLabel: 'Back',
      onSecondary: widget.onBack,
      primaryLabel: 'Finish',
      primaryEnabled: _isComplete(state) && !_uploading,
      onPrimary: widget.onFinish,
      child: ListView(
        children: [
          _docCard(
            title: 'ID proof',
            status: docs.idProof,
            onTap: () => _upload(state, DocumentType.idProof),
            disabled: _uploading,
          ),
          const SizedBox(height: 10),
          _docCard(
            title: 'Driving license',
            status: docs.drivingLicense,
            onTap: () => _upload(state, DocumentType.drivingLicense),
            disabled: _uploading,
          ),
          const SizedBox(height: 10),
          _docCard(
            title: 'Vehicle RC',
            status: docs.vehicleRc,
            onTap: () => _upload(state, DocumentType.vehicleRc),
            disabled: _uploading,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.background,
                    child: Icon(Icons.timer_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verification usually completes within 24 hours.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docCard({
    required String title,
    required DocumentStatus status,
    required VoidCallback onTap,
    required bool disabled,
  }) {
    final color = switch (status) {
      DocumentStatus.missing => AppColors.danger,
      DocumentStatus.pending => const Color(0xFFF59E0B),
      DocumentStatus.verified => AppColors.success,
      DocumentStatus.rejected => AppColors.danger,
    };
    final label = switch (status) {
      DocumentStatus.missing => 'Upload',
      DocumentStatus.pending => 'Update',
      DocumentStatus.verified => 'View',
      DocumentStatus.rejected => 'Re-upload',
    };
    final statusText = switch (status) {
      DocumentStatus.missing => 'Not uploaded',
      DocumentStatus.pending => 'Pending verification',
      DocumentStatus.verified => 'Verified',
      DocumentStatus.rejected => 'Rejected',
    };

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.background,
          child: Icon(Icons.description_outlined, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(statusText),
        trailing: FilledButton.tonal(
          onPressed: disabled ? null : onTap,
          child: Text(label),
        ),
      ),
    );
  }
}

