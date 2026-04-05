import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/core/services/supabase_service.dart';
import 'package:vidyarth_app/features/requests/screens/request_chat_page.dart';
import 'package:vidyarth_app/features/shop/screens/shop_page.dart';
import 'package:vidyarth_app/features/trade/screens/item_detail_page.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/delivery_profile_model.dart';
import 'package:vidyarth_app/shared/models/offer_model.dart';
import 'package:vidyarth_app/shared/models/stuff_model.dart';
import 'package:vidyarth_app/shared/models/user_model.dart';

class BrowsePage extends StatefulWidget {
  final VoidCallback onLogout;
  const BrowsePage({super.key, required this.onLogout});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final SupabaseService _supabaseService = SupabaseService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final _supabase = Supabase.instance.client;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  final String? _currentUserId = Supabase.instance.client.auth.currentUser?.id;
  // --- LOCATION STATE ---
  LatLng? _myLocation;
  final LatLng _defaultLocation = const LatLng(22.5726, 88.3639);

  // --- DATA STATE ---
  List<Offer> _allOffers = [];
  List<Offer> _filteredOffers = [];
  UserModel? _currentUserModel;
  String? _mySchoolCollegeId;
  bool _isLoading = true;
  List<DeliveryProfile> _liveRiders = [];

  List<Map<String, dynamic>> _dealerShops = [];

  // --- FILTER STATE ---
  double _radiusKm = 10.0;
  bool _showMyCollegeOnly = false;
  final Set<String> _notifiedRequestIds = {};
  final Set<String> _viewedRequestIds = {};
  StreamSubscription? _requestsSubscription;
  // Position? _userPosition;

  // Multi-select filters
  final List<String> _selectedStuffTypes = [];
  final List<String> _selectedOfferTypes = [];
  final List<String> _selectedConditions = [];

  // Options for filters
  final List<String> _stuffTypeOptions = StuffType.values.map((e) => e.name).toList();
  final List<String> _offerTypeOptions = OfferType.values.map((e) => e.name).toList();
  final List<String> _conditionOptions = ItemCondition.values.map((e) => e.name).toList();

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _setupRequestNotificationListener();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _localNotifications.initialize(settings: settings);

