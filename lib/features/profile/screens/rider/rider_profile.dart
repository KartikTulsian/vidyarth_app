import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/shared/models/delivery_profile_model.dart';

class RiderProfilePage extends StatefulWidget {
  const RiderProfilePage({super.key});

  @override
  State<RiderProfilePage> createState() => _RiderProfilePageState();
}

class _RiderProfilePageState extends State<RiderProfilePage> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;
  DeliveryProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _service.getDeliveryProfile(); // Uses delivery_boy_id
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _isLoading = true);
    await _service.updateRiderStatus(isAvailable: value); // Updates is_available column
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_profile == null) return const Center(child: Text("Profile not found"));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            Text("Rating: ${_profile!.averageRating} ⭐",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), //
            const Card(
              child: ListTile(
                leading: Icon(Icons.verified_user),
                title: Text("Identity Verified"),
                subtitle: Text("Delivery Partner"),
              ),
            ),
            const Divider(height: 32),
            SwitchListTile(
              title: const Text("Active for Jobs"),
              subtitle: Text(_profile!.isAvailable ? "You are online" : "You are offline"),
              value: _profile!.isAvailable,
              activeColor: Colors.orange[800],
              onChanged: _toggleAvailability, //
            ),
            ListTile(
              leading: const Icon(Icons.directions_bike),
              title: const Text("Vehicle Type"),
              subtitle: Text(_profile!.vehicleType ?? "Not set"), //
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text("License Number"),
              subtitle: Text(_profile!.licenseNumber ?? "Not set"), //
            ),
          ],
        ),
      ),
    );
  }
}