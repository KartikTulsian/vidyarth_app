import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/core/theme.dart';
import 'package:vidyarth_app/features/browse/screens/browse_page.dart';
import 'package:vidyarth_app/features/message/screens/student_message_screen.dart';
import 'package:vidyarth_app/features/profile/screens/student/student_home.dart';
import 'package:vidyarth_app/features/profile/screens/student/student_profile.dart';
import 'package:vidyarth_app/features/trade/screens/trade_page.dart';
import 'package:vidyarth_app/shared/models/user_model.dart';

class StudentDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  const StudentDashboard({super.key, required this.onLogout});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  final SupabaseService _service = SupabaseService();
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final data = await _service.getUnifiedProfile();
    if (mounted) {
      setState(() {
        _userModel = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Define pages here so they receive the fresh userModel
    final List<Widget> pages = [
      StudentHome(onLogout: widget.onLogout, userData: _userModel!), // PASSING HERE
      BrowsePage(onLogout: widget.onLogout),
      StudentMessageScreen(),
      TradePage(onLogout: widget.onLogout),
      StudentProfile(onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // App bar is handled individually by pages if needed, or hidden here
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
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
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Browse'),
            BottomNavigationBarItem(icon: Icon(Icons.message_rounded), label: 'Messages'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline, size: 32),
                label: 'Trade'
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}