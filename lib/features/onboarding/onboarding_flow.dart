import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_state.dart';
import '../../app/theme/app_theme.dart';
import '../../core/api/api_client.dart';

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
          Navigator.of(context).pushReplacementNamed('/under-review');
        },
      ),
    ];

    return steps[_step];
  }
}

class _OnboardingScaffold extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Widget title;
  final String subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback? onBack;
  final bool primaryEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? subtitleColor;
  final bool showHeader;
  final Widget? footer;

  const _OnboardingScaffold({
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.onBack,
    this.primaryEnabled = true,
    this.backgroundColor,
    this.textColor,
    this.subtitleColor,
    this.showHeader = true,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Colors.white;
    final text = textColor ?? const Color(0xFF0F172A);
    final sub = subtitleColor ?? const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      appBar: !showHeader 
        ? null 
        : AppBar(
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back, color: text),
            ),
            title: Text(
              'MAA SHARDA GO',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: text,
                letterSpacing: 1.2,
              ),
            ),
            centerTitle: true,
          ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(totalSteps, (index) {
                      final isActive = index == currentStep - 1;
                      return Container(
                        width: isActive ? 24 : 8,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF00E676) : text.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 32),
              ],
              title,
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: sub,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(child: child),
              if (footer != null) footer! else Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 16),
                child: Row(
                  children: [
                    if (secondaryLabel != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onSecondary,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            secondaryLabel!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: primaryEnabled ? onPrimary : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              primaryLabel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),
                  ],
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
  String _city = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  static const List<String> _cities = <String>[
    'Bhopal',
    'Indore',
    'Jabalpur',
    'Gwalior',
    'Ujjain',
    'Sagar',
    'Satna',
    'Rewa',
  ];

  Future<void> _pickCity(AppState state) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final controller = TextEditingController();
        var q = '';
        return StatefulBuilder(
          builder: (context, setInner) {
            final list = _cities
                .where((c) => c.toLowerCase().contains(q.toLowerCase().trim()))
                .toList(growable: false);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      onChanged: (v) => setInner(() => q = v),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search city',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = list[i];
                          return ListTile(
                            title: Text(c),
                            trailing: _city == c
                                ? const Icon(Icons.check, color: Color(0xFF00E676))
                                : null,
                            onTap: () => Navigator.of(context).pop(c),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (picked == null) return;
    setState(() => _city = picked);
    // Persist early so back/forward keeps value even if user exits onboarding.
    await state.updateGeneralInfo(
      name: _nameController.text.trim().isEmpty ? state.rider.profile.name : _nameController.text.trim(),
      city: picked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    if (_city.isEmpty && state.rider.profile.city.isNotEmpty) {
      _city = state.rider.profile.city;
    }
    return _OnboardingScaffold(
      currentStep: 1,
      totalSteps: 4,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Deliver with',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
          Text(
            'Maa Sharda Go',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF00E676),
              height: 1.1,
            ),
          ),
        ],
      ),
      subtitle: 'Join our community of drivers and start earning today.',
      primaryLabel: 'Next',
      primaryEnabled: _nameController.text.trim().isNotEmpty && _city.trim().isNotEmpty,
      onPrimary: () {
        state.updateGeneralInfo(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          city: _city.trim(),
        );
        widget.onNext();
      },
      child: ListView(
        children: [
          const Text(
            'Full Name',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'e.g. Rahul Sharma',
              prefixIcon: Icon(Icons.person_outline, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mobile Number',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      '+91',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: state.rider.session.phone.isEmpty
                        ? '92323 23432'
                        : state.rider.session.phone,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.verified, size: 14, color: Color(0xFF00E676)),
              SizedBox(width: 6),
              Text(
                'Verified',
                style: TextStyle(color: Color(0xFF00E676), fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Select City',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickCity(state),
            child: AbsorbPointer(
              child: TextField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: _city.isEmpty ? 'Search your city' : _city,
                  prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8)),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
                ),
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
  final _regController = TextEditingController();
  final _licController = TextEditingController();

  @override
  void dispose() {
    _regController.dispose();
    _licController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final reg = _regController.text.trim();
    final lic = _licController.text.trim();
    final regOk = reg.isNotEmpty;
    final licOk = lic.isNotEmpty;
    final canContinue = regOk && licOk;
    return _OnboardingScaffold(
      currentStep: 2,
      totalSteps: 4,
      backgroundColor: const Color(0xFF0A1410),
      textColor: Colors.white,
      subtitleColor: const Color(0xFF94A3B8),
      title: const Text(
        'Vehicle Details',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      subtitle: 'Tell us what you drive to get started.',
      primaryLabel: 'Next Step',
      onPrimary: () {
        state.updateVehicle(type: _type, number: reg, drivingLicenseNumber: lic);
        widget.onNext();
      },
      footer: Padding(
        padding: const EdgeInsets.only(bottom: 24, top: 16),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.undo, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: canContinue
                    ? () {
                        state.updateVehicle(
                          type: _type,
                          number: reg,
                          drivingLicenseNumber: lic,
                        );
                        widget.onNext();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Next Step',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      child: ListView(
        children: [
          const Text(
            'SELECT VEHICLE TYPE',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _VehicleTypeCard(
                  label: 'Cycle',
                  icon: Icons.pedal_bike,
                  selected: _type == VehicleType.cycle,
                  onTap: () => setState(() => _type = VehicleType.cycle),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VehicleTypeCard(
                  label: 'Bike /\nScooter',
                  icon: Icons.motorcycle,
                  selected: _type == VehicleType.bike,
                  onTap: () => setState(() => _type = VehicleType.bike),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VehicleTypeCard(
                  label: 'Electric',
                  icon: Icons.electric_scooter,
                  selected: _type == VehicleType.scooter,
                  onTap: () => setState(() => _type = VehicleType.scooter),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Vehicle Registration Number',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _DarkField(
            controller: _regController,
            onChanged: (_) => setState(() {}),
            hint: 'MP 04 AB 1234',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 6),
          const Text(
            'Standard Indian format (e.g. DL 01 AB 1234)',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 24),
          const Text(
            'Driving License Number',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _DarkField(
            controller: _licController,
            onChanged: (_) => setState(() {}),
            hint: 'DL-1234567890123',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00E676).withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF00E676), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please ensure your documents are valid. You will be asked to upload photos in the next step.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleTypeCard extends StatelessWidget {
  const _VehicleTypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: selected ? Colors.transparent : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF00E676) : Colors.white.withOpacity(0.05),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF00E676) : Colors.black26,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.black : Colors.white.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(icon, color: const Color(0xFF64748B), size: 20),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: VerticalDivider(color: Colors.white12, width: 1),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              ),
            ),
          ),
        ],
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
      currentStep: 3,
      totalSteps: 4,
      title: const Text('Bank details', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1)),
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
  final Map<DocumentType, DocumentStatus> _localStatuses = {};

  bool _isComplete(AppState state) => state.rider.profile.documents.mandatoryComplete;

  DocumentStatus _statusFor(DocumentType type, DocumentsState docs) {
    return _localStatuses[type] ??
        switch (type) {
          DocumentType.idProof => docs.idProof,
          DocumentType.drivingLicense => docs.drivingLicense,
          DocumentType.vehicleRc => docs.vehicleRc,
        };
  }

  static String _docKey(DocumentType type) => switch (type) {
        DocumentType.idProof => 'aadhar',
        DocumentType.drivingLicense => 'license',
        DocumentType.vehicleRc => 'rc',
      };

  Future<File?> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final path = res?.files.single.path;
    if (path == null) return null;
    return File(path);
  }

  Future<File?> _pickFromCamera() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x == null) return null;
    return File(x.path);
  }

  Future<void> _upload(AppState state, DocumentType type) async {
    final src = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Use camera'),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: const Text('Choose file'),
                onTap: () => Navigator.of(context).pop('file'),
              ),
            ],
          ),
        );
      },
    );
    if (src == null) return;
    setState(() => _uploading = true);
    try {
      final file = src == 'camera' ? await _pickFromCamera() : await _pickFile();
      if (!mounted) return;
      if (file == null) {
        setState(() => _uploading = false);
        return;
      }
      await state.uploadDocument(type: type, file: file);
      await state.setDocumentStatus(type, DocumentStatus.pending);
      if (!mounted) return;
      setState(() => _localStatuses[type] = DocumentStatus.pending);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded ${_docKey(type)}. Pending verification.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final docs = state.rider.profile.documents;
    final idStatus = _statusFor(DocumentType.idProof, docs);
    final licStatus = _statusFor(DocumentType.drivingLicense, docs);
    final rcStatus = _statusFor(DocumentType.vehicleRc, docs);
    final allUploaded = idStatus != DocumentStatus.missing &&
        licStatus != DocumentStatus.missing &&
        rcStatus != DocumentStatus.missing;
    return _OnboardingScaffold(
      currentStep: 4,
      totalSteps: 4,
      title: const Text('Documents', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1)),
      subtitle: 'Upload required documents to start receiving orders.',
      secondaryLabel: 'Back',
      onSecondary: widget.onBack,
      primaryLabel: 'Finish',
      primaryEnabled: allUploaded && !_uploading,
      onPrimary: () {
        widget.onFinish();
      },
      child: ListView(
        children: [
          _docCard(
            title: 'ID proof',
            status: idStatus,
            onTap: () => _upload(state, DocumentType.idProof),
            disabled: _uploading,
          ),
          const SizedBox(height: 10),
          _docCard(
            title: 'Driving license',
            status: licStatus,
            onTap: () => _upload(state, DocumentType.drivingLicense),
            disabled: _uploading,
          ),
          const SizedBox(height: 10),
          _docCard(
            title: 'Vehicle RC',
            status: rcStatus,
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


class ApplicationReviewScreen extends StatelessWidget {
  const ApplicationReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                'MAA SHARDA GO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    state.rider.verification == VerificationStatus.rejected
                        ? Icons.cancel
                        : Icons.check_circle,
                    color: state.rider.verification == VerificationStatus.rejected
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF00E676),
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                state.rider.verification == VerificationStatus.rejected
                    ? 'Application Rejected'
                    : 'Application Under Review',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  state.rider.verification == VerificationStatus.rejected
                      ? 'Your application was rejected. Please re-upload documents or contact support.'
                      : 'Thank you for registering with us. We will verify your documents (Aadhar, License, RC) and get back to you shortly.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Review Process',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F9EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _TimelineItem(
                      title: 'Submission Received',
                      subtitle: 'Your application has been logged.',
                      isDone: true,
                    ),
                    _TimelineItem(
                      title: 'Document Verification',
                      subtitle: 'Checking Aadhar & License details.',
                      isDone: state.rider.profile.documents.mandatoryComplete,
                      isActive: !state.rider.profile.documents.mandatoryComplete,
                    ),
                    _TimelineItem(
                      title: 'Approval',
                      subtitle: 'Final activation for driving.',
                      isDone: state.rider.verification == VerificationStatus.verified,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F9EB).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00E676).withOpacity(0.1),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time, color: Color(0xFF00E676)),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESTIMATED WAIT',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '24-48 Hours',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await state.login(phone: state.rider.session.phone);
                    } catch (_) {}
                    if (!context.mounted) return;
                    if (state.rider.verification == VerificationStatus.verified) {
                      Navigator.of(context).pushReplacementNamed('/home');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Still under review')),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    state.logout();
                    await ApiClient().clearSession();
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacementNamed('/auth');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.subtitle,
    this.isDone = false,
    this.isActive = false,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone 
                      ? const Color(0xFF00E676) 
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone || isActive 
                        ? const Color(0xFF00E676) 
                        : const Color(0xFFCBD5E1),
                    width: isActive ? 6 : 2,
                  ),
                ),
                child: isDone 
                    ? const Icon(Icons.check, color: Colors.white, size: 14) 
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDone || isActive 
                          ? const Color(0xFF1E293B) 
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
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
