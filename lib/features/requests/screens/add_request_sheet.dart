import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/request_model.dart';

class AddRequestSheet extends StatefulWidget {
  final VoidCallback onRequestAdded;
  const AddRequestSheet({super.key, required this.onRequestAdded});

  @override
  State<AddRequestSheet> createState() => _AddRequestSheetState();
}

class _AddRequestSheetState extends State<AddRequestSheet> {
  final _descController = TextEditingController();
  StuffType _selectedType = StuffType.BOOK;
  UrgentLevel _selectedUrgency = UrgentLevel.MEDIUM;
  bool _isSubmitting = false;
  VisiScope _selectedScope = VisiScope.PUBLIC;
  double _selectedRange = 2.0;
  Position? _currentPosition;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Post Urgent Need",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<StuffType>(
            value: _selectedType,
            items: StuffType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                .toList(),
            onChanged: (val) => setState(() => _selectedType = val!),
            decoration: const InputDecoration(labelText: "What do you need?"),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<UrgentLevel>(
            value: _selectedUrgency,
            items: UrgentLevel.values
                .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                .toList(),
            onChanged: (val) => setState(() => _selectedUrgency = val!),
            decoration: const InputDecoration(labelText: "Urgency Level"),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Describe what you need and for how long...",
              border: OutlineInputBorder(),
            ),
          ),
          _buildDropdown(
            "Visibility Scope",
            VisiScope.values.map((e) => e.name).toList(),
            _selectedScope.name,
            (val) {
              setState(() => _selectedScope = VisiScope.values.byName(val!));
            },
          ),

          const Text(
            "Range (km)",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Slider(
            value: _selectedRange,
            min: 0.5,
            max: 2.0,
            divisions: 9,
            label: "${_selectedRange}km",
            onChanged: (val) => setState(() => _selectedRange = val),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "POST URGENT REQUEST",
                    style: TextStyle(color: Colors.white),
                  ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _submitRequest() async {
    if (_descController.text.isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      // 1. Fetch current location before submitting
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint(
        "DEBUG: Submitting request with Range: $_selectedRange KM, Scope: ${_selectedScope.name}",
      );

      final req = RequestModel(
        id: '',
        stuffType: _selectedType,
        description: _descController.text,
        urgencyLevel: _selectedUrgency,
        visibilityScope: _selectedScope,
        radiusKm: _selectedRange,
        lat: position.latitude,
        lng: position.longitude,
      );

      debugPrint(
        "DEBUG: Final Request Object - Lat: ${req.lat}, Lng: ${req.lng}",
      );
      await SupabaseService().createUrgentRequest(req);
      widget.onRequestAdded();
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Location Error: $e");
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not get location. Please enable GPS.")),
      );
    }
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String currentVal,
    Function(String?) onChanged,
  ) {
    final effectiveValue = items.contains(currentVal)
        ? currentVal
        : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Keep it tight
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: effectiveValue,
          isExpanded: true, // Crucial for use inside Rows
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
