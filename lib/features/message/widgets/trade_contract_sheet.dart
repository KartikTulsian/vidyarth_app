import 'package:flutter/material.dart';
import 'package:vidyarth_app/shared/models/offer_model.dart';
import 'package:vidyarth_app/shared/models/trade_model.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';

class TradeContractSheet extends StatefulWidget {
  final Offer offer;
  final String borrowerId;
  final Function(Trade) onContractSent;

  const TradeContractSheet({super.key, required this.offer, required this.borrowerId, required this.onContractSent});

  @override
  State<TradeContractSheet> createState() => _TradeContractSheetState();
}

class _TradeContractSheetState extends State<TradeContractSheet> {
  late TextEditingController priceCtrl, qtyCtrl, termsCtrl, depositCtrl;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    // PRE-FILLING from the existing Offer
    priceCtrl = TextEditingController(text: (widget.offer.price ?? widget.offer.rentalPrice ?? 0).toString());
    qtyCtrl = TextEditingController(text: "1");
    termsCtrl = TextEditingController(text: widget.offer.termsConditions ?? "");
    depositCtrl = TextEditingController(text: widget.offer.securityDeposit?.toString() ?? "0");
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
            const Text("Finalize Trade Terms", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("Set final values after negotiation", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            _buildReadOnlyField("Offer Type", widget.offer.offerType.name),
            _buildTextField("Final Price (₹)", priceCtrl, isNumber: true),
            _buildTextField("Quantity", qtyCtrl, isNumber: true),

            if (widget.offer.offerType == OfferType.RENT || widget.offer.offerType == OfferType.LEND) ...[
              const Text("Duration", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (d != null) setState(() => startDate = d);
                    },
                    child: Text(startDate == null ? "Start Date" : startDate!.toLocal().toString().split(' ')[0]),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (d != null) setState(() => endDate = d);
                    },
                    child: Text(endDate == null ? "End Date" : endDate!.toLocal().toString().split(' ')[0]),
                  )),
                ],
              ),
            ],
            const SizedBox(height: 10),
            _buildTextField("Security Deposit (₹)", depositCtrl, isNumber: true),
            _buildTextField("Final Terms/Instructions", termsCtrl, maxLines: 3),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 55)),
              onPressed: () {
                final trade = Trade(
                  offerId: widget.offer.id!,
                  lenderId: widget.offer.userId!,
                  borrowerId: widget.borrowerId,
                  finalizedPrice: double.tryParse(priceCtrl.text),
                  finalizedQuantity: int.tryParse(qtyCtrl.text) ?? 1,
                  finalizedTerms: termsCtrl.text,
                  finalizedDeposit: double.tryParse(depositCtrl.text),
                  offerType: widget.offer.offerType,
                  startDate: startDate,
                  endDate: endDate,
                  status: TradeStatus.PENDING,
                );
                widget.onContractSent(trade);
                Navigator.pop(context);
              },
              child: const Text("SEND CONTRACT TO BORROWER", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }
}