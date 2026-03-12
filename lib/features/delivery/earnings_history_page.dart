import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/shared/models/delivery_model.dart';

class EarningsHistoryPage extends StatelessWidget {
  const EarningsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SupabaseService _service = SupabaseService();

    return Scaffold(
      body: FutureBuilder<List<Delivery>>(
        future: _service.getDeliveryHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final history = snapshot.data ?? [];

          return Column(
            children: [
              _buildEarningsSummary(history.length),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text("Order #${item.id.substring(0, 8)}"), //
                      subtitle: Text(
                        "Completed: ${item.deliveryTime?.toLocal()}",
                      ), //
                      trailing: const Text(
                        "₹50.00",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ), // Example fixed rate
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEarningsSummary(int count) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      color: Colors.orange[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statColumn("Total Deliveries", count.toString()),
          _statColumn("Total Earnings", "₹${count * 50}"),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
