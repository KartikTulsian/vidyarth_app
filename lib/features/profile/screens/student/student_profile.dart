import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/features/profile/screens/subscription_page.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/user_model.dart';
import 'package:vidyarth_app/shared/widgets/forms/edit_profile_sheet.dart';

class StudentProfile extends StatefulWidget {
  final VoidCallback onLogout;
  const StudentProfile({super.key, required this.onLogout});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();

  UserModel? _userModel;
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isRefreshing = true);
    final data = await _supabaseService.getUnifiedProfile();
    if (mounted) {
      setState(() {
        _userModel = data;
        _isLoading = false;
        _isRefreshing = false; // Stop Loading
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploading = true);

      final File file = File(image.path);
      // The service now returns the new URL and updates the DB
      final newUrl = await _supabaseService.uploadProfileImage(file);

      if (newUrl != null) {
        await _loadProfile(); // Force reload state to show new image
      }
      setState(() => _isUploading = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  void _openEditSheet() {
    if (_userModel == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileSheet(
        userData: _userModel!,
        onSaveSuccess: () {
          _loadProfile(); // Refresh parent when child saves
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!")),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Extracting initials for the avatar
    final profile = _userModel?.profile;
    String name = profile?.fullName ?? _userModel?.username ?? "User";
    String? avatarUrl = profile?.avatarUrl;
    String initial = name.isNotEmpty ? name[0].toUpperCase() : "U";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Your Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),

        actions: [
          _isRefreshing
              ? const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue[50],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: avatarUrl != null
                          ? CachedNetworkImage(
                        imageUrl: avatarUrl, // Use URL without the manual timestamp here
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      )
                          : Center(
                        child: Text(initial, style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Name & Edit Button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        // REFINED BUTTON LAYOUT
                        Row(
                          children: [
                            _isUploading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : InkWell(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                                child: const Icon(Icons.photo_camera, color: Colors.white, size: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _openEditSheet,
                              child: const Text("Edit Details ▶", style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- GOLD STYLE CARD ---
            _buildMembershipCard(),

            _buildSectionHeader("Contact & Personal"),
            _buildProfileItem(Icons.badge_outlined, "Display Name", profile?.displayName ?? "-"),
            _buildProfileItem(Icons.person_outline, "Gender", profile?.gender ?? "-"),
            _buildProfileItem(Icons.phone_outlined, "Phone", _userModel?.phone ?? profile?.phone ?? "-"),

            _buildSectionHeader("Location"),
            _buildProfileItem(Icons.home_outlined, "Address", profile?.address ?? "-"),
            _buildProfileItem(Icons.location_city, "City / State", "${profile?.city ?? '-'}, ${profile?.state ?? '-'}"),
            _buildProfileItem(Icons.pin_drop_outlined, "Pincode", profile?.pincode ?? "-"),

            _buildSectionHeader("Academic"),
            _buildProfileItem(
              Icons.school_outlined,
              "College ID",
              profile?.schoolCollegeId ?? "-", // Matches public.profiles.school_college_id
            ),

            const SizedBox(height: 20),
            ListTile(
              onTap: widget.onLogout,
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard() {
    // Determine membership label based on role and subTier enums
    String roleLabel = _userModel?.role == UserRole.STUDENT ? "Student" : "User";
    String tierLabel = _userModel?.subTier == SubTier.BASIC ? "Basic" : "Pro";

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SubscriptionPage(
          role: _userModel?.role.name ?? 'STUDENT',
          currentTier: _userModel?.subTier.name ?? 'BASIC',
        )));
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              Text(
                "Membership: $roleLabel $tierLabel",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}
