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
  late TextEditingController priceCtrl, qtyCtrl, termsCtrl, depositCtrl, exchangeDescCtrl, paymentDetailsCtrl;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    // PRE-FILLING from the existing Offer
    double initialPrice = 0;
    if (widget.offer.offerType == OfferType.SELL) {
      initialPrice = widget.offer.price ?? 0;
    } else if (widget.offer.offerType == OfferType.RENT) {
      initialPrice = widget.offer.rentalPrice ?? 0;
    }

    priceCtrl = TextEditingController(text: initialPrice.toString());
    qtyCtrl = TextEditingController(text: "1");
    termsCtrl = TextEditingController(text: widget.offer.termsConditions ?? "");
    depositCtrl = TextEditingController(text: widget.offer.securityDeposit?.toString() ?? "0");
    exchangeDescCtrl = TextEditingController(text: widget.offer.exchangeItemDescription ?? "");
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
            const Text("Finalize Trade Terms", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("Set final values after negotiation", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            _buildReadOnlyField("Offer Type", widget.offer.offerType.name),
            if (widget.offer.offerType == OfferType.SELL)
              _buildTextField("Final Selling Price (₹)", priceCtrl, isNumber: true),

            if (widget.offer.offerType == OfferType.RENT) ...[
              _buildTextField("Final Rental Price (₹)", priceCtrl, isNumber: true),
              const Text("Rental Duration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildDatePicker(true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDatePicker(false)),
                ],
              ),
              const SizedBox(height: 15),
            ],

            if (widget.offer.offerType == OfferType.EXCHANGE)
              _buildTextField("Exchange Item Details", exchangeDescCtrl, maxLines: 2),

            _buildTextField("Quantity", qtyCtrl, isNumber: true),

            // Deposit is relevant for Rent/Lend/Share
            if (widget.offer.offerType != OfferType.SELL)
              _buildTextField("Security Deposit (₹)", depositCtrl, isNumber: true),

            const Divider(height: 40),
            const Text("Payment Information", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildTextField(
                "Your UPI ID or Payment Phone (for direct payment)",
                paymentDetailsCtrl,
                hint: "e.g. name@okaxis or 9876543210"
            ),

            _buildTextField("Final Terms/Instructions", termsCtrl, maxLines: 3),

            if (widget.offer.offerType == OfferType.SELL || widget.offer.offerType == OfferType.RENT)
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.amber[50],
                child: const Text(
                  "Note: A 10% platform fee will be added to your next subscription bill based on this trade.",
                  style: TextStyle(fontSize: 11, color: Colors.brown),
                ),
              ),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final price = double.tryParse(priceCtrl.text) ?? 0;

                final fee = (widget.offer.offerType == OfferType.SELL || widget.offer.offerType == OfferType.RENT)
                    ? (price * 0.10) : 0.0;

                final trade = Trade(
                  offerId: widget.offer.id!,
                  lenderId: widget.offer.userId!,
                  borrowerId: widget.borrowerId,
                  finalizedPrice: price,
                  finalizedQuantity: int.tryParse(qtyCtrl.text) ?? 1,
                  finalizedTerms: termsCtrl.text.isEmpty ? exchangeDescCtrl.text : termsCtrl.text,
                  finalizedDeposit: double.tryParse(depositCtrl.text) ?? 0,
                  offerType: widget.offer.offerType,
                  startDate: startDate,
                  endDate: endDate,
                  ownerPaymentDetails: paymentDetailsCtrl.text,
                  platformFee: fee,
                  status: TradeStatus.PENDING,
                  offerDetails: widget.offer,
                );
                widget.onContractSent(trade);
                Navigator.pop(context);
              },
              child: const Text("SEND CONTRACT TO BORROWER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        final d = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365))
        );
        if (d != null) setState(() => isStart ? startDate = d : endDate = d);
      },
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(
        isStart
            ? (startDate == null ? "Start" : "${startDate!.day}/${startDate!.month}")
            : (endDate == null ? "End" : "${endDate!.day}/${endDate!.month}"),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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