    // Create the channel for Android (Mandatory for Android 8.0+)
    const channel = AndroidNotificationChannel(
      'urgent_channel',
      'Urgent Requests',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _setupRequestNotificationListener() {
    _requestsSubscription = _supabase
        .from('requests')
        .stream(primaryKey: ['request_id'])
        .eq('status', 'OPEN')
        .listen((List<Map<String, dynamic>> data) {
      debugPrint("DEBUG: Received ${data.length} open requests from stream");
      _checkAndNotifyNearby(data);
    });
  }

  void _checkAndNotifyNearby(List<Map<String, dynamic>> requests) async {
    if (_myLocation == null) {
      debugPrint("DEBUG: Skipping notification check - Position not ready");
      return;
    }

    for (var req in requests) {
      final String reqId = req['request_id'];

      // Skip if already notified or if it's the current user's own request
      if (_notifiedRequestIds.contains(reqId) || req['user_id'] == _currentUserId) continue;

      try {
        double distance = Geolocator.distanceBetween(
            _myLocation!.latitude,
            _myLocation!.longitude,
            (req['location_latitude'] as num).toDouble(),
            (req['location_longitude'] as num).toDouble()
        ) / 1000;

        double radius = (req['radius_km'] as num?)?.toDouble() ?? 2.0;

        if (distance <= radius) {
          debugPrint("DEBUG: Nearby request detected ($distance km). Notifying user...");
          _notifiedRequestIds.add(reqId); // Mark as notified
          _showSystemNotification(
              req['stuff_type'] ?? "Item",
              req['description'] ?? "Someone nearby needs an item urgently."
          );
        }
      } catch (e) {
        debugPrint("DEBUG ERROR: Notification distance check failed: $e");
      }
    }
  }

  Future<void> _showSystemNotification(String type, String desc) async {
    const androidDetails = AndroidNotificationDetails(
      'urgent_channel',
      'Urgent Requests',
      channelDescription: 'Notifications for nearby urgent trade requests',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    try {
      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _localNotifications.show(
        id: notificationId,
        notificationDetails: platformDetails,
        payload: 'urgent_request',
      );
      debugPrint("DEBUG: Notification sent successfully.");
    } catch (e) {
      debugPrint("DEBUG ERROR: _localNotifications.show failed: $e");
    }
  }

  Future<void> _initializeData() async {
    try {
      await _getCurrentLocation();
      if (!mounted) return;
      await _fetchUserData();
      await _fetchOffers();
    } catch (e) {
      print("Init Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // 1. Try Last Known Position (Instant)
      Position? position = await Geolocator.getLastKnownPosition();

      // 2. If null, try Current Position with timeout
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
      }

      if (position != null && mounted) {
        setState(() {
          _myLocation = LatLng(position!.latitude, position.longitude);
        });
        _mapController.move(_myLocation!, 14.0);
      }
    } catch (e) {
      print("Location Error: $e");
    }
  }

  Future<void> _fetchUserData() async {
    final user = await _supabaseService.getUnifiedProfile();
    if (mounted && user != null) {
      setState(() {
        _currentUserModel = user;
        _mySchoolCollegeId = user.profile?.schoolCollegeId;
      });
    }
  }

  Future<void> _fetchOffers() async {
    try {
      final offers = await _supabaseService.getNearbyOffers();

      final shopsResponse= await Supabase.instance.client.from('dealer_shops').select();

      if (mounted) {
        setState(() {
          _allOffers = offers;
          _dealerShops = List<Map<String, dynamic>>.from(shopsResponse);
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      print("Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRiders() async {
    final riders = await _supabaseService.getLiveRiders();
    if (mounted) {
      setState(() {
        _liveRiders = riders;
      });
    }
  }

  // void _showNearbyRequests(List<Map<String, dynamic>> requests) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (ctx) => ListView.builder(
  //       itemCount: requests.length,
  //       itemBuilder: (context, i) {
  //         final req = requests[i];
  //         return ListTile(
  //           leading: const Icon(Icons.bolt, color: Colors.orange),
  //           title: Text("Need: ${req['stuff_type']}"),
  //           subtitle: Text(req['description']),
  //           trailing: ElevatedButton(
  //             onPressed: () {
  //               Navigator.pop(ctx);
  //               Navigator.push(context, MaterialPageRoute(
  //                 builder: (context) => ChatPage(
  //                   receiverId: req['user_id'],
  //                   receiverName: "Urgent Requester",
  //                   offerId: null,
  //                 ),
  //               ));
  //             },
  //             child: const Text("Chat"),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredOffers = _allOffers.where((offer) {
        if (_currentUserId != null && offer.userId == _currentUserId) {
          return false;
        }

        final stuff = offer.stuff;
        if (stuff == null) return false;

        // 1. Search Text (Title or Description)
        if (query.isNotEmpty) {
          final title = stuff.title.toLowerCase();
          final desc = stuff.description?.toLowerCase() ?? '';
          if (!title.contains(query) && !desc.contains(query)) return false;
        }

        // 2. Stuff Type Filter
        if (_selectedStuffTypes.isNotEmpty) {
          if (!_selectedStuffTypes.contains(stuff.type.name)) return false;
        }

        // 3. Offer Type Filter
        if (_selectedOfferTypes.isNotEmpty) {
          if (!_selectedOfferTypes.contains(offer.offerType.name)) return false;
        }

        // 4. Condition Filter
        if (_selectedConditions.isNotEmpty) {
          if (!_selectedConditions.contains(stuff.condition.name)) return false;
        }

        // 5. My College Filter
        if (_showMyCollegeOnly && _mySchoolCollegeId != null) {
          final sellerCollegeId = offer.seller?.profile?.schoolCollegeId;
          if (sellerCollegeId != _mySchoolCollegeId) return false;
        }

        // 6. Distance Filter
        final lat = offer.latitude;
        final lng = offer.longitude;
        if (lat == null || lng == null) return false;

        if (_myLocation != null) {
          final Distance distance = const Distance();
          final double km = distance.as(
            LengthUnit.Kilometer,
            _myLocation!,
            LatLng(lat, lng),
          );
          if (km > _radiusKm) return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // --- MAP LAYER ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myLocation ?? _defaultLocation,
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                // Carto Positron provides that clean, minimalist "light" look
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.vidyarth_app',
                retinaMode: true,
              ),
              MarkerLayer(
                markers: [
                  // User Location Pin
                  if (_myLocation != null)
                    Marker(
                      point: _myLocation!,
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(
                                BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Offer Pins
                  ..._filteredOffers.map((offer) {
                    final lat = offer.latitude;
                    final lng = offer.longitude;
                    if (lat == null || lng == null)
                      return const Marker(
                        point: LatLng(0, 0),
                        child: SizedBox(),
                      );

                    return Marker(
                      point: LatLng(lat, lng),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showOfferDetails(offer),
                        child: _buildCustomPin(offer.stuff?.type.name ?? 'OTHER'),
                      ),
                    );
                  }),

                  ..._dealerShops.map((shop) {
                    return Marker(
                      point: LatLng(shop['latitude'], shop['longitude']),
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShopPage(
                              dealerId: shop['dealer_id'],
                              shopName: shop['shop_name'],
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.orange, width: 2),
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: const Icon(Icons.store, color: Colors.orange, size: 20),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              color: Colors.orange,
                              child: Text(
                                shop['shop_name'],
                                style: const TextStyle(color: Colors.white, fontSize: 8),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }),

                  ..._liveRiders.map(
                    (rider) => Marker(
                      point: LatLng(
                        rider.currentLat ?? 0.0,
                        rider.currentLng ?? 0.0,
                      ),
                      width: 45,
                      height: 45,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.directions_bike,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // --- FLOATING SEARCH & FILTER BAR ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Where to pick up from?",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF44FFD3),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune),
                          onPressed: _showFilterSheet,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Filter Button
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.tune, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 70, // Placed below search bar
            right: 16,
            child: _buildUrgentRequestFAB(),
          ),

          // --- LOADING INDICATOR ---
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),

      // Floating GPS Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.gps_fixed, color: Colors.black),
        onPressed: () {
          if (_myLocation != null) {
            _mapController.move(_myLocation!, 15);
          } else {
            _getCurrentLocation();
          }
        },
      ),
    );
  }

  Widget _buildUrgentRequestFAB() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('requests').stream(primaryKey: ['request_id']).eq('status', 'OPEN'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        final nearbyRequests = snapshot.data!.where((req) {
          if (_myLocation == null) return false;
          if (req['user_id'] == _currentUserId) return false;
          try {
            double dist = Geolocator.distanceBetween(
                _myLocation!.latitude, _myLocation!.longitude,
                (req['location_latitude'] as num).toDouble(),
                (req['location_longitude'] as num).toDouble()
            ) / 1000;
            return dist <= (req['radius_km'] ?? 2.0);
          } catch (e) { return false; }
        }).toList();

        if (nearbyRequests.isEmpty) return const SizedBox.shrink();

        final unseenCount = nearbyRequests.where((req) => !_viewedRequestIds.contains(req['request_id'])).length;
        final bool hasUnseen = unseenCount > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: "urgent_notif_btn",
              backgroundColor: Colors.white,
              elevation: 8,
              onPressed: () => _showNearbyRequests(nearbyRequests),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Change icon color from Red (new) to Black (normalized/seen)
                  Icon(
                    hasUnseen ? Icons.notifications_active : Icons.notifications,
                    color: hasUnseen ? Colors.redAccent : Colors.black,
                  ),

                  // Only show the red number badge if there are UNSEEN requests
                  if (hasUnseen)
                    Positioned(
                      right: 0, top: 0,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text("$unseenCount", style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // Change label background from Red to Black when normalized
                  color: hasUnseen ? Colors.redAccent : Colors.black,
                  borderRadius: BorderRadius.circular(12)
              ),
              child: const Text("URGENT", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

// 3. Updated Modal with Expandable List and Chat Option
  void _showNearbyRequests(List<Map<String, dynamic>> requests) {

    setState(() {
      for (var req in requests) {
        _viewedRequestIds.add(req['request_id']);
      }
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Urgent Needs Nearby", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: requests.length,
                itemBuilder: (context, i) {
                  final req = requests[i];
                  final double dist = _myLocation == null ? 0 : Geolocator.distanceBetween(
                      _myLocation!.latitude, _myLocation!.longitude,
                      req['location_latitude'], req['location_longitude']
                  ) / 1000;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ExpansionTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFFFFEBEE), child: Icon(Icons.bolt, color: Colors.red)),
                      title: Text("Need: ${req['stuff_type']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${dist.toStringAsFixed(1)} km away • ${req['urgency_level']}"),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Request Details:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(req['description'] ?? "No additional details provided.", style: const TextStyle(fontSize: 14)),
                              const Divider(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (context) => RequestChatPage( // CHANGED HERE
                                        requestId: req['request_id'],
                                        receiverId: req['user_id'],
                                        receiverName: "Requester (${req['stuff_type']})",
                                      ),
                                    ));
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text("HELP & CHAT"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black, foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CUSTOM PIN WIDGET ---
  Widget _buildCustomPin(String type) {
    Color color = Colors.grey;
    IconData icon = Icons.bookmark;

    switch (type) {
      case 'BOOK':
        color = Colors.blue;
        icon = Icons.menu_book;
        break;
      case 'STATIONERY':
        color = Colors.green;
        icon = Icons.edit;
        break;
      case 'ELECTRONICS':
        color = Colors.redAccent;
        icon = Icons.devices;
        break;
      case 'NOTES':
        color = Colors.orange;
        icon = Icons.description;
        break;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        // Triangle/Arrow pointer
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(color: color, width: 10, height: 8),
        ),
      ],
    );
  }

  // --- FILTER MODAL SHEET ---
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filters",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Filters List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Distance Slider
                      const Text(
                        "Distance Radius",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _radiusKm,
                              min: 1,
                              max: 50,
                              divisions: 49,
                              label: "${_radiusKm.toInt()} km",
                              onChanged: (val) =>
                                  setSheetState(() => _radiusKm = val),
                            ),
                          ),
                          Text("${_radiusKm.toInt()} km"),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // My College Toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          "My College Only",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          "Show items from students in my college",
                        ),
                        value: _showMyCollegeOnly,
                        onChanged: (val) =>
                            setSheetState(() => _showMyCollegeOnly = val),
                      ),
                      const Divider(),

                      // Item Type
                      _buildFilterSection(
                        "Item Type",
                        _stuffTypeOptions,
                        _selectedStuffTypes,
                        setSheetState,
                      ),
                      const Divider(),

                      // Offer Type
                      _buildFilterSection(
                        "Offer Type",
                        _offerTypeOptions,
                        _selectedOfferTypes,
                        setSheetState,
                      ),
                      const Divider(),

                      // Condition
                      _buildFilterSection(
                        "Condition",
                        _conditionOptions,
                        _selectedConditions,
                        setSheetState,
                      ),
                    ],
                  ),
                ),

                // Apply Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters(); // Apply to parent state
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Apply Filters",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    List<String> selectedList,
    StateSetter setSheetState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selectedList.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (bool selected) {
                setSheetState(() {
                  if (selected) {
                    selectedList.add(option);
                  } else {
                    selectedList.remove(option);
                  }
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- OFFER DETAILS SHEET ---
  void _showOfferDetails(Offer offer) {
    final stuff = offer.stuff;
    if (stuff == null) return;

    final String? imageUrl = (stuff.imageUrls.isNotEmpty) ? stuff.imageUrls[0] : null;

    final String sellerName = offer.seller?.profile?.fullName ?? 'Unknown Seller';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 15)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
              ),
              title: Text(
                stuff.title ?? 'No Title',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    "${stuff.type.name} • ₹${offer.price ?? offer.rentalPrice ?? 0}",
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(sellerName, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);

                  final displayItem = Stuff(
                    id: stuff.id,
                    ownerId: offer.userId ?? stuff.ownerId,
                    title: stuff.title,
                    subtitle: stuff.subtitle,
                    description: stuff.description,
                    type: stuff.type,
                    author: stuff.author,
                    isbn: stuff.isbn,
                    condition: stuff.condition,
                    originalPrice: stuff.originalPrice,
                    isAvailable: stuff.isAvailable,
                    imageUrls: stuff.imageUrls,
                    tags: stuff.tags,
                    offers: [offer], // Inject the selected offer into the model
                    // Transfer all academic/product metadata
                    publisher: stuff.publisher,
                    edition: stuff.edition,
                    publicationYear: stuff.publicationYear,
                    language: stuff.language,
                    brand: stuff.brand,
                    model: stuff.model,
                    subject: stuff.subject,
                    genre: stuff.genre,
                    classSuitability: stuff.classSuitability,
                    quantity: stuff.quantity,
                    stockQuantity: stuff.stockQuantity,
                    isInventory: stuff.isInventory,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ItemDetailPage(item: displayItem),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("View"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple clipper for the map pin triangle
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
