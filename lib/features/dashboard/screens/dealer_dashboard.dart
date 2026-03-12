import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/theme.dart';
import 'package:vidyarth_app/features/browse/screens/browse_page.dart';
import 'package:vidyarth_app/features/inventory/screens/dealer_inventory.dart';
import 'package:vidyarth_app/features/message/screens/messageScreen.dart';
import 'package:vidyarth_app/features/profile/screens/dealer/dealer_home.dart';
import 'package:vidyarth_app/features/profile/screens/dealer/dealer_profile.dart';
import 'package:vidyarth_app/features/trade/screens/trade_page.dart';

class DealerDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  const DealerDashboard({super.key, required this.onLogout});

  @override
  State<DealerDashboard> createState() => _DealerDashboardState();
}

class _DealerDashboardState extends State<DealerDashboard> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  // final List<Widget> _pages = [
  //   const Center(child: Text("Shop Profile & Stats")),
  //   const Center(child: Text("Manage Inventory (Trade)")),
  //   const Center(child: Text("Customer Orders")),
  //   const Center(child: Text("Messages")),
  // ];

  void initState() {
    super.initState();
    _pages = [
      // DealerHome(onLogout: widget.onLogout),
      DealerInventory(onLogout: widget.onLogout),
      BrowsePage(onLogout: widget.onLogout),
      Messagescreen(onLogout: widget.onLogout,),
      DealerProfile(onLogout: widget.onLogout), // Pass logout to Profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (idx) => setState(() => _selectedIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventory'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline, size: 32),
                label: 'Browse'
            ),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
