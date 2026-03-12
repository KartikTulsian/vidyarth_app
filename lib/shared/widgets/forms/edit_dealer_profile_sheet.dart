import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/shared/models/dealer_profile_model.dart';
import 'package:vidyarth_app/shared/models/user_model.dart';

class EditDealerProfileSheet extends StatefulWidget {
  final UserModel userData;
  final VoidCallback onSaveSuccess;

  const EditDealerProfileSheet({super.key, required this.userData, required this.onSaveSuccess});

  @override
  State<EditDealerProfileSheet> createState() => _EditDealerProfileSheetState();
}

class _EditDealerProfileSheetState extends State<EditDealerProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  late TextEditingController _shopNameController;
  late TextEditingController _gstController;
  late TextEditingController _addressController;
  late TextEditingController _openTimeController;
  late TextEditingController _closeTimeController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final dealer = widget.userData.dealerProfile;

    _shopNameController = TextEditingController(text: dealer?.shopName ?? "");
    _gstController = TextEditingController(text: dealer?.gstNumber ?? "");
    _addressController = TextEditingController(text: dealer?.businessAddress ?? "");
    _openTimeController = TextEditingController(text: dealer?.openingTime ?? "");
    _closeTimeController = TextEditingController(text: dealer?.closingTime ?? "");
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create a new DealerProfile instance to pass to the service
        final updatedDealer = DealerProfile(
          dealerId: widget.userData.id, // Use ID from parent user model
          shopName: _shopNameController.text.trim(),
          gstNumber: _gstController.text.trim(),
          businessAddress: _addressController.text.trim(),
          openingTime: _openTimeController.text.trim(),
          closingTime: _closeTimeController.text.trim(),
          // Preserve existing verification/location status
          isVerified: widget.userData.dealerProfile?.isVerified ?? false,
          latitude: widget.userData.dealerProfile?.latitude,
          longitude: widget.userData.dealerProfile?.longitude,
        );

        // Call the service method updated to handle the model
        await _supabaseService.updateDealerBusinessProfile(updatedDealer);

        widget.onSaveSuccess();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Edit Business Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(controller: _shopNameController, decoration: const InputDecoration(labelText: "Shop Name*"), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: _gstController, decoration: const InputDecoration(labelText: "GST Number")),
              TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: "Business Address")),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _openTimeController, decoration: const InputDecoration(labelText: "Opening Time (HH:MM)"))),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _closeTimeController, decoration: const InputDecoration(labelText: "Closing Time (HH:MM)")))
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
                  child: const Text("Save Business Deatils", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
