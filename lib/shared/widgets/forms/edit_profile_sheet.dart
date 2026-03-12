import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/dealer_profile_model.dart';
import 'package:vidyarth_app/shared/models/profile_model.dart';
import 'package:vidyarth_app/shared/models/school_model.dart';
import 'package:vidyarth_app/shared/models/user_model.dart';

class EditProfileSheet extends StatefulWidget {
  final UserModel userData;
  final VoidCallback onSaveSuccess;

  const EditProfileSheet({
    super.key,
    required this.userData,
    required this.onSaveSuccess,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final SupabaseService _supabaseService = SupabaseService();

  // Controllers
  late TextEditingController fullNameCtrl;
  late TextEditingController displayNameCtrl;
  late TextEditingController bioCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController pincodeCtrl;

  late TextEditingController _shopNameCtrl;
  late TextEditingController _gstCtrl;
  late TextEditingController _businessAddressCtrl;
  late TextEditingController _openTimeCtrl;
  late TextEditingController _closeTimeCtrl;

  // Dropdown State
  String? selectedGender;
  String? selectedSchoolId;
  List<SchoolCollege> _availableSchools = [];
  bool _isLoadingSchools = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchSchools();
  }

  void _initializeControllers() {
    // Helper to safely get string data
    final profile = widget.userData.profile; //
    final dealer = widget.userData.dealerProfile;

    fullNameCtrl = TextEditingController(text: profile?.fullName ?? '');
    displayNameCtrl = TextEditingController(text: profile?.displayName ?? '');
    bioCtrl = TextEditingController(text: profile?.bio ?? '');
    phoneCtrl = TextEditingController(text: widget.userData.phone ?? profile?.phone ?? '');
    addressCtrl = TextEditingController(text: profile?.address ?? '');
    cityCtrl = TextEditingController(text: profile?.city ?? '');
    stateCtrl = TextEditingController(text: profile?.state ?? '');
    pincodeCtrl = TextEditingController(text: profile?.pincode ?? '');

    selectedGender = profile?.gender;
    const validGenders = ['Male', 'Female', 'Other'];
    if (selectedGender != null && !validGenders.contains(selectedGender)) {
      selectedGender = null;
    }

    _shopNameCtrl = TextEditingController(text: dealer?.shopName ?? '');
    _gstCtrl = TextEditingController(text: dealer?.gstNumber ?? '');
    _businessAddressCtrl = TextEditingController(text: dealer?.businessAddress ?? '');
    _openTimeCtrl = TextEditingController(text: dealer?.openingTime ?? '');
    _closeTimeCtrl = TextEditingController(text: dealer?.closingTime ?? '');

    selectedSchoolId = profile?.schoolCollegeId;
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        // Formats time as HH:MM:00 for the database
        controller.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
      });
    }
  }

  Future<void> _fetchSchools() async {
    final schools = await _supabaseService.getSchools();

    if (mounted) {
      setState(() {
        _availableSchools = schools;
        _isLoadingSchools = false;

        // CRITICAL FIX: Check if the user's current school ID actually exists in the fetched list.
        // If not, reset it to null to prevent the "Value not in range" error.
        bool exists = schools.any((s) => s.id == selectedSchoolId);
        if (!exists) selectedSchoolId = null;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (fullNameCtrl.text.trim().isEmpty) {
      print("DEBUG: Validation failed - Full Name is empty");
      return;
    }

    setState(() => _isSaving = true);
    print("DEBUG: Starting Profile Save Process...");

    // String? sanitize(String val) => val.trim().isEmpty ? null : val.trim();

    try {
      // 1. Update Profile using the model data
      final updatedProfile = ProfileModel(
        id: widget.userData.profile?.id ?? '',
        userId: widget.userData.id,
        fullName: fullNameCtrl.text.trim(),
        avatarUrl: widget.userData.profile?.avatarUrl,
        trust_score: widget.userData.profile?.trust_score,
        created_at: widget.userData.profile?.created_at,
        displayName: displayNameCtrl.text.trim(),
        bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
        city: cityCtrl.text.trim().isEmpty ? null : cityCtrl.text.trim(),
        state: stateCtrl.text.trim().isEmpty ? null : stateCtrl.text.trim(),
        pincode: pincodeCtrl.text.trim().isEmpty ? null : pincodeCtrl.text.trim(),
        gender: selectedGender,
        schoolCollegeId: selectedSchoolId,
      );

      print("DEBUG: Profile toMap content: ${updatedProfile.toMap()}");
      await _supabaseService.updateDetailedProfile(updatedProfile);
      print("DEBUG: updateDetailedProfile completed successfully");

      // 2. Update Dealer Business Profile if applicable
      if (widget.userData.role == UserRole.DEALER) {
        final updatedDealer = DealerProfile(
          dealerId: widget.userData.id,
          shopName: _shopNameCtrl.text.trim(),
          gstNumber: _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
          businessAddress: _businessAddressCtrl.text.trim().isEmpty ? null : _businessAddressCtrl.text.trim(),
          openingTime: _openTimeCtrl.text.trim().isEmpty ? null : _openTimeCtrl.text.trim(),
          closingTime: _closeTimeCtrl.text.trim().isEmpty ? null : _closeTimeCtrl.text.trim(),
          isVerified: widget.userData.dealerProfile?.isVerified ?? false,
          latitude: widget.userData.dealerProfile?.latitude,
          longitude: widget.userData.dealerProfile?.longitude,
        );
        print("DEBUG: Dealer toMap content: ${updatedDealer.toMap()}");
        await _supabaseService.updateDealerBusinessProfile(updatedDealer);
        print("DEBUG: updateDealerBusinessProfile completed successfully");
      }

      if (mounted) {
        widget.onSaveSuccess();
        Navigator.pop(context);
      }
    } catch (e, stacktrace) {
      print("DEBUG: ERROR DURING SAVE: $e");
      print("DEBUG: STACKTRACE: $stacktrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDealer = widget.userData.role == UserRole.DEALER;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildDragHandle(),
          _buildHeader(),
          const Divider(height: 1),

          // Scrollable Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: keyboardHeight + 20, // Pad for keyboard
              ),
              child: Column(
                children: [
                  _buildSectionLabel("General Information"),
                  _buildTextField("Full Name", fullNameCtrl),
                  _buildTextField("Display Name", displayNameCtrl),
                  _buildTextField("Bio", bioCtrl, maxLines: 3),
            
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: _inputDecoration("Gender"),
                    items: ['Male', 'Female', 'Other'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedGender = val),
                  ),
            
                  _buildSectionLabel("Contact Info"),
                  _buildTextField(
                    "Phone Number",
                    phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
            
                  _buildSectionLabel("Address Details"),
                  _buildTextField("Address Line", addressCtrl),
                  Row(
                    children: [
                      Expanded(child: _buildTextField("City", cityCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTextField("State", stateCtrl)),
                    ],
                  ),
                  _buildTextField(
                    "Pincode",
                    pincodeCtrl,
                    keyboardType: TextInputType.number,
                  ),
            
                  if (widget.userData.role == UserRole.STUDENT) ...[
                    _buildSectionLabel("Academic"),
                    _isLoadingSchools
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : DropdownButtonFormField<String>(
                      value: selectedSchoolId,
                      isExpanded: true,
                      decoration: _inputDecoration("Select School / College"),
                      items: _availableSchools.map((school) {
                        return DropdownMenuItem<String>(
                          value: school.id,
                          child: Text("${school.name} (${school.city})", overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedSchoolId = val),
                      hint: const Text("Select your institution"),
                    ),
                  ],

                  if (isDealer) ...[
                    _buildSectionLabel("Business Details"),
                    _buildTextField("Shop Name", _shopNameCtrl),
                    _buildTextField("GST Number", _gstCtrl),
                    _buildTextField("Business Address", _businessAddressCtrl),
                    Row(
                      children: [
                        Expanded(child: _buildTimePickerField("Opens", _openTimeCtrl)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTimePickerField("Closes", _closeTimeCtrl)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Save Button
          const SizedBox(height: 20),
          _buildSaveButton(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Edit Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildTimePickerField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () => _selectTime(context, controller),
        child: IgnorePointer(
          child: TextField(
            controller: controller,
            decoration: _inputDecoration(label).copyWith(
              suffixIcon: const Icon(Icons.access_time),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SafeArea( // FIX: Prevents overlap with system navigation bar
        top: false,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
