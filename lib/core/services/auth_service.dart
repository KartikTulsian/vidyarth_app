import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _updateLastLogin(String userId) async {
    try {
      await _supabase.from('users').update({
        'last_login': DateTime.now().toIso8601String(),
        'is_active': true,
      }).eq('user_id', userId);
    } catch (e) {
      print("Error updating last_login: $e");
    }
  }

  // 1. Sign Up with Email & Password
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    return response;
  }

  // 2. Verify Email OTP (The New Feature)
  Future<AuthResponse> verifyEmailOtp(String email, String token) async {
    final response = await _supabase.auth.verifyOTP(
      token: token,
      type: OtpType.signup,
      email: email,
    );

    if (response.user != null) {
      await _updateLastLogin(response.user!.id); // Update login time
    }
    return response;
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // This ensures the last_login and is_active flags in your public.users table
      // are updated every time a student or dealer logs in.
      await _updateLastLogin(response.user!.id);
    }
    return response;
  }

  // 3. Sign In with Email & Password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      await _updateLastLogin(response.user!.id); // Update login time
    }
    return response;
  }

  // 4. Sign In with Google
  Future<AuthResponse> signInWithGoogle() async {
    // WEB CLIENT ID (From Google Cloud -> Credentials -> OAuth 2.0 Client IDs -> Web)
    const webClientId = '431664039726-0n5upgpai3h14gkv668hmr84kg0nmlpc.apps.googleusercontent.com';

    // iOS Client ID (Optional)
    const iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      // clientId: iosClientId,
      serverClientId: webClientId,
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw 'Google Sign-In canceled.';
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'No ID Token found from Google.';
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    if (response.user != null) {
      await _updateLastLogin(response.user!.id); // Update login time
    }
    return response;
  }

  // 5. Sign Out
  Future<void> signOut() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}