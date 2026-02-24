import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme/app_theme.dart';
import '../orders/delivery_flow_screen.dart';
import '../profile/profile_screens.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final pages = <Widget>[
      _HomeTab(
        isOnline: state.rider.isOnline,
        onToggleOnline: (v) => state.setOnline(v),
        onSimulateOrder: () => state.simulateIncomingOrder(),
      ),
      const _OrdersTab(),
      const _EarningsTab(),
      _ProfileTab(onNavigateToTab: (i) => setState(() => _index = i)),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.isOnline,
    required this.onToggleOnline,
    required this.onSimulateOrder,
  });

  final bool isOnline;
  final ValueChanged<bool> onToggleOnline;
  final VoidCallback onSimulateOrder;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekTripCount = state.earnings.trips
        .where(
          (t) => t.createdAt.isAfter(
            DateTime(weekStart.year, weekStart.month, weekStart.day),
          ),
        )
        .length;
    const incentiveTarget = 12;
    final incentiveProgress = (weekTripCount / incentiveTarget).clamp(0, 1);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=rider'),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                   Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Switch(
                value: isOnline,
                onChanged: onToggleOnline,
                activeColor: const Color(0xFF00E676),
                activeTrackColor: const Color(0xFFEEF9F1),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Today',
                    value: '₹ ${state.earnings.todayTotal.toStringAsFixed(0)}',
                    subtitle: 'Earnings',
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Active',
                    value: '${state.orders.active.length}',
                    subtitle: 'Orders',
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: _MapCard(isOnline: isOnline)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Incentives', style: textTheme.titleMedium),
                        const Spacer(),
                        Text(
                          '$weekTripCount/$incentiveTarget trips',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: incentiveProgress.toDouble(),
                        minHeight: 8,
                        backgroundColor: AppColors.outline,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Complete more trips this week to unlock incentives.',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF1F2), Color(0xFFFFFFFF)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.outline,
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.local_fire_department_outlined,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Heat map',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Emergency SOS'),
                                            content: const Text(
                                              'Emergency contacts and live location sharing will be enabled here.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: const Text('Close'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.sos_outlined),
                                    label: const Text('SOS'),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                'High-demand areas',
                                style: textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Map overlay will be added with Google Maps.',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text('New requests', style: textTheme.titleMedium),
                const Spacer(),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: isOnline
              ? Builder(
                  builder: (context) {
                    final requests = state.orders.requests;
                    if (requests.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: _EmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'No requests',
                          subtitle: 'New order requests will appear here.',
                        ),
                      );
                    }
                    return SliverList.separated(
                      itemCount: requests.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _OrderRequestCard(order: requests[i]),
                    );
                  },
                )
              : const SliverToBoxAdapter(
                  child: _EmptyState(
                    icon: Icons.do_not_disturb_alt_outlined,
                    title: 'You are offline',
                    subtitle: 'Go online to start receiving delivery requests.',
                  ),
                ),
        ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = AppStateScope.of(context);
    final active = state.orders.active;
    final history = state.orders.history;
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Active', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          if (active.isEmpty)
            const _EmptyState(
              icon: Icons.directions_bike_outlined,
              title: 'No active orders',
              subtitle: 'Accept a request to start a delivery.',
            )
          else
            ...active.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderTile(
                  title: 'Pickup: ${o.request.restaurantName}',
                  subtitle: 'Drop: ${o.request.dropArea}',
                  trailing: _progressLabel(o.progress),
                  icon: Icons.directions_bike,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DeliveryFlowScreen(orderId: o.id),
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text('History', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const _EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No history yet',
              subtitle: 'Completed and rejected orders will show here.',
            )
          else
            ...history.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderTile(
                  title: 'Order #${h.orderId} · ${h.restaurantName}',
                  subtitle: '₹ ${h.earning.toStringAsFixed(0)} · ${h.dropArea}',
                  trailing: _timeLabel(h.completedAt),
                  icon: h.status == OrderStatus.delivered
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  onTap: () {
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
                                  'Order #${h.orderId}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                _KeyValueRow(
                                  label: 'Status',
                                  value: h.status.name,
                                ),
                                const SizedBox(height: 10),
                                _KeyValueRow(
                                  label: 'Earning',
                                  value: '₹ ${h.earning.toStringAsFixed(0)}',
                                ),
                                const SizedBox(height: 10),
                                _KeyValueRow(
                                  label: 'Cash collected',
                                  value: '₹ ${h.cashCollected}',
                                ),
                                if (h.note.trim().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _KeyValueRow(label: 'Note', value: h.note),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _progressLabel(DeliveryProgress p) {
    return switch (p) {
      DeliveryProgress.navigateRestaurant => 'To restaurant',
      DeliveryProgress.reachedRestaurant => 'At restaurant',
      DeliveryProgress.pickedUp => 'Picked up',
      DeliveryProgress.navigateCustomer => 'To customer',
      DeliveryProgress.arrivedCustomer => 'At customer',
      DeliveryProgress.delivered => 'Delivered',
    };
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }
}

class _EarningsTab extends StatelessWidget {
  const _EarningsTab();

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0C140E), // Very dark green background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        title: Column(
          children: const [
            Text(
              'Earnings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              'Nov 13 - Nov 19 ⌄',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [
          Icon(Icons.help_outline, color: Colors.white),
          SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'AVAILABLE BALANCE',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              '\$1,240.50',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text(
                'Cash Out Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF162018),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Weekly Earnings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Mon - Sun',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+12%',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                  ].map((day) {
                    final isToday = day == 'Fri';
                    return Column(
                      children: [
                        Container(
                          width: 8,
                          height: day == 'Wed' ? 80 : 40,
                          decoration: BoxDecoration(
                            color: isToday ? const Color(0xFF00E676) : const Color(0xFF2D3C2F),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day,
                          style: TextStyle(
                            color: isToday ? const Color(0xFF00E676) : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Today\'s Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _breakdownGrid(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Recent Trips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'See All',
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._mockTrips(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _breakdownGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _breakdownCard('Base Pay', '\$85.00', Icons.local_shipping_outlined, const Color(0xFF3B82F6)),
        _breakdownCard('Tips', '\$42.50', Icons.favorite_border, const Color(0xFFA855F7)),
        _breakdownCard('Incentives', '\$15.00', Icons.local_fire_department_outlined, const Color(0xFFF97316)),
        _breakdownCard('Total Today', '\$142.50', Icons.account_balance_wallet_outlined, const Color(0xFF00E676), isTotal: true),
      ],
    );
  }

  Widget _breakdownCard(String label, String value, IconData icon, Color color, {bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162018),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? const Color(0xFF00E676) : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _mockTrips() {
    return [
      _tripTile('Burger King', '2.4 mi • 2:30 PM', '+\$12.50', Icons.fastfood),
      _tripTile('Pizza Hut', '5.1 mi • 1:15 PM', '+\$18.25', Icons.local_pizza),
      _tripTile('Noodle House', '1.2 mi • 12:45 PM', '+\$9.50', Icons.ramen_dining),
    ];
  }

  Widget _tripTile(String title, String subtitle, String price, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162018),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF0C140E),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF00E676), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(color: Color(0xFF00E676), fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m';
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.onNavigateToTab});

  final ValueChanged<int> onNavigateToTab;

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('You will be signed out from this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    if (!context.mounted) return;
    AppStateScope.of(context).logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text('Profile'),
            actions: [
              IconButton(
                onPressed: () => _push(context, const HelpSupportScreen()),
                icon: const Icon(Icons.help_outline),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE23744), Color(0xFFB91C1C)],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ProfileSummaryCard(),
                  const SizedBox(height: 14),
                  _ProfileQuickActions(
                    onOpenDocuments: () =>
                        _push(context, const DocumentsScreen()),
                    onOpenEarnings: () => onNavigateToTab(2),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        _ProfileTile(
                          icon: Icons.person_outline,
                          title: 'General info',
                          subtitle: 'Name, phone, address',
                          onTap: () =>
                              _push(context, const GeneralInfoScreen()),
                        ),
                        const Divider(height: 1),
                        _ProfileTile(
                          icon: Icons.two_wheeler_outlined,
                          title: 'Vehicle details',
                          subtitle: 'Bike, RC, insurance',
                          onTap: () => _push(
                            context,
                            const PlaceholderScreen(title: 'Vehicle details'),
                          ),
                        ),
                        const Divider(height: 1),
                        _ProfileTile(
                          icon: Icons.account_balance_outlined,
                          title: 'Bank details',
                          subtitle: 'Payout account',
                          onTap: () => _push(
                            context,
                            const PlaceholderScreen(title: 'Bank details'),
                          ),
                        ),
                        const Divider(height: 1),
                        _ProfileTile(
                          icon: Icons.badge_outlined,
                          title: 'Documents',
                          subtitle: 'Verify & update',
                          onTap: () => _push(context, const DocumentsScreen()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        _ProfileTile(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Order alerts & sounds',
                          onTap: () => _push(context, const SettingsScreen()),
                        ),
                        const Divider(height: 1),
                        _ProfileTile(
                          icon: Icons.language_outlined,
                          title: 'Language',
                          subtitle: 'English',
                          onTap: () => _push(context, const SettingsScreen()),
                        ),
                        const Divider(height: 1),
                        _ProfileTile(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          subtitle: 'App preferences',
                          onTap: () => _push(context, const SettingsScreen()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Support',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        _ProfileTile(
                          icon: Icons.headset_mic_outlined,
                          title: 'Help & support',
                          subtitle: 'FAQs and chat',
                          onTap: () =>
                              _push(context, const HelpSupportScreen()),
                        ),
                        const Divider(height: 1),
                        _ProfileTile(
                          icon: Icons.policy_outlined,
                          title: 'Policies',
                          subtitle: 'Terms & privacy',
                          onTap: () => _push(context, const PoliciesScreen()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Column(
                      children: [
                        _ProfileTile(
                          icon: Icons.logout,
                          title: 'Logout',
                          subtitle: 'Sign out from this device',
                          isDestructive: true,
                          onTap: () => _confirmLogout(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'App version 1.0.0',
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

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = isDestructive ? AppColors.danger : AppColors.primary;
    final titleColor = isDestructive ? AppColors.danger : AppColors.text;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.background,
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: titleColor),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard();

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final profile = state.rider.profile;
    final textTheme = Theme.of(context).textTheme;
    final name = profile.name.trim().isEmpty ? 'Rider' : profile.name.trim();
    final phone = state.rider.session.phone.trim().isEmpty
        ? 'Phone'
        : state.rider.session.phone.trim();
    final vehicleLabel = profile.vehicle.type == VehicleType.unknown
        ? 'Vehicle'
        : profile.vehicle.type.name;
    final verificationLabel = switch (state.rider.verification) {
      VerificationStatus.pending => 'Pending',
      VerificationStatus.inReview => 'In review',
      VerificationStatus.verified => 'Verified',
      VerificationStatus.rejected => 'Rejected',
    };
    final completionDone = [
      profile.name.trim().isNotEmpty,
      profile.address.trim().isNotEmpty,
      profile.vehicle.isComplete,
      profile.bank.isComplete,
      profile.documents.mandatoryComplete,
    ].where((v) => v).length;
    final completionTotal = 5;
    final completion = completionDone / completionTotal;
    final completionPct = (completion * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(phone, style: textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
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
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  state.rider.metrics.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$vehicleLabel · $verificationLabel',
                              style: textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GeneralInfoScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile completion',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$completionPct%',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: completion,
                minHeight: 8,
                backgroundColor: AppColors.outline,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileQuickActions extends StatelessWidget {
  const _ProfileQuickActions({
    required this.onOpenEarnings,
    required this.onOpenDocuments,
  });

  final VoidCallback onOpenEarnings;
  final VoidCallback onOpenDocuments;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.receipt_long_outlined,
            title: 'Earnings',
            subtitle: 'This week',
            onTap: onOpenEarnings,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.badge_outlined,
            title: 'Documents',
            subtitle: 'Check status',
            onTap: onOpenDocuments,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.background,
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = value ? AppColors.success : AppColors.mutedText;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              value ? 'Online' : 'Offline',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.background,
                  child: Icon(icon, color: AppColors.primary),
                ),
                const Spacer(),
                Text(title, style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(subtitle, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 170,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFCE7E9), Color(0xFFFFFFFF)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.my_location,
                                  size: 16,
                                  color: isOnline
                                      ? AppColors.primary
                                      : AppColors.mutedText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOnline ? 'Searching nearby' : 'Paused',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.layers_outlined,
                            color: AppColors.mutedText,
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'Map',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add Google Maps later. UI is ready.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 18,
                bottom: 18,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.outline),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.navigation_outlined,
                    color: AppColors.primary,
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

class _OrderRequestCard extends StatelessWidget {
  const _OrderRequestCard({required this.order});

  final OrderRequest order;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final remaining = order.expiresAt.difference(now);
    final duration = remaining.isNegative ? Duration.zero : remaining;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: duration.inMilliseconds.toDouble(), end: 0),
      duration: duration,
      onEnd: () {
        final stillThere = state.orders.requests.any((r) => r.id == order.id);
        if (stillThere) {
          state.rejectOrder(order.id, reason: 'Timed out');
        }
      },
      builder: (context, millis, _) {
        final secs = (millis / 1000).ceil().clamp(0, 999);
        final canAct = secs > 0;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF334155), width: 1),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fastfood, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.restaurantName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                            const SizedBox(width: 4),
                            const Text(
                              '4.5',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '• Indian Cuisine',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.expectedEarning}',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Est. Earning',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.location_on, color: Color(0xFF94A3B8), size: 16),
                              SizedBox(width: 4),
                              Text(
                                'DISTANCE',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.totalDistanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: const Color(0xFF3F3F3F),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.access_time, color: Color(0xFF94A3B8), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'TIME',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '~${order.etaMin} min',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canAct ? () => state.rejectOrder(order.id) : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3F3F3F)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: canAct ? () {
                        final ok = state.acceptOrder(order.id);
                        if (!ok) return;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DeliveryFlowScreen(orderId: order.id),
                          ),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444), // Red as per image
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Accept Order',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.background,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          trailing,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
