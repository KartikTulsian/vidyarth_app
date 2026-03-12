import 'package:flutter/material.dart';

class DeliverySupportPage extends StatelessWidget {
  const DeliverySupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Active Conversations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // Placeholder for Chat List
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.support_agent)),
              title: const Text("App Support"),
              subtitle: const Text("How can we help you today?"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () { /* Navigate to Support Chat */ },
            ),
          ),
          const Divider(height: 40),
          const Text("Help Center", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const ListTile(
            leading: Icon(Icons.help_outline),
            title: Text("Delivery Guidelines"),
          ),
          const ListTile(
            leading: Icon(Icons.payment),
            title: Text("Payment Issues"),
          ),
          const ListTile(
            leading: Icon(Icons.report_problem_outlined),
            title: Text("Report an Accident"),
          ),
        ],
      ),
    );
  }
}