import 'package:flutter/cupertino.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/constants/api_keys.dart';

class PaymentService {
  final _razorpay = Razorpay();
  final _supabase = Supabase.instance.client;

  Function(bool)? onPaymentResult;
  Map<String, dynamic>? _currentNotes;

  PaymentService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> startPayment({
    required double amount,
    required String name,
    required String description,
    Map<String, dynamic>? notes,
  }) async {
    try {
      _currentNotes = notes;

      debugPrint("PAYMENT: Starting order creation for amount: $amount");
      debugPrint("PAYMENT: Notes passed to startPayment: $notes");

      final session = _supabase.auth.currentSession;

      if (session == null || session.isExpired) {
        final AuthResponse res = await _supabase.auth.refreshSession();
        if (res.session == null) {
          debugPrint("PAYMENT ERROR: Session could not be refreshed. User must re-login.");
          onPaymentResult?.call(false);
          return;
        }
      }

      final String token = _supabase.auth.currentSession!.accessToken;

      debugPrint("PAYMENT: JWT Token attached: $token");

      final response = await _supabase.functions.invoke(
        'create-razorpay-order',
        body: {'amount': amount},
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("PAYMENT: create-razorpay-order Status: ${response.status}");
      debugPrint("PAYMENT: create-razorpay-order Data: ${response.data}");

      if (response.status != 200) {
        debugPrint("PAYMENT CRITICAL: Failed to create order. Check Edge Function logs.");
        throw 'Failed to create order';
      }

      final String? orderId = response.data['id'];
      if (orderId == null) {
        debugPrint("PAYMENT ERROR: Order ID is null in response data.");
        throw 'Order ID is null';
      }

      var options = {
        'key': ApiKeys.razorpayKey,
        'amount': amount * 100,
        'name': name,
        'description': description,
        'order_id': orderId,
        'timeout': 300,
        'notes': notes ?? {},
        'prefill': {
          'contact': _supabase.auth.currentUser?.phone ?? '',
          'email': _supabase.auth.currentUser?.email ?? '',
        }
      };

      debugPrint("PAYMENT: Opening Razorpay with Options: $options");
      _razorpay.open(options);
      debugPrint("PAYMENT: Razorpay UI opened");
    } catch (e) {
      // print("Payment Initiation Error: $e");
      debugPrint("PAYMENT CRITICAL ERROR: $e");
      onPaymentResult?.call(false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint("--- DEALER TEST: Payment Success Received ---");
    debugPrint("PAYMENT SUCCESS: PaymentID: ${response.paymentId}, OrderID: ${response.orderId}");

    try {
      final verifyBody = {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'tier': _currentNotes?['tier'],
      };

      debugPrint("PAYMENT VERIFY: Sending to verify-payment: $verifyBody");

      final verifyRes = await _supabase.functions.invoke(
        'verify-payment',
        body: verifyBody,
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}',
        },
      );
      debugPrint("PAYMENT VERIFY: Response Status: ${verifyRes.status}");
      debugPrint("PAYMENT VERIFY: Response Data: ${verifyRes.data}");

      // Explicitly cast verifyRes.data to a Map to avoid index errors
      final dynamic rawData = verifyRes.data;

      debugPrint("PAYMENT VERIFY: Response Data: $rawData");

      bool isActualSuccess = false;
      if (rawData is Map) {
        // Check if it's a boolean true or a string "true"
        var successValue = rawData['success'];
        if (successValue == true || successValue?.toString().toLowerCase() == 'true') {
          isActualSuccess = true;
        }
      }

      if (isActualSuccess) {
        debugPrint("PAYMENT VERIFY: Success! Subscription updated in DB.");
        onPaymentResult?.call(true); // This will trigger the success UI
      } else {
        debugPrint("PAYMENT VERIFY: Failed at Edge Function level. Data was: $rawData");
        onPaymentResult?.call(false);
      }

    } catch (e) {
      debugPrint("PAYMENT VERIFY CRITICAL CATCH: $e");
      onPaymentResult?.call(false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Error: ${response.code} - ${response.message}");

    onPaymentResult?.call(false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet Selected: ${response.walletName}");
  }

  void dispose() {
    _razorpay.clear();
  }
}