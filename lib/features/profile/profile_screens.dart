import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/app_state.dart';
import '../../core/api/api_client.dart';
import 'dart:convert';
import '../../ui/primary_button.dart';

class GeneralInfoScreen extends StatefulWidget {
  const GeneralInfoScreen({super.key});

  @override
  State<GeneralInfoScreen> createState() => _GeneralInfoScreenState();
}

class _GeneralInfoScreenState extends State<GeneralInfoScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final state = AppStateScope.of(context);
    await state.updateGeneralInfo(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = AppStateScope.of(context);
      if (_nameController.text.isEmpty) {
        _nameController.text = s.rider.profile.name;
      }
      if (_phoneController.text.isEmpty) {
        _phoneController.text = s.rider.session.phone;
      }
      if (_emailController.text.isEmpty) {
        _emailController.text = s.rider.profile.email;
      }
      if (_addressController.text.isEmpty) {
        _addressController.text = s.rider.profile.address;
      }
    });
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('General info')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basic', style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        labelText: 'Full name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_android),
                        labelText: 'Phone',
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Address', style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined),
                        labelText: 'Current address',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Save',
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  Future<String?> _promptForUrl(BuildContext context, String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  String _docKey(String displayName) {
    final key = displayName.toLowerCase();
    if (key.contains('aadhar')) return 'aadhar';
    if (key.contains('pan')) return 'pan';
    if (key.contains('driving')) return 'license';
    if (key.contains('vehicle')) return 'rc';
    return 'aadhar';
  }

  DocumentType _docType(String key) {
    switch (key) {
      case 'aadhar':
        return DocumentType.idProof;
      case 'license':
        return DocumentType.drivingLicense;
      case 'rc':
        return DocumentType.vehicleRc;
      default:
        return DocumentType.idProof;
    }
  }

  void _showUploadSheet(BuildContext context, String docName) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload $docName',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _SheetAction(
                  icon: Icons.photo_camera_outlined,
                  title: 'Add image URL',
                  onTap: () async {
                    Navigator.of(context).pop();
                    final url = await _promptForUrl(
                      context,
                      'Paste $docName image URL',
                    );
                    if (url == null || url.trim().isEmpty) return;
                    final docKey = _docKey(docName);
                    await ApiClient().post(
                      '/v1/delivery/profile/documents',
                      body: {
                        'doc': docKey,
                        'status': 'pending',
                        'url': url.trim(),
                      },
                    );
                    final state = AppStateScope.of(context);
                    await state.setDocumentStatus(
                      _docType(docKey),
                      DocumentStatus.pending,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Document submitted')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SheetAction(
                  icon: Icons.photo_library_outlined,
                  title: 'Mark as verified',
                  onTap: () async {
                    Navigator.of(context).pop();
                    final docKey = _docKey(docName);
                    await ApiClient().post(
                      '/v1/delivery/profile/documents',
                      body: {'doc': docKey, 'status': 'verified'},
                    );
                    final state = AppStateScope.of(context);
                    await state.setDocumentStatus(
                      _docType(docKey),
                      DocumentStatus.verified,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Document marked verified')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = const <_DocItem>[
      _DocItem(name: 'Aadhar Card', status: _DocStatus.verified),
      _DocItem(name: 'PAN Card', status: _DocStatus.verified),
      _DocItem(name: 'Driving License', status: _DocStatus.pending),
      _DocItem(name: 'Vehicle RC', status: _DocStatus.missing),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF64748B)),
        ),
        title: const Text(
          'Verify Identity',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
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
              const SizedBox(height: 24),
              const Text(
                'STEP 2 OF 3',
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(3, (index) {
                  final isActive = index < 2;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF00E676)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              const Text(
                'Upload Documents',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please upload clear photos of your original documents for verification.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final d = items[index];
                    return InkWell(
                      onTap: () => _showUploadSheet(context, d.name),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Icon(d.icon, color: d.color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    d.statusLabel,
                                    style: TextStyle(
                                      color: d.color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0xFF00E676).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final _numberController = TextEditingController();
  final _licenseController = TextEditingController();
  VehicleType _type = VehicleType.bike;
  bool _saving = false;

  @override
  void dispose() {
    _numberController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final state = AppStateScope.of(context);
    await state.updateVehicle(
      type: _type,
      number: _numberController.text.trim(),
      drivingLicenseNumber: _licenseController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Vehicle details saved')));
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = AppStateScope.of(context);
      if (_numberController.text.isEmpty) {
        _numberController.text = s.rider.profile.vehicle.number;
      }
      if (_licenseController.text.isEmpty) {
        _licenseController.text = s.rider.profile.drivingLicenseNumber;
      }
      if (_type == VehicleType.bike &&
          s.rider.profile.vehicle.type != VehicleType.unknown) {
        _type = s.rider.profile.vehicle.type;
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<VehicleType>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle type',
                        prefixIcon: Icon(Icons.two_wheeler_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: VehicleType.bike,
                          child: Text('Bike'),
                        ),
                        DropdownMenuItem(
                          value: VehicleType.scooter,
                          child: Text('Scooter'),
                        ),
                        DropdownMenuItem(
                          value: VehicleType.cycle,
                          child: Text('Cycle'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _type = v ?? VehicleType.bike),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _numberController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                        labelText: 'Vehicle number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _licenseController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.badge_outlined),
                        labelText: 'Driving license number',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Save',
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _holderController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _holderController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final state = AppStateScope.of(context);
    await state.updateBank(
      holder: _holderController.text.trim(),
      account: _accountController.text.trim(),
      ifsc: _ifscController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bank details saved')));
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = AppStateScope.of(context);
      if (_holderController.text.isEmpty) {
        _holderController.text = s.rider.profile.bank.holderName;
      }
      if (_accountController.text.isEmpty) {
        _accountController.text = s.rider.profile.bank.accountNumber;
      }
      if (_ifscController.text.isEmpty) {
        _ifscController.text = s.rider.profile.bank.ifsc;
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Bank details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _holderController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        labelText: 'Account holder name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _accountController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.account_balance_outlined),
                        labelText: 'Account number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ifscController,
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
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Save',
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _orderAlerts = true;
  bool _sound = true;
  bool _vibrate = true;
  bool _locationAlways = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final res = await ApiClient().get('/v1/delivery/settings');
      final s = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _orderAlerts = s['orderAlerts'] == true;
        _sound = s['sound'] == true;
        _vibrate = s['vibration'] == true;
        _language = (s['language']?.toString() ?? 'en') == 'hi'
            ? 'Hindi'
            : 'English';
      });
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _orderAlerts,
                    onChanged: (v) async {
                      setState(() => _orderAlerts = v);
                      await ApiClient().put(
                        '/v1/delivery/settings',
                        body: {'orderAlerts': v},
                      );
                    },
                    title: const Text('Order alerts'),
                    subtitle: const Text('Get notified for new requests'),
                    secondary: const CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _sound,
                    onChanged: (v) async {
                      setState(() => _sound = v);
                      await ApiClient().put(
                        '/v1/delivery/settings',
                        body: {'sound': v},
                      );
                    },
                    title: const Text('Sound'),
                    subtitle: const Text('Play sound on new requests'),
                    secondary: const CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(
                        Icons.volume_up_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _vibrate,
                    onChanged: (v) async {
                      setState(() => _vibrate = v);
                      await ApiClient().put(
                        '/v1/delivery/settings',
                        body: {'vibration': v},
                      );
                    },
                    title: const Text('Vibration'),
                    subtitle: const Text('Vibrate on new requests'),
                    secondary: const CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(
                        Icons.vibration_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _locationAlways,
                    onChanged: (v) => setState(() => _locationAlways = v),
                    title: const Text('Location access'),
                    subtitle: const Text('Allow location while using the app'),
                    secondary: const CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(Icons.my_location, color: AppColors.primary),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    onTap: () async {
                      final result = await showModalBottomSheet<String>(
                        context: context,
                        showDragHandle: true,
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 6),
                                _RadioTile(
                                  label: 'English',
                                  groupValue: _language,
                                  onChanged: (v) =>
                                      Navigator.of(context).pop(v),
                                ),
                                _RadioTile(
                                  label: 'Hindi',
                                  groupValue: _language,
                                  onChanged: (v) =>
                                      Navigator.of(context).pop(v),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          );
                        },
                      );
                      if (result == null) return;
                      setState(() => _language = result);
                    },
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(
                        Icons.language_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    title: const Text('Language'),
                    subtitle: Text(_language),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact support',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _SheetAction(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat with us',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 8),
                _SheetAction(
                  icon: Icons.call_outlined,
                  title: 'Call support',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 8),
                _SheetAction(
                  icon: Icons.email_outlined,
                  title: 'Email us',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & support'),
        actions: [
          IconButton(
            onPressed: () => _showContactSheet(context),
            icon: const Icon(Icons.headset_mic_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(
                        Icons.support_agent,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need help?',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chat or call support for quick resolution.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => _showContactSheet(context),
                      child: const Text('Contact'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: const [
                  _FaqTile(
                    q: 'How do I go online?',
                    a: 'Turn on Online from the Home tab. Complete documents if required.',
                  ),
                  Divider(height: 1),
                  _FaqTile(
                    q: 'How is payout calculated?',
                    a: 'Payout depends on distance, demand, and incentives.',
                  ),
                  Divider(height: 1),
                  _FaqTile(
                    q: 'What if the customer is unreachable?',
                    a: 'Use in-app call. If still unreachable, contact support.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Policies')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Terms', style: textTheme.titleMedium),
                    const SizedBox(height: 10),
                    const Text(
                      'Use this app only for delivery operations. Follow safety rules and local laws. '
                      'Do not share OTPs or customer details.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Privacy', style: textTheme.titleMedium),
                    const SizedBox(height: 10),
                    const Text(
                      'We collect location and delivery activity to assign orders and improve service. '
                      'Your data is used to operate the rider platform.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Cancellation', style: textTheme.titleMedium),
                    const SizedBox(height: 10),
                    const Text(
                      'Frequent cancellations may affect incentives. If you face an issue, contact support.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const SafeArea(
        child: Center(
          child: Text(
            'Coming soon',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.q, required this.a});

  final String q;
  final String a;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      collapsedShape: const RoundedRectangleBorder(),
      shape: const RoundedRectangleBorder(),
      title: Text(q, style: const TextStyle(fontWeight: FontWeight.w800)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(
          a,
          style: const TextStyle(color: AppColors.mutedText, height: 1.35),
        ),
      ],
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.background,
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({
    required this.label,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == label;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppColors.primary : AppColors.mutedText,
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      onTap: () => onChanged(label),
    );
  }
}

enum _DocStatus { verified, pending, missing }

class _DocItem {
  const _DocItem({required this.name, required this.status});

  final String name;
  final _DocStatus status;

  String get statusLabel {
    return switch (status) {
      _DocStatus.verified => 'Verified',
      _DocStatus.pending => 'Pending verification',
      _DocStatus.missing => 'Not uploaded',
    };
  }

  String get ctaLabel {
    return switch (status) {
      _DocStatus.verified => 'View',
      _DocStatus.pending => 'Update',
      _DocStatus.missing => 'Upload',
    };
  }

  IconData get icon {
    return switch (status) {
      _DocStatus.verified => Icons.verified_outlined,
      _DocStatus.pending => Icons.hourglass_bottom_outlined,
      _DocStatus.missing => Icons.upload_file_outlined,
    };
  }

  Color get color {
    return switch (status) {
      _DocStatus.verified => AppColors.success,
      _DocStatus.pending => const Color(0xFFF59E0B),
      _DocStatus.missing => AppColors.danger,
    };
  }
}
