import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_state.dart';
import '../../app/theme/app_theme.dart';
import '../../ui/primary_button.dart';

class DeliveryFlowScreen extends StatefulWidget {
  const DeliveryFlowScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<DeliveryFlowScreen> createState() => _DeliveryFlowScreenState();
}

class _DeliveryFlowScreenState extends State<DeliveryFlowScreen> {
  final _pickupOtpController = TextEditingController();
  final _deliveryOtpController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _pickupOtpController.dispose();
    _deliveryOtpController.dispose();
    super.dispose();
  }

  Future<void> _run(FutureOr<bool> Function() action, {String? error}) async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final ok = await action();
    setState(() => _loading = false);
    if (!ok && error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _openMaps(ActiveOrder order) async {
    final dest = Uri.encodeComponent(
      order.progress == DeliveryProgress.navigateRestaurant || order.progress == DeliveryProgress.reachedRestaurant
          ? order.request.restaurantName
          : order.request.dropArea,
    );
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$dest');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showContactSheet(BuildContext context, String title) {
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
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _SheetAction(
                  icon: Icons.call_outlined,
                  title: 'Call',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 8),
                _SheetAction(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showIssueSheet(
    BuildContext context,
    AppState state,
    ActiveOrder order,
  ) {
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
                  'Report an issue',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _SheetAction(
                  icon: Icons.location_searching_outlined,
                  title: 'Can’t find address',
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Issue reported')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SheetAction(
                  icon: Icons.timer_outlined,
                  title: 'Restaurant delay',
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Issue reported')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SheetAction(
                  icon: Icons.warning_amber_outlined,
                  title: 'Customer unreachable',
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Issue reported')),
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
    final state = AppStateScope.of(context);
    final order = state.orders.findActive(widget.orderId);
    if (order == null) return const Scaffold(body: Center(child: Text('Order not found')));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Simulated Map Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF1F5F9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 64, color: Colors.blue.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    const Text('Pickup Location Map', style: TextStyle(color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ),
          ),
          
          // Top Navigation Overlay
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 24),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _openMaps(order),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.near_me, color: Color(0xFF00E676), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Navigate',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),

          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF111827), // Dark grey/black
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        order.request.restaurantName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.verified, color: Color(0xFF00E676), size: 18),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '#${order.id} • Pick up by 12:45 PM',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _RoundAction(icon: Icons.call, color: Colors.white.withOpacity(0.1), iconColor: Colors.white),
                                const SizedBox(width: 12),
                                _RoundAction(icon: Icons.chat_bubble, color: Colors.white.withOpacity(0.1), iconColor: Colors.white),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'ITEMS TO PICK UP',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PickupItem(name: 'Chicken Dum Biryani', quantity: '1', crossed: true),
                        _PickupItem(name: 'Butter Naan', quantity: '2'),
                        _PickupItem(name: 'Special Mutton Curry', quantity: '1'),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Verify all items before leaving. Ensure packaging is intact.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Builder(
                          builder: (context) {
                            switch (order.progress) {
                              case DeliveryProgress.navigateRestaurant:
                                return SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : () async {
                                      await state.markReachedRestaurant(order.id);
                                      if (!mounted) return;
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Reached Restaurant',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                );
                              case DeliveryProgress.reachedRestaurant:
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Enter Pickup OTP',
                                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _pickupOtpController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 4,
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        hintText: '4-digit OTP',
                                        filled: true,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : () async {
                                          await _run(() async {
                                            final ok = await state.confirmPickupOtp(order.id, _pickupOtpController.text.trim());
                                            if (ok) setState(() {});
                                            return ok;
                                          }, error: 'Invalid OTP');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFEF4444),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: const Text('Confirm Pickup'),
                                      ),
                                    ),
                                  ],
                                );
                              case DeliveryProgress.pickedUp:
                                return SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : () async {
                                      await state.markArrivedCustomer(order.id);
                                      if (!mounted) return;
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Arrived at Customer',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                );
                              case DeliveryProgress.arrivedCustomer:
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Enter Delivery OTP',
                                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _deliveryOtpController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 4,
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        hintText: '4-digit OTP',
                                        filled: true,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : () async {
                                          await _run(() async {
                                            final ok = await state.confirmDeliveryOtp(order.id, _deliveryOtpController.text.trim());
                                            if (ok && mounted) Navigator.of(context).pop();
                                            return ok;
                                          }, error: 'Invalid OTP');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFEF4444),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: const Text('Confirm Delivery'),
                                      ),
                                    ),
                                  ],
                                );
                              case DeliveryProgress.navigateCustomer:
                              case DeliveryProgress.delivered:
                                return SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                );
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
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

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.color, required this.iconColor});
  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _PickupItem extends StatefulWidget {
  const _PickupItem({required this.name, required this.quantity, this.crossed = false});
  final String name;
  final String quantity;
  final bool crossed;

  @override
  State<_PickupItem> createState() => _PickupItemState();
}

class _PickupItemState extends State<_PickupItem> {
  late bool _checked = widget.crossed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => setState(() => _checked = !_checked),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _checked ? const Color(0xFF00E676) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _checked ? const Color(0xFF00E676) : Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: _checked 
                  ? const Icon(Icons.check, size: 16, color: Colors.black) 
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '${widget.quantity} x ${widget.name}',
                style: TextStyle(
                  color: _checked ? Colors.white.withOpacity(0.3) : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: _checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideToComplete extends StatefulWidget {
  const _SlideToComplete({required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<_SlideToComplete> createState() => _SlideToCompleteState();
}

class _SlideToCompleteState extends State<_SlideToComplete> {
  double _position = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbSize = 54.0;
        final maxPosition = width - thumbSize - 6;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.all(3),
          child: Stack(
            children: [
              const Center(
                child: Text(
                  'Slide to complete delivery',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                left: _position,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _position = (_position + details.delta.dx).clamp(0, maxPosition);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_position >= maxPosition * 0.8) {
                      widget.onComplete();
                    } else {
                      setState(() {
                        _position = 0;
                      });
                    }
                  },
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
