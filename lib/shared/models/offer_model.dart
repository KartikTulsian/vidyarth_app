import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/stuff_model.dart';
import 'package:vidyarth_app/shared/models/user_model.dart';

class Offer {
  final String? id;
  final String? userId;
  final String? stuffId;
  final OfferType offerType;
  final double? price;
  final double? rentalPrice;
  final int? rentalPeriodDays;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? securityDeposit;
  final String? exchangeItemDescription;
  final double? exchangeItemValue;
  final int? quantityAvailable;
  final RentalUnit rentalUnit;
  final String? pickupAddress;
  final String? city;
  final String? state;
  final String? pincode;
  final DateTime? availabilityStart;
  final DateTime? availabilityEnd;
  final VisiScope visibilityScope;
  final String? termsConditions;
  final String? specialInstructions;

  final Stuff? stuff;
  final UserModel? seller;

  Offer({
    this.id,
    this.stuffId,
    this.userId,
    required this.offerType,
    this.price,
    this.rentalPrice,
    this.rentalPeriodDays,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.securityDeposit,
    this.exchangeItemDescription,
    this.exchangeItemValue,
    this.quantityAvailable = 1,
    this.rentalUnit = RentalUnit.DAY,
    this.pickupAddress,
    this.city,
    this.state,
    this.pincode,
    this.availabilityStart,
    this.availabilityEnd,
    this.visibilityScope = VisiScope.PUBLIC,
    this.termsConditions,
    this.specialInstructions,

    this.stuff,
    this.seller,
  });

  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      id: map['offer_id'],
      stuffId: map['stuff_id'],
      userId: map['user_id'],
      offerType: OfferType.values.firstWhere((e) => e.name == map['offer_type']),
      price: (map['price'] as num?)?.toDouble(),
      rentalPrice: (map['rental_price'] as num?)?.toDouble(),
      rentalPeriodDays: map['rental_period_days'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      pickupAddress: map['pickup_address'],
      city: map['city'],
      state: map['state'],
      pincode: map['pincode'],
      termsConditions: map['terms_conditions'],
      specialInstructions: map['special_instructions'],
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      securityDeposit: (map['security_deposit'] as num?)?.toDouble(),
      exchangeItemDescription: map['exchange_item_description'],
      quantityAvailable: map['quantity_available'] ?? 1,
      visibilityScope: VisiScope.values.firstWhere((e) => e.name == map['visibility_scope'], orElse: () => VisiScope.PUBLIC),
      rentalUnit: RentalUnit.values.firstWhere((e) => e.name == map['rental_unit'], orElse: () => RentalUnit.DAY),

      stuff: map['stuff'] != null ? Stuff.fromMap(map['stuff']) : null,
      seller: map['seller'] != null ? UserModel.fromMap(map['seller']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'offer_id': id,
      'stuff_id': stuffId,
      'user_id': userId,
      'offer_type': offerType.name,
      'price': price,
      'rental_price': rentalPrice,
      'rental_period_days': rentalPeriodDays,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'visibility_scope': visibilityScope.name,
      'rental_unit': rentalUnit.name,
      'security_deposit': securityDeposit,
      'exchange_item_description': exchangeItemDescription,
      'exchange_item_value': exchangeItemValue,
      'quantity_available': quantityAvailable,
      'pickup_address': pickupAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'terms_conditions': termsConditions,
      'special_instructions': specialInstructions,
      'availability_start': availabilityStart?.toIso8601String(),
      'availability_end': availabilityEnd?.toIso8601String(),
    };
  }
}