import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/offer_model.dart';
import 'package:vidyarth_app/shared/models/stuff_model.dart';
import 'package:vidyarth_app/shared/widgets/searchable_tag_selector.dart';

class AddItemSheet extends StatefulWidget {
  final VoidCallback onItemAdded;
  final Stuff? itemToEdit;

  const AddItemSheet({super.key, required this.onItemAdded, this.itemToEdit});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedTags = [];

  // --- STATE ---
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isEditMode = false;

  bool _isLocating = false;
  double? _gpsLatitude;
  double? _gpsLongitude;

  // --- CONTROLLERS ---
  late TextEditingController titleCtrl;
  late TextEditingController subtitleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController originalPriceCtrl;
  late TextEditingController quantityCtrl;

  late TextEditingController authorCtrl;
  late TextEditingController publisherCtrl;
  late TextEditingController editionCtrl;
  late TextEditingController isbnCtrl;
  late TextEditingController pubYearCtrl;

  late TextEditingController brandCtrl;
  late TextEditingController modelCtrl;

  late TextEditingController languageCtrl;
  late TextEditingController subjectCtrl;
  late TextEditingController genreCtrl;
  late TextEditingController classSuitCtrl;
  late TextEditingController tagCtrl;

  late TextEditingController sellPriceCtrl;
  late TextEditingController rentalPriceCtrl;
  late TextEditingController maxRentalDaysCtrl;
  late TextEditingController securityDepositCtrl;
  late TextEditingController exchangeDescCtrl;
  late TextEditingController exchangeValueCtrl;
  late TextEditingController pickupAddressCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController pincodeCtrl;
  late TextEditingController termsCtrl;
  late TextEditingController instructionsCtrl;

  // --- DROPDOWN DEFAULTS ---
  StuffType _stuffType = StuffType.STATIONERY;
  ItemCondition _condition = ItemCondition.NEW;
  OfferType _offerType = OfferType.SELL;
  RentalUnit _rentalUnit = RentalUnit.DAY;
  BookType _bookType = BookType.TEXTBOOK;
  StationeryType _stationeryType = StationeryType.WRITING;
  VisiScope _visibility = VisiScope.PUBLIC;

  List<File> _newImages = [];
  List<String> _existingImageUrls = [];

