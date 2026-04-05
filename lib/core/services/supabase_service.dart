import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/dealer_profile_model.dart';
import 'package:vidyarth_app/shared/models/delivery_model.dart';
import 'package:vidyarth_app/shared/models/delivery_profile_model.dart';
import 'package:vidyarth_app/shared/models/offer_model.dart';
import 'package:vidyarth_app/shared/models/profile_model.dart';
import 'package:vidyarth_app/shared/models/request_model.dart';
import 'package:vidyarth_app/shared/models/request_trade_model.dart';
import 'package:vidyarth_app/shared/models/school_model.dart';
import 'package:vidyarth_app/shared/models/stuff_model.dart';
import 'package:vidyarth_app/shared/models/tag_model.dart';
import 'package:vidyarth_app/shared/models/trade_model.dart';
import 'package:vidyarth_app/shared/models/user_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  SupabaseClient get client => _client;

  Future<UserModel?> getUnifiedProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      // Single query fetching data from users, joined with profiles and dealer_profiles
      final response = await _client
          .from('users')
          .select('''
          *,
          profiles (*),
          dealer_profiles (*),
          delivery_profiles (*)
        ''')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromMap(response);
    } catch (e) {
      print("Unified Fetch Error: $e");
      return null;
    }
  }

  Future<DealerProfile?> getDealerProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select('*, dealer_profiles(*)')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return DealerProfile.fromMap(response);
    } catch (e) {
      print("Error fetching dealer profile: $e");
      return null;
    }
  }

  Future<bool> hasProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final data = await _client
          .from('profiles')
          .select('phone')
          .eq('user_id', user.id)
          .maybeSingle();

      if (data == null) return false;

      // Check if phone is present to consider profile "complete"
      final phone = data['phone'] as String?;
      return phone != null && phone.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> createProfile({
    required String name,
    required String role,
    required String? email,
    required String phone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // 1. Update public.users
    await _client.from('users').upsert({
      'user_id': user.id,
      'username': name,
      'role': role,
      'email': email,
      'phone': phone,
      'is_active': true,
    }, onConflict: 'user_id');

    // 2. Update public.profiles
    await _client.from('profiles').upsert({
      'user_id': user.id,
      'full_name': name,
      'phone': phone,
    }, onConflict: 'user_id');

    if (role == 'DEALER') {
      await _client.from('dealer_profiles').upsert({
        'dealer_id': user.id,
        'shop_name': "$name's Shop", // Default name until they edit it
      }, onConflict: 'dealer_id');
    } else if (role == "DELIVERY") {
      await _client.from('delivery_profiles').upsert({
        'delivery_boy_id': user.id,
        'is_available': true,
        'average_rating': 0.0,
      });
    }
  }

  Future<void> updateDetailedProfile(ProfileModel profile) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      print("DEBUG SERVICE: No authenticated user found");
      return;
    }

    final data = profile.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();

    print("DEBUG SERVICE: Executing profiles upsert for user ${user.id}");

    // Note: Ensure 'user_id' is the correct column name for your unique constraint
    final response = await _client.from('profiles').upsert(data, onConflict: 'user_id').select();
    print("DEBUG SERVICE: Profiles Upsert Response: $response");
  }

  Future<void> updateDealerBusinessProfile(DealerProfile dealer) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    print("DEBUG SERVICE: Executing dealer_profiles upsert for user ${user.id}");
    final response = await _client
        .from('dealer_profiles')
        .upsert(dealer.toMap(), onConflict: 'dealer_id')
        .select();
    print("DEBUG SERVICE: Dealer Upsert Response: $response");
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${user.id}/avatar.$fileExt';

      // 1. Upload/Overwrite to 'avatars' bucket
      await _client.storage.from('avatars').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // 2. Get Public URL
      final String imageUrl = _client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // 3. Add timestamp for Flutter cache busting
      await _client
          .from('profiles')
          .update({
            'avatar_url': imageUrl,
          }) // Use .update() instead of .upsert()
          .eq('user_id', user.id);

      final timestampedUrl =
          "$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}";

      return timestampedUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<List<SchoolCollege>> getSchools() async {
    try {
      final response = await _client
          .from('school_colleges')
          .select()
          .order('name');
      return (response as List).map((s) => SchoolCollege.fromMap(s)).toList();
    } catch (e) {
      print("Error fetching schools: $e");
      return [];
    }
  }

  Future<List<Stuff>> getUserItems() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('stuff')
          .select('''
          *, 
          stuff_images(url), 
          stuff_tags(tags(name)), 
          offers(*)
          ''')
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);

      return (response as List).map((data) => Stuff.fromMap(data)).toList();
    } catch (e) {
      print("Error fetching user items: $e");
      return [];
    }
  }

  Future<void> addNewItem({
    required String title,
    required String description,
    required String type,
    required String condition,
    required double price,
    String? author,
    String? isbn,
    File? imageFile,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final response = await _client
        .from('stuff')
        .insert({
          'owner_id': user.id,
          'title': title,
          'description': description,
          'type': type,
          'condition': condition,
          'original_price': price,
          'author': author,
          'isbn': isbn,
          'is_available': true,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('stuff_id')
        .single();

    final newStuffId = response['stuff_id'];

    if (imageFile != null && newStuffId != null) {
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          'items/$newStuffId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload to bucket 'stuff_images'
      await _client.storage.from('stuff_images').upload(fileName, imageFile);
      final imageUrl = _client.storage
          .from('stuff_images')
          .getPublicUrl(fileName);

      // Insert into stuff_images table
      await _client.from('stuff_images').insert({
        'stuff_id': newStuffId,
        'url': imageUrl,
        'is_primary': true,
      });
    }
  }

  Future<void> createStuffWithOffer({
    required Stuff stuff,
    required Offer offer,
    required List<File> images,
    required List<String> tags,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    print("DEBUG: Starting Stuff Insert...");
    final stuffMap = stuff.toMap()..['owner_id'] = user.id;

    final stuffResponse = await _client
        .from('stuff')
        .insert(stuffMap)
        .select('stuff_id')
        .single();

    final stuffId = stuffResponse['stuff_id'];
    print("DEBUG: Stuff Created with ID: $stuffId");

    for (var i = 0; i < images.length; i++) {
      final path =
          'items/$stuffId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      await _client.storage.from('stuff_images').upload(path, images[i]);
      final url = _client.storage.from('stuff_images').getPublicUrl(path);

      await _client.from('stuff_images').insert({
        'stuff_id': stuffId,
        'url': url,
        'is_primary': i == 0,
      });
    }

    for (String tagName in tags) {
      final tagRes = await _client
          .from('tags')
          .upsert({'name': tagName.toUpperCase()}, onConflict: 'name')
          .select('tag_id')
          .single();

      await _client.from('stuff_tags').insert({
        'stuff_id': stuffId,
        'tag_id': tagRes['tag_id'],
      });
    }

    // 4. Insert Offer
    print("DEBUG: Preparing Offer Map for Stuff ID: $stuffId");
    final offerMap = offer.toMap();
    offerMap['stuff_id'] = stuffId;
    offerMap['user_id'] = user.id;

    print("DEBUG: Offer Map Content: $offerMap");

    try {
      final offerResponse = await _client
          .from('offers')
          .insert(offerMap)
          .select()
          .single();
      print("DEBUG: Offer Successfully Created: ${offerResponse['offer_id']}");
    } catch (e) {
      print("DEBUG: ERROR INSERTING OFFER: $e");
      // If offer fails, we should probably delete the stuff to keep DB clean
      await _client.from('stuff').delete().eq('stuff_id', stuffId);
      throw Exception("Failed to create offer details: $e");
    }
  }

  Future<void> deleteStuff(String stuff_id) async {
    try {
      final offerData = await _client
          .from('offers')
          .select('offer_id')
          .eq('stuff_id', stuff_id)
          .maybeSingle();

      if (offerData != null) {
        String offerId = offerData['offer_id'];

        await _client.from('messages').delete().eq('offer_id', offerId);

        await _client.from('offers').delete().eq('offer_id', offerId);
      }

      await _client.from('stuff_images').delete().eq('stuff_id', stuff_id);

      await _client.from('stuff_tags').delete().eq('stuff_id', stuff_id);

      await _client.from('stuff').delete().eq('stuff_id', stuff_id);
    } catch (e) {
      throw Exception("Delete failed: $e");
    }
  }

  Future<void> updateStuffWithOffer({
    required Stuff stuff,
    required Offer offer,
    List<File>? newImages,
    List<String>? tags,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    // 1. Update Stuff Table using model toMap
    await _client.from('stuff').update(stuff.toMap()).eq('stuff_id', stuff.id);

    // 2. Update Offer Table using model toMap
    if (offer.id != null) {
      final offerMap = offer.toMap();
      offerMap['stuff_id'] = stuff.id;
      offerMap.remove('offer_id');

      await _client
          .from('offers')
          .update(offerMap)
          .eq('offer_id', offer.id!);
    }

    // 3. Update Tags (Delete old, Insert new)
    if (tags != null) {
      await _client.from('stuff_tags').delete().eq('stuff_id', stuff.id);
      for (String tagName in tags) {
        final tagRes = await _client
            .from('tags')
            .upsert({'name': tagName.toUpperCase()}, onConflict: 'name')
            .select('tag_id')
            .single();

        await _client.from('stuff_tags').insert({
          'stuff_id': stuff.id,
          'tag_id': tagRes['tag_id'],
        });
      }
    }

    // 4. Upload NEW Images (if any)
    if (newImages != null && newImages.isNotEmpty) {
      for (var i = 0; i < newImages.length; i++) {
        final file = newImages[i];
        final path =
            'items/${stuff.id}/${DateTime.now().millisecondsSinceEpoch}_new_$i.jpg';

        await _client.storage.from('stuff_images').upload(path, file);
        final url = _client.storage.from('stuff_images').getPublicUrl(path);

        await _client.from('stuff_images').insert({
          'stuff_id': stuff.id,
          'url': url,
          'is_primary': false,
        });
      }
    }
  }

  Future<List<Offer>> getNearbyOffers() async {
    try {
      final response = await _client
          .from('offers')
          .select('''
      *,
      stuff:stuff_id (
        *, 
        stuff_images(url),
        stuff_tags(tags(name))
      ),
      seller:user_id (
        *,
        profiles (full_name, school_college_id)
      )
    ''')
          .eq('is_active', true);

      if (response == null) return [];

      final List<dynamic> data = response as List;

      return data.map((offerMap) => Offer.fromMap(offerMap)).toList();
    } catch (e) {
      print("Error fetching nearby offers: $e");
      return [];
    }
  }

  Future<List<DeliveryProfile>> getLiveRiders() async {
    try {
      final response = await _client
          .from('delivery_profiles')
          .select()
          .eq('is_available', true);

      if (response == null) return [];

      return (response as List)
          .map((data) => DeliveryProfile.fromMap(data))
          .toList();
    } catch (e) {
      print("Error fetching riders: $e");
      return [];
    }
  }

  Future<void> upgradeSubscription(SubTier tier) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('users')
        .update({
          'sub_tier': tier.name, // Uses the Enum name
          'sub_expiry': DateTime.now()
              .add(const Duration(days: 30))
              .toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id);
  }

  Future<bool> canUserAddItem() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      // 1. Fetch user role and tier
      final userData = await _client
          .from('users')
          .select('role, sub_tier')
          .eq('user_id', user.id)
          .single();

      final role = UserRole.values.firstWhere(
        (e) => e.name == userData['role'],
      );
      final tier = SubTier.values.firstWhere(
        (e) => e.name == userData['sub_tier'],
      );

      // 2. Dealers on PRO or PLUS have unlimited items
      if (role == UserRole.DEALER &&
          (tier == SubTier.PRO || tier == SubTier.PLUS))
        return true;
      if (role == UserRole.STUDENT && tier == SubTier.PLUS) return true;

      // 3. Get count of current listings (Safe cross-version way)
      final response = await _client
          .from('stuff')
          .select('stuff_id')
          .eq('owner_id', user.id);

      final int currentItemCount = (response as List).length;

      // Logic Check
      if (role == UserRole.STUDENT) {
        if (tier == SubTier.BASIC && currentItemCount >= 8) return false;
        if (tier == SubTier.PRO && currentItemCount >= 20) return false;
      } else if (role == UserRole.DEALER) {
        if (tier == SubTier.BASIC && currentItemCount >= 5) return false;
      }

      return true;
    } catch (e) {
      print("Check Limit Error: $e");
      return true; // Default to allow if check fails (better UX)
    }
  }

  Future<Map<String, int>> getUserListingStats() async {
    final user = _client.auth.currentUser;
    if (user == null) return {'count': 0, 'limit': 0};

    try {
      final userData = await _client
          .from('users')
          .select('role, sub_tier')
          .eq('user_id', user.id)
          .single();

      final role = UserRole.values.firstWhere(
        (e) => e.name == userData['role'],
      );
      final tier = SubTier.values.firstWhere(
        (e) => e.name == userData['sub_tier'],
      );

      final List<dynamic> response = await _client
          .from('stuff')
          .select('stuff_id')
          .eq('owner_id', user.id);
      int count = response.length;

      int limit = 0;
      if (role == UserRole.STUDENT) {
        limit = (tier == SubTier.BASIC) ? 8 : (tier == SubTier.PRO ? 20 : 9999);
      } else {
        limit = (tier == SubTier.BASIC) ? 5 : 9999;
      }

      return {'count': count, 'limit': limit};
    } catch (e) {
      return {'count': 0, 'limit': 0};
    }
  }

  Future<void> markMessagesAsRead(String otherUserId, String? offerId) async {
    final user = _client.auth.currentUser;
    if (user == null || offerId == null) return;

    try {
      print("DEBUG: Marking messages as read for User: ${user.id}, Sender: $otherUserId, Offer: $offerId");

      final response = await _client
          .from('messages')
          .update({'is_read': true})
          .eq('receiver_id', user.id)
          .eq('sender_id', otherUserId)
          .eq('offer_id', offerId ?? '') // Handle null as empty string if that's your DB default
          .eq('is_read', false)
          .select();

      print("DEBUG: Successfully marked ${response.length} messages as read.");

    } catch (e) {
      print("DEBUG ERROR: markMessagesAsRead failed: $e");
    }
  }

  Future<List<Stuff>> getDealerInventory() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    try {
      final response = await _client
          .from('stuff')
          .select('''
            *,
            stuff_images(url),
            offers(*),
            stuff_tags(tags(name))
          ''')
          .eq('owner_id', user.id)
          .eq('is_inventory', true)
          .order('created_at', ascending: false);

      return (response as List).map((data) => Stuff.fromMap(data)).toList();
    } catch (e) {
      print("Inventory Fetch Error:  $e");
      return [];
    }
  }

  Future<List<Stuff>> getShopItems(String dealerId, String query) async {
    try {
      var request = _client
          .from('stuff')
          .select('*, stuff_images(url), offers(*)')
          .eq('owner_id', dealerId)
          .eq('is_inventory', true);

      if (query.isNotEmpty) {
        request = request.ilike('title', '%$query%');
      }

      final response = await request.order('title', ascending: true);
      return (response as List).map((data) => Stuff.fromMap(data)).toList();
    } catch (e) {
      print("Shop Items Error: $e");
      return [];
    }
  }

  Future<void> updateShopLocation(double lat, double lng) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Update both tables so they stay in sync
    await _client.from('dealer_profiles').update({'latitude': lat, 'longitude': lng}).eq('dealer_id', user.id);
    await _client.from('profiles').update({'latitude': lat, 'longitude': lng}).eq('user_id', user.id);
  }

  Future<List<Tag>> getAllTags() async {
    final response = await _client.from('tags').select().order('name');
    return (response as List).map((t) => Tag.fromMap(t)).toList();
  }

  Future<DealerProfile?> getDealerBusinessAddress() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('dealer_profiles')
        .select('dealer_id, shop_name, business_address, latitude, longitude')
        .eq('dealer_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return DealerProfile.fromMap(response);
  }

  Future<Offer?> getOfferById(String offerId) async {
    try {
      final response = await _client
          .from('offers')
          .select('*, stuff:stuff_id(*, stuff_images(url), offers(*))')
          .eq('offer_id', offerId)
          .maybeSingle();

      if (response == null) return null;
      return Offer.fromMap(response);
    } catch (e) {
      print("Error fetching offer: $e");
      return null;
    }
  }

  Future<Trade?> getTradeById(String tradeId) async {
    try {
      final response = await _client
          .from('trades')
          .select()
          .eq('trade_id', tradeId)
          .maybeSingle();

      if (response == null) {
        print("DEBUG: Trade $tradeId not found in database."); // Helpful for debugging
        return null;
      }
      return Trade.fromMap(response);
    } catch (e) {
      print("Error fetching trade: $e");
      return null;
    }
  }

  Future<DeliveryProfile?> getDeliveryProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('delivery_profiles')
          .select()
          .eq('delivery_boy_id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return DeliveryProfile.fromMap(response);
    } catch (e) {
      print("Error fetching delivery profile: $e");
      return null;
    }
  }

  Future<void> updateRiderStatus({required bool isAvailable, double? lat, double? lng}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('delivery_profiles').update({
      'is_available': isAvailable,
      if (lat != null) 'current_latitude': lat,
      if (lng != null) 'current_longitude': lng,
    }).eq('delivery_boy_id', user.id);
  }

  Future<List<Delivery>> getActiveDeliveries() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('deliveries')
          .select()
          .eq('delivery_boy_id', user.id)
          .not('status', 'eq', 'DELIVERED')
          .order('created_at', ascending: false);

      return (response as List).map((data) => Delivery.fromMap(data)).toList();
    } catch (e) {
      print("Error fetching deliveries: $e");
      return [];
    }
  }

  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? proofUrl,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (status == 'PICKED_UP') {
      updateData['picked_time'] = DateTime.now().toIso8601String();
      if (proofUrl != null) updateData['pickup_proof_url'] = proofUrl;
    } else if (status == 'DELIVERED') {
      updateData['delivered_time'] = DateTime.now().toIso8601String();
      if (proofUrl != null) updateData['delivery_proof_url'] = proofUrl;
    }

    await _client.from('deliveries').update(updateData).eq('delivery_id', deliveryId);
  }

  Future<List<Delivery>> getDeliveryHistory() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('deliveries')
          .select()
          .eq('delivery_boy_id', user.id)
          .eq('status', 'DELIVERED')
          .order('delivery_time', ascending: false);

      return (response as List).map((data) => Delivery.fromMap(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getDeliveryMessage() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('messages')
        .select()
        .or('sender_id.eq.${user.id}, receiver_id.eq.${user.id}')
        .order('created_at', ascending: false);

    return response as List;
  }

  Future<double> getOutstandingPlatformFees() async {
    final user = client.auth.currentUser;
    if (user == null) return 0.0;

    try {
      // Sum platform_fee from accepted trades where the user is the lender
      final response = await _client
          .from('trades')
          .select('platform_fee')
          .eq('lender_id', user.id)
          .or('status.eq.ACCEPTED,status.eq.COMPLETED');

      if (response == null || (response as List).isEmpty) {
        print("DEBUG: No trades found for fee calculation");
        return 0.0;
      }

      double total = 0.0;
      for (var trade in (response as List)) {
        // Safely convert to double and handle nulls
        final fee = trade['platform_fee'];
        if (fee != null) {
          total += (fee as num).toDouble();
        }
      }
      print("DEBUG: Service calculated total fees: ₹$total");
      return total;
    } catch (e) {
      print("DEBUG ERROR: getOutstandingPlatformFees failed: $e");
      return 0.0;
    }
  }

  Future<List<Trade>> getFullTradeHistory() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('trades')
          .select('''
            *,
            offers(
            *,
            stuff (*)
            )
          ''')
          .or('borrower_id.eq.${user.id}, lender_id.eq.${user.id}')
          .order('created_at', ascending: false);

      return (response as List).map((map) {
        return Trade.fromMap(map);
      }).toList();
    } catch (e) {
      print("Error fetching trade history: $e");
      return [];
    }
  }

  Future<void> completeTrade(String tradeId) async {
    try {
      await _client
          .from('trades')
          .update({'status': 'COMPLETED'})
          .eq('trade_id', tradeId);
    } catch (e) {
      throw Exception("Could not complete trade: $e");
    }
  }

  Future<void> createUrgentRequest(RequestModel request) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      debugPrint("DEBUG: Creating urgent request for ${request.stuffType}");
      final data = request.toMap();
      data['user_id'] = user.id;
      await _client.from('requests').insert(data);
      debugPrint("DEBUG: Request saved successfully for User: ${user.id}");
    } catch (e) {
      debugPrint("DEBUG ERROR: createUrgentRequest failed: $e");
    }
  }

  Future<List<RequestModel>> getUserRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('requests')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List).map((map) => RequestModel.fromMap(map)).toList();
    } catch (e) {
      print("Error fetching user requests: $e");
      return [];
    }
  }

  Future<RequestTrade?> getRequestTradeById(String tradeId) async {
    try {
      final response = await _client.from('request_trades').select().eq('trade_id', tradeId).maybeSingle();
      if (response == null) return null;
      return RequestTrade.fromMap(response);
    } catch (e) {
      print("Error fetching request trade: $e");
      return null;
    }
  }

  Future<void> markRequestMessagesAsRead(String otherUserId, String requestId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client.from('request_messages')
          .update({'is_read': true})
          .eq('receiver_id', user.id)
          .eq('sender_id', otherUserId)
          .eq('request_id', requestId)
          .eq('is_read', false);
    } catch (e) {
      print("Error marking request messages read: $e");
    }
  }
}
