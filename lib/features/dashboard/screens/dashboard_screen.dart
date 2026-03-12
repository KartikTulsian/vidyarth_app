import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/auth_service.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/core/theme.dart';
import 'package:vidyarth_app/features/auth/screens/login_screen.dart';
import 'package:vidyarth_app/features/auth/screens/user_form_screen.dart';
import 'package:vidyarth_app/features/dashboard/screens/admin_dashboard.dart';
import 'package:vidyarth_app/features/dashboard/screens/dealer_dashboard.dart';
import 'package:vidyarth_app/features/dashboard/screens/delivery_dashboard.dart';
import 'package:vidyarth_app/features/dashboard/screens/student_dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final SupabaseService _supabaseService = SupabaseService();

  String? _userRole;
  bool _isLoading = true;
  bool _isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userModel = await _supabaseService.getUnifiedProfile();

      if (!mounted) return;

      if (userModel != null) {
        setState(() {
          _isProfileComplete = userModel.profile != null;
          _userRole = userModel.role.name;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isProfileComplete = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Dashboard Load Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator())
      );
    }

    if (!_isProfileComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complete Profile')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.orange,
                child: Icon(Icons.person_add, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20,),
              const Text(
                'Almost there!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10,),
              const Text(
                  'Please complete your profile to access the dashboard'),
              const SizedBox(height: 30,),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserFormScreen())
                  ).then((_) => _loadUserData());
                },
                child: const Text('Complete Profile Now'),
              ),
              TextButton(onPressed: _handleLogout, child: const Text('Logout'))
            ],
          ),
        ),
      );
    }

    switch (_userRole) {
      case 'DEALER':
        return DealerDashboard(onLogout: _handleLogout);
      case 'DELIVERY_BOY':
        return DeliveryDashboard(onLogout: _handleLogout);
      case 'ADMIN':
        return AdminDashboard(onLogout: _handleLogout);
      case 'STUDENT':
      default:
        return StudentDashboard(onLogout: _handleLogout);
    }
  }
}