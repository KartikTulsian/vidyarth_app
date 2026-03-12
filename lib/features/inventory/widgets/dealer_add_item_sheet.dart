import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/dealer_profile_model.dart';
import 'package:vidyarth_app/shared/models/offer_model.dart';
import 'package:vidyarth_app/shared/models/profile_model.dart';
import 'package:vidyarth_app/shared/models/stuff_model.dart';
import 'package:vidyarth_app/shared/widgets/searchable_tag_selector.dart';

class DealerAddItemSheet extends StatefulWidget {
  final VoidCallback onItemAdded;
  final Stuff? itemToEdit;
  const DealerAddItemSheet({
    super.key,
    required this.onItemAdded,
    this.itemToEdit,
  });

  @override
  State<DealerAddItemSheet> createState() => _DealerAddItemSheetState();
}

class _DealerAddItemSheetState extends State<DealerAddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _service = SupabaseService();
  final ImagePicker _picker = ImagePicker();

  List<String> _selectedTags = [];
  DealerProfile? _dealerShopInfo;
  ProfileModel? _userProfile;

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isEditMode = false;

  // --- CONTROLLERS ---
  late TextEditingController titleCtrl,
      subtitleCtrl,
      descCtrl,
      originalPriceCtrl;
  late TextEditingController authorCtrl,
      isbnCtrl,
      publisherCtrl,
      editionCtrl,
      pubYearCtrl;
  late TextEditingController brandCtrl,
      modelCtrl,
      subjectCtrl,
      languageCtrl,
      genreCtrl,
      stockCtrl,
      quantityCtrl,
      classSuitCtrl;

  // Offer Fields
  late TextEditingController sellPriceCtrl,
      rentalPriceCtrl,
      maxDurationCtrl,
      depositCtrl,
      exchangeDescCtrl,
      exchangeValueCtrl;
  late TextEditingController offerQtyCtrl, termsCtrl, instructionsCtrl;

  // --- DROPDOWNS ---
  StuffType _stuffType = StuffType.STATIONERY;
  ItemCondition _condition = ItemCondition.NEW;
  OfferType _offerType = OfferType.SELL;
  RentalUnit _rentalUnit = RentalUnit.DAY;
  BookType _bookType = BookType.TEXTBOOK;
  StationeryType _stationeryType = StationeryType.WRITING;

  File? _newImage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.itemToEdit != null;
    _initializeControllers();
    _fetchShopDetails();
  }

  void _fetchShopDetails() async {
    print("DEBUG: Fetching Unified Profile for Dealer...");
    try {
      final userData = await _service.getUnifiedProfile();
      if (userData != null && mounted) {
        setState(() {
          // Fix: Properly assign both business info and personal profile info
          _dealerShopInfo = userData.dealerProfile;
          _userProfile = userData.profile;
        });
        print("DEBUG: Shop Info Loaded: ${_dealerShopInfo?.shopName}");
        print("DEBUG: Profile Address Loaded: ${_userProfile?.address}");
      }
    } catch (e) {
      print("DEBUG ERROR: _fetchShopDetails failed: $e");
    }
  }

  void _initializeControllers() {
    final item = widget.itemToEdit;
    // Get the first offer if it exists
    final offer = (item?.offers.isNotEmpty ?? false)
        ? item!.offers.first
        : null;

    // Stuff Fields
    titleCtrl = TextEditingController(text: item?.title ?? '');
    subtitleCtrl = TextEditingController(text: item?.subtitle ?? '');
    descCtrl = TextEditingController(text: item?.description ?? '');
    originalPriceCtrl = TextEditingController(
      text: item?.originalPrice?.toString() ?? '',
    );

    // Specific category fields
    authorCtrl = TextEditingController(text: item?.author ?? '');
    isbnCtrl = TextEditingController(text: item?.isbn ?? '');
    publisherCtrl = TextEditingController(text: item?.publisher ?? '');
    editionCtrl = TextEditingController(text: item?.edition ?? '');
    pubYearCtrl = TextEditingController(
      text: item?.publicationYear?.toString() ?? '',
    );
    brandCtrl = TextEditingController(text: item?.brand ?? '');
    modelCtrl = TextEditingController(text: item?.model ?? '');

    subjectCtrl = TextEditingController(text: item?.subject ?? '');
    languageCtrl = TextEditingController(text: item?.language ?? 'English');
    genreCtrl = TextEditingController(text: item?.genre ?? '');
    classSuitCtrl = TextEditingController(text: item?.classSuitability ?? '');
    quantityCtrl = TextEditingController(
      text: item?.quantity.toString() ?? '1',
    );
    stockCtrl = TextEditingController(
      text: item?.stockQuantity.toString() ?? '1',
    );

    // Offer Fields
    sellPriceCtrl = TextEditingController(text: offer?.price?.toString() ?? '');
    rentalPriceCtrl = TextEditingController(
      text: offer?.rentalPrice?.toString() ?? '',
    );
    maxDurationCtrl = TextEditingController(
      text: offer?.rentalPeriodDays?.toString() ?? '',
    );
    depositCtrl = TextEditingController(
      text: offer?.securityDeposit?.toString() ?? '',
    );
    exchangeDescCtrl = TextEditingController(
      text: offer?.exchangeItemDescription ?? '',
    );
    exchangeValueCtrl = TextEditingController(
      text: offer?.exchangeItemValue?.toString() ?? '',
    );
    offerQtyCtrl = TextEditingController(
      text: offer?.quantityAvailable?.toString() ?? '1',
    );

    termsCtrl = TextEditingController(text: offer?.termsConditions ?? '');
    instructionsCtrl = TextEditingController(
      text: offer?.specialInstructions ?? '',
    );

    // _selectedTags = item?.tags != null ? List.from(item!.tags) : [];
    // _existingImageUrl = item?.imageUrls.isNotEmpty == true ? item!.imageUrls.first : null;

    if (item != null) {
      _stuffType = item.type;
      _condition = item.condition;
      _bookType = BookType.values.firstWhere(
        (e) => e.name == item.bookType,
        orElse: () => BookType.TEXTBOOK,
      );
      _stationeryType = StationeryType.values.firstWhere(
        (e) => e.name == item.stationaryType,
        orElse: () => StationeryType.WRITING,
      );
      _selectedTags = List.from(item.tags);
      _existingImageUrl = item.imageUrls.isNotEmpty
          ? item.imageUrls.first
          : null;
    }

    if (offer != null) {
      _offerType = offer.offerType;
      _rentalUnit = offer.rentalUnit;
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newImage = File(picked.path));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dealerShopInfo == null && _userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Location information not found.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    print("DEBUG: Starting Submission...");

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;

      final stuff = Stuff(
        id: widget.itemToEdit?.id ?? '', // ID handled by DB on insert
        ownerId: currentUserId, // Handled by Service
        title: titleCtrl.text.trim(),
        subtitle: subtitleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        type: _stuffType,
        condition: _condition,
        originalPrice: double.tryParse(originalPriceCtrl.text),
        isInventory: true,
        author: authorCtrl.text.trim(),
        isbn: isbnCtrl.text.trim(),
        publisher: publisherCtrl.text.trim(),
        edition: editionCtrl.text.trim(),
        publicationYear: int.tryParse(pubYearCtrl.text),
        brand: brandCtrl.text.trim(),
        model: modelCtrl.text.trim(),
        subject: subjectCtrl.text.trim(),
        language: languageCtrl.text.trim(),
        genre: genreCtrl.text.trim(),
        classSuitability: classSuitCtrl.text.trim(),
        bookType: _stuffType == StuffType.BOOK ? _bookType.name : null,
        stationaryType: _stuffType == StuffType.STATIONERY
            ? _stationeryType.name
            : null,
        quantity: int.tryParse(quantityCtrl.text) ?? 1,
        stockQuantity: int.tryParse(stockCtrl.text) ?? 1,
        tags: _selectedTags,
      );

      final offer = Offer(
        id: widget.itemToEdit?.offers.firstOrNull?.id,
        userId: currentUserId,
        offerType: _offerType,
        price: double.tryParse(sellPriceCtrl.text),
        rentalPrice: double.tryParse(rentalPriceCtrl.text),
        rentalUnit: _rentalUnit,
        rentalPeriodDays: int.tryParse(maxDurationCtrl.text),
        securityDeposit: double.tryParse(depositCtrl.text),
        exchangeItemDescription: exchangeDescCtrl.text,
        exchangeItemValue: double.tryParse(exchangeValueCtrl.text),
        quantityAvailable: int.tryParse(offerQtyCtrl.text) ?? 1,

        pickupAddress:
            _dealerShopInfo?.businessAddress ?? _userProfile?.address,
        city: _userProfile?.city,
        state: _userProfile?.state,
        pincode: _userProfile?.pincode,
        latitude: _dealerShopInfo?.latitude ?? _userProfile?.latitude,
        longitude: _dealerShopInfo?.longitude ?? _userProfile?.longitude,

        termsConditions: termsCtrl.text.trim(),
        specialInstructions: instructionsCtrl.text.trim(),
        visibilityScope: VisiScope.PUBLIC,
      );

      print(
        "DEBUG: Sending to Service - Stuff: ${stuff.title}, Offer Type: ${offer.offerType}",
      );

      if (_isEditMode) {
        await _service.updateStuffWithOffer(
          stuff: stuff,
          offer: offer,
          newImages: _newImage != null ? [_newImage!] : null,
          tags: _selectedTags,
        );
      } else {
        await _service.createStuffWithOffer(
          stuff: stuff,
          offer: offer,
          images: _newImage != null ? [_newImage!] : [],
          tags: _selectedTags,
        );
      }

      print("DEBUG: Submission Successful");
      widget.onItemAdded();
      Navigator.pop(context);
    } catch (e, stack) {
      print("DEBUG ERROR: Submission failed: $e");
      print("DEBUG STACK: $stack");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        // FIX: Avoid system button overlap
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 5,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Flexible(
              // FIX: Allows the keyboard to push up the content
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ...(_currentStep == 0 ? _buildStuffStep() : _buildOfferStep()),

                      // This is the "Magic" Spacer:
                      // It adds space equal to the keyboard height so the
                      // focused text field is always visible.
                      SizedBox(height: keyboardHeight > 0 ? keyboardHeight : 20),
                    ],
                  ),
                ),
              ),
            ),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStuffStep() {
    return [
      const Text(
        "Step 1: Item Details",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 20),
      _buildImageSelector(),
      _buildTextField("Title *", titleCtrl, isRequired: true),
      _buildTextField("Subtitle", subtitleCtrl),
      _buildDropdown(
        "Stuff Type",
        StuffType.values.map((e) => e.name).toList(),
        _stuffType.name,
        (v) => setState(() => _stuffType = StuffType.values.byName(v!)),
      ),
      _buildDropdown(
        "Condition",
        ItemCondition.values.map((e) => e.name).toList(),
        _condition.name,
        (v) => setState(() => _condition = ItemCondition.values.byName(v!)),
      ),
      const SizedBox(height: 15),

      if (_stuffType == StuffType.BOOK || _stuffType == StuffType.NOTES) ...[
        _buildTextField("Author", authorCtrl),
        _buildTextField("Subject", subjectCtrl),
        _buildTextField("Language", languageCtrl),
        if (_stuffType == StuffType.BOOK) ...[
          _buildDropdown(
            "Book Type",
            BookType.values.map((e) => e.name).toList(),
            _bookType.name,
            (v) => setState(() => _bookType = BookType.values.byName(v!)),
          ),
          _buildTextField("ISBN", isbnCtrl),
          _buildTextField("Publisher", publisherCtrl),
          _buildTextField("Edition", editionCtrl),
          _buildTextField("Publication Year", pubYearCtrl, isNumber: true),
        ],
      ],
      if (_stuffType == StuffType.ELECTRONICS ||
          _stuffType == StuffType.STATIONERY) ...[
        _buildTextField("Brand", brandCtrl),
        _buildTextField("Model", modelCtrl),
        if (_stuffType == StuffType.STATIONERY)
          _buildDropdown(
            "Stationery Type",
            StationeryType.values.map((e) => e.name).toList(),
            _stationeryType.name,
            (v) => setState(
              () => _stationeryType = StationeryType.values.byName(v!),
            ),
          ),
      ],
      _buildTextField("Description", descCtrl, maxLines: 3),
      const SizedBox(height: 15),
      _buildTextField(
        "Original Price (Optional)",
        originalPriceCtrl,
        isNumber: true,
      ),
      const SizedBox(height: 15),
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              "Unit Size (e.g. 5 for pack)",
              quantityCtrl,
              isNumber: true,
            ),
          ), //
          const SizedBox(width: 10),
          Expanded(
            child: _buildTextField(
              "Total Stock Count *",
              stockCtrl,
              isNumber: true,
              isRequired: true,
            ),
          ), //
        ],
      ),
      const SizedBox(height: 10),
      SearchableTagSelector(
        selectedTags: _selectedTags,
        onTagsChanged: (tags) => setState(() => _selectedTags = tags),
      ),
    ];
  }

  List<Widget> _buildOfferStep() {
    return [
      const Text(
        "Step 2: Pricing & Shop Info",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.shop, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Pickup location set to your business address: ${_dealerShopInfo?.businessAddress ?? 'Loading...'}",
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      _buildTextField(
        "Quantity to List for Sale",
        offerQtyCtrl,
        isNumber: true,
        isRequired: true,
      ),
      _buildDropdown(
        "Offer Type",
        OfferType.values.map((e) => e.name).toList(),
        _offerType.name,
        (v) => setState(() => _offerType = OfferType.values.byName(v!)),
      ),

      if (_offerType == OfferType.SELL)
        _buildTextField(
          "Selling Price (₹) *",
          sellPriceCtrl,
          isNumber: true,
          isRequired: true,
        ),

      if (_offerType == OfferType.RENT) ...[
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                "Rental Price",
                rentalPriceCtrl,
                isNumber: true,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDropdown(
                "Unit",
                RentalUnit.values.map((e) => e.name).toList(),
                _rentalUnit.name,
                (v) =>
                    setState(() => _rentalUnit = RentalUnit.values.byName(v!)),
              ),
            ),
          ],
        ),
        _buildTextField("Security Deposit (₹)", depositCtrl, isNumber: true),
        _buildTextField(
          "Max Rental Duration (Days)",
          maxDurationCtrl,
          isNumber: true,
        ),
      ],
      if (_offerType == OfferType.EXCHANGE) ...[
        _buildTextField(
          "What do you want in exchange?",
          exchangeDescCtrl,
          isRequired: true,
        ),
        _buildTextField(
          "Est. Value of required item",
          exchangeValueCtrl,
          isNumber: true,
        ),
      ],

      const SizedBox(height: 20),
      _buildTextField("Terms & Conditions", termsCtrl, maxLines: 2),
      _buildTextField("Special Instructions", instructionsCtrl, maxLines: 2),
    ];
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep == 1)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 55)),
                  child: const Text("Back"),
                ),
              ),
            if (_currentStep == 1) const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_currentStep == 0
                    ? () => setState(() => _currentStep = 1)
                    : _submitForm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(0, 55),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : Text(_currentStep == 0 ? "Next: Pricing" : "List Item"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _newImage != null
              ? Image.file(
                  _newImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
              ? Image.network(
                  _existingImageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (v) =>
            (isRequired && (v == null || v.isEmpty)) ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String currentVal,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          value: currentVal,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
