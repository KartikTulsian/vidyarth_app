import 'package:flutter/material.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/shared/models/tag_model.dart';

class SearchableTagSelector extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;

  const SearchableTagSelector({super.key, required this.selectedTags, required this.onTagsChanged});

  @override
  State<SearchableTagSelector> createState() => _SearchableTagSelectorState();
}

class _SearchableTagSelectorState extends State<SearchableTagSelector> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Tag> _allTags = [];
  List<Tag> _filteredTags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  void _loadTags() async {
    final tags = await _service.getAllTags();
    if (mounted) {
      setState(() {
        _allTags = tags;
        _filteredTags = tags;
      });
    }
  }

  void _filterTags(String query) {
    setState(() {
      _filteredTags = _allTags
          .where((t) => t.name.toLowerCase().contains(query.toLowerCase())) //
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tags (Search or Create)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: "Search Tags",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blue),
              onPressed: () {
                if (_searchCtrl.text.isNotEmpty && !widget.selectedTags.contains(_searchCtrl.text)) {
                  widget.selectedTags.add(_searchCtrl.text.toLowerCase());
                  widget.onTagsChanged(widget.selectedTags);
                  _searchCtrl.clear();
                  _filterTags("");
                }
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: _filterTags,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: widget.selectedTags.map((tag) => Chip(
            label: Text(tag),
            onDeleted: () {
              widget.selectedTags.remove(tag);
              widget.onTagsChanged(widget.selectedTags);
              setState(() {}); // Refresh UI
            },
          )).toList(),
        ),
        if (_searchCtrl.text.isNotEmpty && _filteredTags.isNotEmpty)
          Container(
            height: 150,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
                ]
            ),
            child: ListView.builder(
                itemCount: _filteredTags.length,
                itemBuilder: (context, i) {
                  final tag = _filteredTags[i];
                  return ListTile(
                    title: Text(tag.name), //
                    onTap: () {
                      if (!widget.selectedTags.contains(tag.name.toLowerCase())) {
                        widget.selectedTags.add(tag.name.toLowerCase());
                        widget.onTagsChanged(widget.selectedTags);
                      }
                      _searchCtrl.clear();
                      _filterTags("");
                    },
                  );
                }
            ),
          )
      ],
    );
  }
}
