import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../ui/primary_button.dart';

class GeneralInfoScreen extends StatefulWidget {
  const GeneralInfoScreen({super.key});

  @override
  State<GeneralInfoScreen> createState() => _GeneralInfoScreenState();
}

class _GeneralInfoScreenState extends State<GeneralInfoScreen> {
  final _nameController = TextEditingController(text: 'Rider Name');
  final _phoneController = TextEditingController(text: '+91 98xxxxxx10');
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
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
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
                  title: 'Use camera',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 8),
                _SheetAction(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from gallery',
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
    final items = const <_DocItem>[
      _DocItem(name: 'Driving license', status: _DocStatus.verified),
      _DocItem(name: 'RC', status: _DocStatus.pending),
      _DocItem(name: 'Insurance', status: _DocStatus.missing),
      _DocItem(name: 'PAN', status: _DocStatus.verified),
      _DocItem(name: 'Aadhaar', status: _DocStatus.pending),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
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
                    Text(
                      'Complete your documents to go online.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const LinearProgressIndicator(
                        value: 0.6,
                        minHeight: 8,
                        backgroundColor: AppColors.outline,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(d.icon, color: d.color),
                    ),
                    title: Text(
                      d.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(d.statusLabel),
                    trailing: FilledButton.tonal(
                      onPressed: () => _showUploadSheet(context, d.name),
                      child: Text(d.ctaLabel),
                    ),
                  ),
                ),
              ),
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
                    onChanged: (v) => setState(() => _orderAlerts = v),
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
                    onChanged: (v) => setState(() => _sound = v),
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
                    onChanged: (v) => setState(() => _vibrate = v),
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