  // --- LOGIC ---

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.itemToEdit != null;
    _initializeControllers();
  }

  void _initializeControllers() {
    final item = widget.itemToEdit;
    // Extract Offer Data if available
    final offer = (item?.offers.isNotEmpty ?? false) ? item!.offers.first : null;

    // Stuff Fields
    titleCtrl = TextEditingController(text: item?.title ?? '');
    subtitleCtrl = TextEditingController(text: item?.subtitle ?? '');
    descCtrl = TextEditingController(text: item?.description ?? '');
    originalPriceCtrl = TextEditingController(text: item?.originalPrice?.toString() ?? '');
    quantityCtrl = TextEditingController(text: item?.quantity.toString() ?? '1');

    // Academic/Book Fields
    authorCtrl = TextEditingController(text: item?.author ?? '');
    isbnCtrl = TextEditingController(text: item?.isbn ?? '');
    publisherCtrl = TextEditingController(text: item?.publisher ?? '');
    editionCtrl = TextEditingController(text: item?.edition ?? '');
    pubYearCtrl = TextEditingController(text: item?.publicationYear?.toString() ?? '');

    // Product/Other Fields
    brandCtrl = TextEditingController(text: item?.brand ?? '');
    modelCtrl = TextEditingController(text: item?.model ?? '');
    languageCtrl = TextEditingController(text: item?.language ?? '');
    subjectCtrl = TextEditingController(text: item?.subject ?? '');
    genreCtrl = TextEditingController(text: item?.genre ?? '');
    classSuitCtrl = TextEditingController(text: item?.classSuitability ?? '');
    tagCtrl = TextEditingController();

    // Offer Fields
    sellPriceCtrl = TextEditingController(text: offer?.price?.toString() ?? '');
    rentalPriceCtrl = TextEditingController(text: offer?.rentalPrice?.toString() ?? '');
    maxRentalDaysCtrl = TextEditingController(text: offer?.rentalPeriodDays?.toString() ?? '');
    securityDepositCtrl = TextEditingController(text: offer?.securityDeposit?.toString() ?? '');
    exchangeDescCtrl = TextEditingController(text: offer?.exchangeItemDescription ?? '');
    exchangeValueCtrl = TextEditingController(text: offer?.exchangeItemValue?.toString() ?? '');

    pickupAddressCtrl = TextEditingController(text: offer?.pickupAddress ?? '');
    cityCtrl = TextEditingController(text: offer?.city ?? '');
    stateCtrl = TextEditingController(text: offer?.state ?? '');
    pincodeCtrl = TextEditingController(text: offer?.pincode ?? '');
    termsCtrl = TextEditingController(text: offer?.termsConditions ?? '');
    instructionsCtrl = TextEditingController(text: offer?.specialInstructions ?? '');

    // Enum & Dropdown Defaults
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
      _existingImageUrls = List.from(item.imageUrls);
    }

    if (offer != null) {
      _offerType = offer.offerType;
      _rentalUnit = offer.rentalUnit;
      _visibility = offer.visibilityScope;
      _gpsLatitude = offer.latitude;
      _gpsLongitude = offer.longitude;
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _newImages.add(File(picked.path)));
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw 'Location permissions are denied';
      }
      if (permission == LocationPermission.deniedForever)
        throw 'Location permissions are permanently denied';

      // Get Position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _gpsLatitude = position.latitude;
      _gpsLongitude = position.longitude;

      // Auto-Fill Address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        setState(() {
          if (place.locality != null) cityCtrl.text = place.locality!;
          if (place.administrativeArea != null)
            stateCtrl.text = place.administrativeArea!;
          if (place.postalCode != null) pincodeCtrl.text = place.postalCode!;
          if (place.street != null && pickupAddressCtrl.text.isEmpty) {
            pickupAddressCtrl.text = place.street!;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location detected & address filled!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    // if (currentUserId == null) return;

    // Validate Images manually
    if (_newImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("At least one image is required *")),
      );
      return;
    }

    setState(() => _isLoading = true);
    print("DEBUG: Starting Submission...");

    try {
      double? finalLat;
      double? finalLng;

      final currentUserId = Supabase.instance.client.auth.currentUser!.id;

      // 1. Priority: User Captured GPS
      if (_gpsLatitude != null && _gpsLongitude != null) {
        finalLat = _gpsLatitude;
        finalLng = _gpsLongitude;
      } else {
        // 2. Fallback: Convert typed address to Coords
        try {
          String fullAddress =
              "${pickupAddressCtrl.text}, ${cityCtrl.text}, ${stateCtrl.text}, ${pincodeCtrl.text}";
          List<Location> locations = await locationFromAddress(fullAddress);
          if (locations.isNotEmpty) {
            finalLat = locations.first.latitude;
            finalLng = locations.first.longitude;
          } else {
            // Second fallback: Just City
            List<Location> cityLoc = await locationFromAddress(cityCtrl.text);
            if (cityLoc.isNotEmpty) {
              finalLat = cityLoc.first.latitude;
              finalLng = cityLoc.first.longitude;
            }
          }
        } catch (e) {
          print("Geocoding failed: $e");
        }
      }
      // 1. Prepare Stuff Data (Matches the new SQL schema)
      final stuff = Stuff(
        id: widget.itemToEdit?.id ?? '',
        ownerId: currentUserId, // Handled by Service
        title: titleCtrl.text.trim(),
        subtitle: subtitleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        type: _stuffType,
        condition: _condition,
        originalPrice: double.tryParse(originalPriceCtrl.text),
        quantity: int.tryParse(quantityCtrl.text) ?? 1,
        isInventory: false, // Students listing items
        author: authorCtrl.text.trim(),
        isbn: isbnCtrl.text.trim(),
        publisher: publisherCtrl.text.trim(),
        edition: editionCtrl.text.trim(),
        publicationYear: int.tryParse(pubYearCtrl.text.trim()),
        brand: brandCtrl.text.trim(),
        model: modelCtrl.text.trim(),
        language: languageCtrl.text.trim(),
        subject: subjectCtrl.text.trim(),
        genre: genreCtrl.text.trim(),
        classSuitability: classSuitCtrl.text.trim(),
        bookType: _stuffType == StuffType.BOOK ? _bookType.name : null,
        stationaryType: _stuffType == StuffType.STATIONERY
            ? _stationeryType.name
            : null,
        tags: _selectedTags,
      );

      // 2. Prepare Offer Data
      final offer = Offer(
        id: widget.itemToEdit?.offers.firstOrNull?.id,
        userId: currentUserId,
        offerType: _offerType,
        visibilityScope: _visibility,
        price: double.tryParse(sellPriceCtrl.text),
        rentalPrice: double.tryParse(rentalPriceCtrl.text),
        rentalUnit: _rentalUnit,
        rentalPeriodDays: int.tryParse(maxRentalDaysCtrl.text),
        securityDeposit: double.tryParse(securityDepositCtrl.text),
        exchangeItemDescription: exchangeDescCtrl.text,
        exchangeItemValue: double.tryParse(exchangeValueCtrl.text),
        pickupAddress: pickupAddressCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        state: stateCtrl.text.trim(),
        pincode: pincodeCtrl.text.trim(),
        latitude: finalLat,
        longitude: finalLng,
        termsConditions: termsCtrl.text.trim(),
        specialInstructions: instructionsCtrl.text.trim(),
      );

      print(
        "DEBUG: Sending to Service - Stuff: ${stuff.title}, Offer Type: ${offer.offerType}",
      );

      if (_isEditMode) {
        await _supabaseService.updateStuffWithOffer(
          stuff: stuff,
          offer: offer,
          newImages: _newImages,
          tags: _selectedTags,
        );
      } else {
        await _supabaseService.createStuffWithOffer(
          stuff: stuff,
          offer: offer,
          images: _newImages,
          tags: _selectedTags,
        );
      }

      if (mounted) {
        print("DEBUG: Submission Successful");
        Navigator.pop(context);
        widget.onItemAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? "Updated Successfully!" : "Listed Successfully!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      print("DEBUG ERROR: Submission failed: $e");
      print("DEBUG STACK: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
      print("Submission Error: $e"); // Check your debug console for this!
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
        // Keep height consistent but allow flexibility
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Fixes lag by not forcing a set height
          children: [
            // Handle bar
            Container(
              height: 5, width: 40,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5)),
            ),

            Expanded( // Replaced fixed Container/ListView with Expanded + ScrollView
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ...(_currentStep == 0 ? _buildStuffStep() : _buildOfferStep()),
                      if (_currentStep == 0) _buildImageSection(),

                      // Added: Spacer for keyboard
                      SizedBox(height: keyboardHeight > 0 ? keyboardHeight : 20),
                    ],
                  ),
                ),
              ),
            ),

            // Action Button stays at bottom
            _buildBottomActionButtons(),
          ],
        ),
      ),
    );
  }

  // --- STEP 1 WIDGETS ---
  List<Widget> _buildStuffStep() {
    return [
      const Text(
        "Step 1: Item Details",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 20),
      _sectionHeader("Basic Info"),
      _buildTextField("Title *", titleCtrl, isRequired: true),
      _buildTextField("Subtitle", subtitleCtrl),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded( // Added Expanded
            child: _buildDropdown(
              "Stuff Type",
              StuffType.values.map((e) => e.name).toList(),
              _stuffType.name,
                  (v) => setState(() => _stuffType = StuffType.values.byName(v!)),
            ),
          ),
          const SizedBox(width: 10), // Added spacing
          Expanded( // Added Expanded
            child: _buildDropdown(
              "Condition",
              ItemCondition.values.map((e) => e.name).toList(),
              _condition.name,
                  (v) => setState(() => _condition = ItemCondition.values.byName(v!)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 15),
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              "Original Price (₹) *",
              originalPriceCtrl,
              isNumber: true,
              isRequired: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildTextField("Quantity", quantityCtrl, isNumber: true),
          ),
        ],
      ),

      // Conditional
      if (_stuffType == StuffType.BOOK || _stuffType == StuffType.NOTES) ...[
        _buildTextField("Author", authorCtrl),
        _buildTextField("Subject", subjectCtrl),
        _buildTextField("Language", languageCtrl),
        if (_stuffType == StuffType.BOOK) ...[
          _buildDropdown(
            "Book Type",
            BookType.values.map((e) => e.name).toList(),
            _bookType.name,
                (v) => setState(() => _bookType = BookType.values.firstWhere((e) => e.name == v, orElse: () => BookType.TEXTBOOK)),
          ),
          _buildTextField("ISBN", isbnCtrl),
          _buildTextField("Publisher", publisherCtrl),
          _buildTextField("Edition", editionCtrl),
          _buildTextField("Publication Year", pubYearCtrl, isNumber: true),
        ],
      ],
      if (_stuffType == StuffType.ELECTRONICS || _stuffType == StuffType.STATIONERY || _stuffType == StuffType.OTHER) ...[
        _buildTextField("Brand", brandCtrl),
        _buildTextField("Model", modelCtrl),
        if (_stuffType == StuffType.STATIONERY)
          _buildDropdown(
            "Stationery Type",
            StationeryType.values.map((e) => e.name).toList(),
            _stationeryType.name,
                (v) => setState(() => _stationeryType = StationeryType.values.firstWhere((e) => e.name == v, orElse: () => StationeryType.WRITING)),
          ),
      ],
      _sectionHeader("Description"),
      _buildTextField("Detailed Description", descCtrl, maxLines: 4),

      const SizedBox(height: 20),
      SearchableTagSelector(
        selectedTags: _selectedTags, // Define this in your _AddItemSheetState
        onTagsChanged: (tags) => setState(() => _selectedTags = tags),
      ),
      const SizedBox(height: 20),
    ];
  }

  // --- STEP 2 WIDGETS ---
  List<Widget> _buildOfferStep() {
    return [
      const Text(
        "Step 2: Pricing & Shop Info",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 20),
      _sectionHeader("What would you like to do? *"),
      _buildDropdown(
        "Offer Type",
        OfferType.values.map((e) => e.name).toList(),
        _offerType.name,
            (v) => setState(() => _offerType = OfferType.values.byName(v!)),
      ),

      const SizedBox(height: 20),

      // Conditional Pricing
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
                "Rental Price *",
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
        _buildTextField(
          "Max Rental Duration",
          maxRentalDaysCtrl,
          isNumber: true,
        ),
        _buildTextField(
          "Security Deposit (₹)",
          securityDepositCtrl,
          isNumber: true,
        ),
      ],

      if (_offerType == OfferType.EXCHANGE) ...[
        _buildTextField(
          "What do you want in exchange? *",
          exchangeDescCtrl,
          isRequired: true,
        ),
        _buildTextField("Est. Value (₹)", exchangeValueCtrl, isNumber: true),
      ],

      if (_offerType == OfferType.LEND || _offerType == OfferType.SHARE) ...[
        const Text("This item will be listed for free lending/sharing within your community.", style: TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic)),
        const SizedBox(height: 10),
        _buildTextField("Security Deposit (if any)", securityDepositCtrl, isNumber: true),
      ],

      _sectionHeader("Pickup Location"),

      Container(
        margin: const EdgeInsets.only(bottom: 15),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLocating ? null : _detectLocation,
          icon: _isLocating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.my_location, color: Colors.white),
          label: Text(
            _isLocating ? "Detecting..." : "Use Current Location",
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      _buildTextField("Address Line", pickupAddressCtrl),
      Row(
        children: [
          Expanded(child: _buildTextField("City", cityCtrl)),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("State", stateCtrl)),
          const SizedBox(width: 10),
          Expanded(
            child: _buildTextField("Pincode", pincodeCtrl, isNumber: true),
          ),
        ],
      ),

      _sectionHeader("Visibility"),
      _buildDropdown(
        "Who can see this?",
        VisiScope.values.map((e) => e.name).toList(),
        _visibility.name,
            (v) => setState(() => _visibility = VisiScope.values.byName(v!)),
      ),

      _sectionHeader("Terms & Instructions"),
      _buildTextField("Terms & Conditions", termsCtrl, maxLines: 3),
      _buildTextField("Special Instructions", instructionsCtrl, maxLines: 3),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea( // FIX: Prevents system button overlap
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
                    : (_currentStep == 0 ? () => setState(() => _currentStep = 1) : _submitForm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_currentStep == 0 ? "Next: Offer Details" : (_isEditMode ? "Update" : "Create")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _sectionHeader(String title, {Color? color}) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      margin: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
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
          alignLabelWithHint: maxLines > 1,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (val) {
          if (isRequired && (val == null || val.trim().isEmpty)) {
            return "Required field";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("Images *"),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // 1. Add Button
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.add_a_photo), Text("Add")],
                  ),
                ),
                // 2. Existing Images (Network)
                ..._existingImageUrls.map(
                  (url) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        Image.network(
                          url,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            onTap: () =>
                                setState(() => _existingImageUrls.remove(url)),
                            child: const Icon(Icons.cancel, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 3. New Images (File)
                ..._newImages.map(
                  (file) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        Image.file(
                          file,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            onTap: () =>
                                setState(() => _newImages.remove(file)),
                            child: const Icon(Icons.cancel, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String currentVal,
    Function(String?) onChanged,
  ) {
    final effectiveValue = items.contains(currentVal) ? currentVal : items.first;

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
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
