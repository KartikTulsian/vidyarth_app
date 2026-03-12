import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/auth_service.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/core/theme.dart';
import 'package:vidyarth_app/features/auth/screens/user_form_screen.dart';
import 'package:vidyarth_app/features/dashboard/screens/dashboard_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String? password; // Optional, passed for context if needed

  const OtpScreen({super.key, required this.email, this.password});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;

  void _verifyOtp() async {
    setState(() => _isLoading = true);

    try {
      final response = await _authService.verifyEmailOtp(
          widget.email,
          _otpController.text.trim()
      );

      if (response.session != null) {
        // Verification Successful!
        // final hasProfile = await _supabaseService.hasProfile();
        // if (!mounted) return;
        //
        // if (hasProfile) {
        //   Navigator.pushAndRemoveUntil(
        //       context,
        //       MaterialPageRoute(builder: (_) => const DashboardScreen()),
        //           (r) => false
        //   );
        // } else {
        //   Navigator.pushReplacement(
        //       context,
        //       // Pass the email so it auto-fills
        //       MaterialPageRoute(builder: (_) => UserFormScreen(initialEmail: widget.email))
        //   );
        // }

        final userModel = await _supabaseService.getUnifiedProfile();

        if (!mounted) return;

        if (userModel != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
        } else {
          // Pass the email from the widget so the form isn't empty
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserFormScreen(initialEmail: widget.email))
          );
        }
      } else {
        throw "Verification failed. Please try again.";
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Verify your Email', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Enter the code sent to ${widget.email}', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 30),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              // Increased maxLength to 8 to handle longer OTPs
              maxLength: 8,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: "",
                // Updated hint to be generic
                hintText: '- - - - - -',
                hintStyle: TextStyle(color: Colors.grey.shade300),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify Email', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}