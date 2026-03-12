import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/shared/models/delivery_model.dart';

class ActiveDeliveriesPage extends StatefulWidget {
  const ActiveDeliveriesPage({super.key});

  @override
  State<ActiveDeliveriesPage> createState() => _ActiveDeliveriesPageState();
}

class _ActiveDeliveriesPageState extends State<ActiveDeliveriesPage> {
  final SupabaseService _service = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _service.getActiveDeliveries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No active deliveries found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(13),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final delivery = snapshot.data![index];
              return _buildDeliveryCard(delivery);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeliveryCard(Delivery delivery) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Order ID: ${delivery.id.substring(0, 8)}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                _buildStatusBadge(delivery.status.name),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: const Text("Pickup Location"),
              subtitle: Text("${delivery.pickupLat}, ${delivery.pickupLng}"),
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: const Text("Drop-off Location"),
              subtitle: Text("${delivery.dropLat}, ${delivery.dropLng}"),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _updateStatusDialog(delivery),
                child: const Text("UPDATE STATUS"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == 'ASSIGNED' ? Colors.blue[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status, style: TextStyle(fontSize: 12, color: Colors.orange[900])),
    );
  }

  void _updateStatusDialog(Delivery delivery) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text("Mark as Picked Up"),
            onTap: () async {
              await _service.updateDeliveryStatus(
                  deliveryId: delivery.id,
                  status: 'PICKED_UP'
              );
              Navigator.pop(context);
              setState(() {}); // Refresh list
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text("Mark as Delivered"),
            onTap: () async {
              await _service.updateDeliveryStatus(
                  deliveryId: delivery.id,
                  status: 'DELIVERED'
              );
              Navigator.pop(context);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
