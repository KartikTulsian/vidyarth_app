import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/payment_service.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';

class SubscriptionPage extends StatefulWidget {
  final String role;
  final String currentTier;

  const SubscriptionPage({super.key, required this.role, required this.currentTier});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SupabaseService _service = SupabaseService();
  final PaymentService _paymentService = PaymentService();

  SubTier? pendingTier;

  @override
  void initState() {
    super.initState();
    _paymentService.onPaymentResult = (success) async {
      if (success) {
        await _service.upgradeSubscription(pendingTier!);
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment failed. Please try again.")),
        );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: widget.role == UserRole.STUDENT.name ? _buildStudentPlans(context) : _buildDealerPlans(context),
        ),
      ),
    );
  }

  List<Widget> _buildStudentPlans(BuildContext context) {
    return [
      _planCard(context, "Basic", "Free", ["8 Items Limit", "Standard Support"], SubTier.BASIC), //
      _planCard(context, "Student Pro", "₹99/mo", ["20 Items Limit", "Rent/Lend Access", "Basic Analytics"], SubTier.PRO), //
      _planCard(context, "Student Plus", "₹149/mo", ["Unlimited Items", "Priority Support", "Advanced Analytics"], SubTier.PLUS), //
    ];
  }

  List<Widget> _buildDealerPlans(BuildContext context) {
    return [
      _planCard(context, "Basic", "Free", ["Limited Visibility", "5 Inventory Items"], SubTier.BASIC), //
      _planCard(context, "Dealer Pro", "₹199/mo", ["Unlimited Inventory", "Standard Badge", "Performance Stats"], SubTier.PRO), //
      _planCard(context, "Dealer Plus", "₹299/mo", ["Top Map Visibility", "Verified Badge", "Customer Insights"], SubTier.PLUS), //
    ];
  }

  Widget _planCard(BuildContext context, String name, String price, List<String> features, SubTier tier) {
    bool isCurrent = widget.currentTier == tier.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCurrent ? Colors.blue : Colors.grey[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (isCurrent) const Chip(label: Text("Current Plan"), backgroundColor: Colors.green, labelStyle: TextStyle(color: Colors.white)),
            ],
          ),
          Text(price, style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.bold)),
          const Divider(height: 30),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [const Icon(Icons.check_circle, size: 16, color: Colors.green), const SizedBox(width: 8), Text(f)],),
          )),
          const SizedBox(height: 20),
          if (!isCurrent)
            ElevatedButton(
              onPressed: () {

                pendingTier = tier;

                double amount = double.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

                _paymentService.startPayment(
                  amount: amount,
                  name: name,
                  description: "Upgrade to $name",
                  notes: {'tier': tier.name},
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
              child: const Text("Upgrade Now", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
