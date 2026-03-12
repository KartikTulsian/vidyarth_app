import 'package:flutter/material.dart';
import 'package:vidyarth_app/features/delivery/active_deliveries_page.dart';
import 'package:vidyarth_app/features/delivery/delivery_support_page.dart';
import 'package:vidyarth_app/features/delivery/earnings_history_page.dart';
import 'package:vidyarth_app/features/profile/screens/rider/rider_profile.dart';

class DeliveryDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  const DeliveryDashboard({super.key, required this.onLogout});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const RiderProfilePage(),
    const ActiveDeliveriesPage(),
    const EarningsHistoryPage(),
    const DeliverySupportPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner'),
        backgroundColor: Colors.orange[800], // Distinct color for Delivery
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (idx) => setState(() => _selectedIndex = idx),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange[800],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_pin), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.headset_mic), label: 'Support'),
        ],
      ),
    );
  }
}
