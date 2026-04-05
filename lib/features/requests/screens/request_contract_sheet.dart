import 'package:flutter/material.dart';
import 'package:vidyarth_app/shared/models/request_model.dart';
import 'package:vidyarth_app/shared/models/request_trade_model.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';

class RequestContractSheet extends StatefulWidget {
  final RequestModel request;
  final String helperId;
  final Function(RequestTrade) onContractSent;

  const RequestContractSheet({super.key, required this.request, required this.helperId, required this.onContractSent});

  @override
  State<RequestContractSheet> createState() => _RequestContractSheetState();
}

class _RequestContractSheetState extends State<RequestContractSheet> {
  late TextEditingController priceCtrl, qtyCtrl, termsCtrl, depositCtrl, paymentDetailsCtrl;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    priceCtrl = TextEditingController(text: "0");
    qtyCtrl = TextEditingController(text: "1");
    termsCtrl = TextEditingController();
    depositCtrl = TextEditingController(text: "0");
    paymentDetailsCtrl = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Propose Help Terms", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("Set terms to help the requester", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            _buildReadOnlyField("Requested Item", widget.request.stuffType.name),
            _buildTextField("Price (₹) - 0 for Free", priceCtrl, isNumber: true),

            const Text("Duration (If lending/renting)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDatePicker(true)),
                const SizedBox(width: 10),
                Expanded(child: _buildDatePicker(false)),
              ],
            ),
            const SizedBox(height: 15),

            _buildTextField("Quantity", qtyCtrl, isNumber: true),
            _buildTextField("Security Deposit (₹)", depositCtrl, isNumber: true),
            const Divider(height: 40),
            _buildTextField("Your UPI ID (if payment required)", paymentDetailsCtrl, hint: "e.g. name@upi"),
            _buildTextField("Additional Terms", termsCtrl, maxLines: 3),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final trade = RequestTrade(
                  requestId: widget.request.id,
                  lenderId: widget.helperId, // Person helping
                  borrowerId: widget.request.userId!, // Person who made request
                  finalizedPrice: double.tryParse(priceCtrl.text) ?? 0,
                  finalizedQuantity: int.tryParse(qtyCtrl.text) ?? 1,
                  finalizedTerms: termsCtrl.text,
                  finalizedDeposit: double.tryParse(depositCtrl.text) ?? 0,
                  startDate: startDate,
                  endDate: endDate,
                  ownerPaymentDetails: paymentDetailsCtrl.text,
                  status: TradeStatus.PENDING,
                );
                widget.onContractSent(trade);
                Navigator.pop(context);
              },
              child: const Text("SEND PROPOSAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool isStart) {
    return OutlinedButton.icon(
      onPressed: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
        if (d != null) setState(() => isStart ? startDate = d : endDate = d);
      },
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(isStart ? (startDate == null ? "Start" : "${startDate!.day}/${startDate!.month}") : (endDate == null ? "End" : "${endDate!.day}/${endDate!.month}"), style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(controller: ctrl, maxLines: maxLines, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: label, hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }
}