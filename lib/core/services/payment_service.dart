import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/constants/api_keys.dart';

class PaymentService {
  final _razorpay = Razorpay();
  final _supabase = Supabase.instance.client;

  Function(bool)? onPaymentResult;

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
      final response = await _supabase.functions.invoke(
        'create-razorpay-order',
        body: {'amount': amount},
      );

      if (response.status != 200) throw 'Failed to create order';

      final String orderId = response.data['id'];

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

      _razorpay.open(options);
    } catch (e) {
      print("Payment Initiation Error: $e");
      onPaymentResult?.call(false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final verifyRes = await _supabase.functions.invoke(
        'verify-payment',
        body: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
        },
      );

      if (verifyRes.data['success'] == true) {
        onPaymentResult?.call(true);
      } else {
        onPaymentResult?.call(false);
      }
    } catch (e) {
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