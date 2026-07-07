import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/features/khata/screens/khata_home_screen.dart';
import 'package:digiluk/features/reports/screens/reports_screen.dart';
import 'package:digiluk/features/reminders/screens/share_balance_screen.dart';
import 'package:digiluk/features/stock/screens/stock_screen.dart';
import 'package:digiluk/features/billing/screens/create_invoice_screen.dart';
import 'package:digiluk/features/profile/screens/profile_screen.dart';

class MobileLayoutScreen extends ConsumerStatefulWidget {
  const MobileLayoutScreen({super.key});

  @override
  ConsumerState<MobileLayoutScreen> createState() =>
      _MobileLayoutScreenState();
}

class _MobileLayoutScreenState extends ConsumerState<MobileLayoutScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const KhataHomeScreen(),
    const ReportsScreen(),
    const _MoreScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: digilukPrimary,
        unselectedItemColor: digilukGrey,
        backgroundColor: digilukBottomNavColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Khata',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'More',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreItem(
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF7C4DFF),
        title: 'Stock / Inventory',
        subtitle: 'Manage items, track quantity, low-stock alerts',
        onTap: () => Navigator.pushNamed(context, StockScreen.routeName),
      ),
      _MoreItem(
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF00BCD4),
        title: 'Invoices / Bills',
        subtitle: 'GST & non-GST bills, link unpaid to ledger',
        onTap: () => Navigator.pushNamed(context, InvoiceListScreen.routeName),
      ),
      _MoreItem(
        icon: Icons.notifications_active_outlined,
        color: const Color(0xFFFF6B35),
        title: 'Bulk Reminders',
        subtitle: 'Send WhatsApp/SMS reminders to all due customers',
        onTap: () => Navigator.pushNamed(context, BulkRemindersScreen.routeName),
      ),
      _MoreItem(
        icon: Icons.groups_outlined,
        color: digilukAccent,
        title: 'Groups',
        subtitle: 'Trust & committee fund management',
        onTap: () => Navigator.pushNamed(context, '/dashboard-trusts'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => items[i],
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MoreItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: digilukSubTextColor)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: digilukSubTextColor),
            ],
          ),
        ),
      ),
    );
  }
}
