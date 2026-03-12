import 'package:vidyarth_app/shared/models/app_enums.dart';
import 'package:vidyarth_app/shared/models/offer_model.dart';

class Stuff {
  final String id;
  final String ownerId;
  final String title;
  final String? subtitle;
  final String? description;
  final StuffType type;
  final String? author;
  final String? isbn;
  final ItemCondition condition;
  final double? originalPrice;
  final bool isAvailable;
  final int viewsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? publisher;
  final String? edition;
  final int? publicationYear;
  final String? language;
  final String? bookType;
  final String? brand;
  final String? model;
  final String? stationaryType;
  final String? subject;
  final String? genre;
  final String? classSuitability;
  final int quantity;
  final int stockQuantity;
  final bool isInventory;

  final List<String> imageUrls;
  final List<Offer> offers;
  final List<String> tags;

  Stuff({
    required this.id,
    required this.ownerId,
    required this.title,
    this.subtitle,
    this.description,
    required this.type,
    this.author,
    this.isbn,
    required this.condition,
    this.originalPrice,
    this.isAvailable = true,
    this.viewsCount = 0,
    this.createdAt,
    this.updatedAt,
    this.publisher,
    this.edition,
    this.publicationYear,
    this.language,
    this.bookType,
    this.brand,
    this.model,
    this.stationaryType,
    this.subject,
    this.genre,
    this.classSuitability,
    this.quantity = 1,
    this.stockQuantity = 1,
    this.isInventory = false,
    this.imageUrls = const [],

    this.offers = const [],
    this.tags = const [],
  });

  factory Stuff.fromMap(Map<String, dynamic> map) {
    return Stuff(
      id: map['stuff_id'],
      ownerId: map['owner_id'],
      type: StuffType.values.firstWhere((e) => e.name == map['type'], orElse: () => StuffType.OTHER),
      title: map['title'],
      description: map['description'],
      author: map['author'],
      isbn: map['isbn'],
      condition: ItemCondition.values.firstWhere((e) => e.name == map['condition'], orElse: () => ItemCondition.GOOD),
      originalPrice: (map['original_price'] as num?)?.toDouble(),
      isAvailable: map['is_available'] ?? true,
      viewsCount: map['views_count'] ?? 0,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      subtitle: map['subtitle'],
      publisher: map['publisher'],
      edition: map['edition'],
      publicationYear: map['publication_year'],
      language: map['language'],
      brand: map['brand'],
      model: map['model'],
      subject: map['subject'],
      genre: map['genre'],
      classSuitability: map['class_suitability'],
      bookType: map['book_type'],
      stationaryType: map['stationary_type'],
      quantity: map['quantity'] ?? 1,
      stockQuantity: map['stock_quantity'] ?? 1,
      isInventory: map['is_inventory'] ?? false,

      offers: (map['offers'] as List?)?.map((o) => Offer.fromMap(o)).toList() ?? [],
      imageUrls: (map['stuff_images'] as List?)?.map((img) => img['url'].toString()).toList() ?? [],
      tags: (map['stuff_tags'] as List?)
          ?.map((t) => t['tags']['name'].toString())
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'type': type.name,
      'author': author,
      'isbn': isbn,
      'condition': condition.name,
      'original_price': originalPrice,
      'publisher': publisher,
      'edition': edition,
      'publication_year': publicationYear,
      'brand': brand,
      'model': model,
      'language': language,
      'subject': subject,
      'genre': genre,
      'class_suitability': classSuitability,
      'quantity': quantity,
      'stock_quantity': stockQuantity,
      'is_inventory': isInventory,
      'is_available': isAvailable,
    };
  }
}