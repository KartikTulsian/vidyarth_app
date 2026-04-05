import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/payment_service.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';

class SubscriptionPage extends StatefulWidget {
  final String role;
  final String currentTier;

  const SubscriptionPage({
    super.key,
    required this.role,
    required this.currentTier,
  });

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SupabaseService _service = SupabaseService();
  final PaymentService _paymentService = PaymentService();

  bool _isProcessing = false;

  SubTier? pendingTier;

  @override
  void initState() {
    super.initState();
    _paymentService.onPaymentResult = (success) async {
      setState(() => _isProcessing = false);

      if (success) {
        // await _service.upgradeSubscription(pendingTier!);
        debugPrint("SUBSCRIPTION UI: Success detected. Refreshing profile...");
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 60),
                  SizedBox(height: 10),
                  Text("Payment Successful!", textAlign: TextAlign.center),
                ],
              ),
              content: const Text(
                "Your subscription has been upgraded. Your profile will refresh automatically.",
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "AWESOME",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );

          // 2. Return 'true' to the profile page to trigger refresh
          if (mounted) Navigator.pop(context, true); // Close the page
        }
      } else {
        debugPrint("SUBSCRIPTION UI: Failure detected.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Payment check failed. Please refresh your profile manually.",
              ),
            ),
          );
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Your Plan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: widget.role == 'STUDENT'
                  ? _buildStudentPlans(context)
                  : _buildDealerPlans(context),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      "Confirming Payment...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Please do not close the app",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildStudentPlans(BuildContext context) {
    return [
      _planCard(context, "Basic", "Free", [
        "8 Items Limit",
        "Standard Support",
      ], SubTier.BASIC), //
      _planCard(context, "Student Pro", "₹99/mo", [
        "20 Items Limit",
        "Rent/Lend Access",
        "Basic Analytics",
      ], SubTier.PRO), //
      _planCard(context, "Student Plus", "₹199/mo", [
        "Unlimited Items",
        "Priority Support",
        "Advanced Analytics",
      ], SubTier.PLUS), //
    ];
  }

  List<Widget> _buildDealerPlans(BuildContext context) {
    return [
      _planCard(context, "Basic", "Free", [
        "Limited Visibility",
        "5 Inventory Items",
      ], SubTier.BASIC), //
      _planCard(context, "Dealer Pro", "₹199/mo", [
        "Unlimited Inventory",
        "Standard Badge",
        "Performance Stats",
      ], SubTier.PRO), //
      _planCard(context, "Dealer Plus", "₹299/mo", [
        "Top Map Visibility",
        "Verified Badge",
        "Customer Insights",
      ], SubTier.PLUS), //
    ];
  }

  Widget _planCard(
    BuildContext context,
    String name,
    String price,
    List<String> features,
    SubTier tier,
  ) {
    final currentTierEnum = SubTier.values.firstWhere(
      (e) => e.name == widget.currentTier,
      orElse: () => SubTier.BASIC,
    );

    bool isCurrent = widget.currentTier == tier.name;

    bool isUpgrade = tier.index > currentTierEnum.index;
    String buttonText = isUpgrade ? "Upgrade Now" : "Downgrade Plan";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? Colors.blue : Colors.grey[200]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isCurrent)
                const Chip(
                  label: Text("Current Plan"),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white),
                ),
            ],
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 30),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(f),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!isCurrent)
            ElevatedButton(
              onPressed: () {
                setState(() => _isProcessing = true);

                pendingTier = tier;

                // Clean way to get price: extract digits and dots
                String cleanPrice = price.replaceAll(RegExp(r'[^0-9.]'), '');
                double amount = double.tryParse(cleanPrice) ?? 0;

                debugPrint(
                  "SUBSCRIPTION: Plan: $name, Raw Price: $price, Parsed Amount: $amount",
                );

                if (amount > 0) {
                  _paymentService.startPayment(
                    amount: amount,
                    name: name,
                    description:
                        "${isUpgrade ? 'Upgrade' : 'Downgrade'} to $name",
                    notes: {'tier': tier.name},
                  );
                } else if (amount == 0) {
                  debugPrint("Switching to Free tier...");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(buttonText, style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
