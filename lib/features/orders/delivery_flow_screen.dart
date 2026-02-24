import 'package:flutter/material.dart';
import 'dart:async';

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
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery')),
        body: const SafeArea(
          child: Center(
            child: Text(
              'Order not found',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
    }

    final progress = order.progress;
    final steps = _steps(progress);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id}'),
        actions: [
          IconButton(
            onPressed: () => _showIssueSheet(context, state, order),
            icon: const Icon(Icons.report_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _OrderSummaryCard(order: order),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...steps.map((s) => _StepRow(step: s)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppColors.outline),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loading
                        ? null
                        : () => _showContactSheet(context, 'Customer'),
                    child: const Text('Customer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppColors.outline),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loading
                        ? null
                        : () => _showContactSheet(context, 'Restaurant'),
                    child: const Text('Restaurant'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _actionSection(context, state, order),
          ],
        ),
      ),
    );
  }

  Widget _actionSection(
    BuildContext context,
    AppState state,
    ActiveOrder order,
  ) {
    return switch (order.progress) {
      DeliveryProgress.navigateRestaurant => PrimaryButton(
        label: 'Reached restaurant',
        isLoading: _loading,
        onPressed: _loading
            ? null
            : () => _run(() async {
                state.markReachedRestaurant(order.id);
                return true;
              }),
      ),
      DeliveryProgress.reachedRestaurant => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pickup confirmation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pickupOtpController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  hintText: 'Enter restaurant OTP',
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Confirm pickup',
                isLoading: _loading,
                onPressed:
                    _pickupOtpController.text.trim().length == 4 && !_loading
                    ? () => _run(
                        () => state.confirmPickupOtp(
                          order.id,
                          _pickupOtpController.text,
                        ),
                        error: 'Wrong OTP',
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      DeliveryProgress.pickedUp => PrimaryButton(
        label: 'Arrived at customer',
        isLoading: _loading,
        onPressed: _loading
            ? null
            : () => _run(() async {
                state.markArrivedCustomer(order.id);
                return true;
              }),
      ),
      DeliveryProgress.navigateCustomer => PrimaryButton(
        label: 'Arrived at customer',
        isLoading: _loading,
        onPressed: _loading
            ? null
            : () => _run(() async {
                state.markArrivedCustomer(order.id);
                return true;
              }),
      ),
      DeliveryProgress.arrivedCustomer => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery confirmation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (order.cashToCollect > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Cash to collect',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '₹ ${order.cashToCollect}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _deliveryOtpController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  hintText: 'Enter customer OTP',
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Mark delivered',
                isLoading: _loading,
                onPressed:
                    _deliveryOtpController.text.trim().length == 4 && !_loading
                    ? () => _run(
                        () => state.confirmDeliveryOtp(
                          order.id,
                          _deliveryOtpController.text,
                        ),
                        error: 'Wrong OTP',
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      DeliveryProgress.delivered => const SizedBox.shrink(),
    };
  }

  List<_DeliveryStep> _steps(DeliveryProgress current) {
    final steps = <_DeliveryStep>[
      _DeliveryStep(
        title: 'Navigate to restaurant',
        subtitle: 'Follow the route and reach pickup point',
        done: current.index >= DeliveryProgress.reachedRestaurant.index,
      ),
      _DeliveryStep(
        title: 'Reached restaurant',
        subtitle: 'Confirm pickup and collect order',
        done: current.index >= DeliveryProgress.pickedUp.index,
      ),
      _DeliveryStep(
        title: 'Navigate to customer',
        subtitle: 'Start delivery after pickup',
        done: current.index >= DeliveryProgress.arrivedCustomer.index,
      ),
      _DeliveryStep(
        title: 'Delivered',
        subtitle: 'Confirm delivery with OTP',
        done: current.index >= DeliveryProgress.delivered.index,
      ),
    ];
    return steps;
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final ActiveOrder order;

  @override
  Widget build(BuildContext context) {
    final r = order.request;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.restaurantName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Text(
                    '${r.totalDistanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AddressRow(
              icon: Icons.storefront_outlined,
              title: 'Pickup',
              value: r.restaurantArea,
            ),
            const SizedBox(height: 10),
            _AddressRow(
              icon: Icons.home_outlined,
              title: 'Drop',
              value: r.dropArea,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Pill(
                    icon: Icons.timer_outlined,
                    label: '${r.etaMin} min',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Pill(
                    icon: Icons.payments_outlined,
                    label: '₹ ${order.fareBreakdown.total.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final _DeliveryStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: step.done ? AppColors.success : AppColors.outline,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: step.done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
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

class _DeliveryStep {
  const _DeliveryStep({
    required this.title,
    required this.subtitle,
    required this.done,
  });

  final String title;
  final String subtitle;
  final bool done;
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
