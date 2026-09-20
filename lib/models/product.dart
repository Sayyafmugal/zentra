import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'product_variant.dart';

/// Lifecycle of a catalog listing. Every product created before this existed
/// has no `status` field in Firestore, and [fromMap] defaults that to
/// [published] — the storefront's visibility behavior for old data is
/// unchanged. New sellers going through the submit-for-approval flow start
/// at [draft]/[pendingApproval] instead (enforced by the controller/rules
/// that use this, not by this model).
enum ProductStatus { draft, pendingApproval, published, rejected, archived, outOfStock }

class Product extends Equatable {
  final String id;
  final String imagePath;
  final String name;
  final String category;
  final double currentPrice;
  final double? oldPrice;
  final String? discount;
  final List<String> availableSizes;
  final String description;
  final bool isFavorite;
  final double rating;
  final int reviewCount;

  // --- Marketplace/production fields (additive; all safely defaulted so
  // existing Firestore product docs written before these existed still
  // decode correctly) ---

  /// Empty string means "owned by the platform admin", matching every
  /// product that existed before the seller system did. A real seller's
  /// products carry that seller's uid.
  final String sellerId;
  final ProductStatus status;
  final String? sku;

  /// Additional gallery images beyond [imagePath] (which remains the
  /// thumbnail/primary image so every existing call site keeps working).
  final List<String> images;

  /// Size/color combinations with their own stock. Empty for a simple
  /// product that only varies by [availableSizes] with no per-size stock
  /// tracking — see [hasVariants].
  final List<ProductVariant> variants;

  /// Stock for a product with no variants. Null means "not tracked" (the
  /// legacy behavior every pre-existing product has: always orderable) —
  /// this is intentionally distinct from `0`, which means genuinely out of
  /// stock. When [hasVariants] is true, stock is read from each variant
  /// instead and this field is ignored.
  final int? totalStock;

  const Product({
    required this.id,
    required this.imagePath,
    required this.name,
    required this.category,
    required this.currentPrice,
    this.oldPrice,
    this.discount,
    required this.availableSizes,
    required this.description,
    this.isFavorite = false,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.sellerId = '',
    this.status = ProductStatus.published,
    this.sku,
    this.images = const [],
    this.variants = const [],
    this.totalStock,
  });

  bool get hasVariants => variants.isNotEmpty;

  bool get isOwnedByAdmin => sellerId.isEmpty;

  /// Total sellable units across variants, or [totalStock] for a simple
  /// product. Null continues to mean "not tracked" so legacy products don't
  /// suddenly read as out of stock.
  int? get stockQuantity {
    if (hasVariants) return variants.fold<int>(0, (sum, v) => sum + v.stock);
    return totalStock;
  }

  bool get isInStock => stockQuantity == null || stockQuantity! > 0;

  bool get isPublished => status == ProductStatus.published;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'name': name,
      'category': category,
      'currentPrice': currentPrice,
      'oldPrice': oldPrice,
      'discount': discount,
      'availableSizes': availableSizes,
      'description': description,
      'isFavorite': isFavorite,
      'rating': rating,
      'reviewCount': reviewCount,
      'sellerId': sellerId,
      'status': status.name,
      'sku': sku,
      'images': images,
      'variants': variants.map((v) => v.toMap()).toList(),
      'totalStock': totalStock,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      imagePath: map['imagePath'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      currentPrice: (map['currentPrice'] ?? 0.0).toDouble(),
      oldPrice: map['oldPrice'] != null ? (map['oldPrice'] as num).toDouble() : null,
      discount: map['discount'],
      availableSizes: List<String>.from(map['availableSizes'] ?? []),
      description: map['description'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
      rating: (map['rating'] ?? 4.5).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      sellerId: map['sellerId'] ?? '',
      status: ProductStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProductStatus.published,
      ),
      sku: map['sku'],
      images: List<String>.from(map['images'] ?? const []),
      variants:
          (map['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          const [],
      totalStock: map['totalStock'] != null ? map['totalStock'] as int : null,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product.fromMap(json);

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromMap(data);
  }

  Product copyWith({
    String? id,
    String? imagePath,
    String? name,
    String? category,
    double? currentPrice,
    double? oldPrice,
    String? discount,
    List<String>? availableSizes,
    String? description,
    bool? isFavorite,
    double? rating,
    int? reviewCount,
    String? sellerId,
    ProductStatus? status,
    String? sku,
    List<String>? images,
    List<ProductVariant>? variants,
    int? totalStock,
  }) {
    return Product(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      name: name ?? this.name,
      category: category ?? this.category,
      currentPrice: currentPrice ?? this.currentPrice,
      oldPrice: oldPrice ?? this.oldPrice,
      discount: discount ?? this.discount,
      availableSizes: availableSizes ?? this.availableSizes,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      sku: sku ?? this.sku,
      images: images ?? this.images,
      variants: variants ?? this.variants,
      totalStock: totalStock ?? this.totalStock,
    );
  }

  @override
  List<Object?> get props => [
    id,
    imagePath,
    name,
    category,
    currentPrice,
    oldPrice,
    discount,
    availableSizes,
    description,
    isFavorite,
    rating,
    reviewCount,
    sellerId,
    status,
    sku,
    images,
    variants,
    totalStock,
  ];
}
