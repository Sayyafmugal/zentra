import 'package:equatable/equatable.dart';

/// One purchasable size/color combination of a [Product]. A simple product
/// with only a flat `availableSizes` list (the pre-existing model) has an
/// empty `variants` list — variants are additive, not a replacement, so
/// every product created before this existed keeps working unchanged.
class ProductVariant extends Equatable {
  final String id;
  final String sku;
  final String size;
  final String? color;
  // Null means "use the product's basePrice" — most variants don't need a
  // price override, so this avoids repeating the price on every variant.
  final double? priceOverride;
  final int stock;
  final String? imageUrl;

  const ProductVariant({
    required this.id,
    required this.sku,
    required this.size,
    this.color,
    this.priceOverride,
    required this.stock,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'size': size,
      'color': color,
      'priceOverride': priceOverride,
      'stock': stock,
      'imageUrl': imageUrl,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] ?? '',
      sku: map['sku'] ?? '',
      size: map['size'] ?? '',
      color: map['color'],
      priceOverride: map['priceOverride'] != null ? (map['priceOverride'] as num).toDouble() : null,
      stock: map['stock'] ?? 0,
      imageUrl: map['imageUrl'],
    );
  }

  ProductVariant copyWith({
    String? sku,
    String? size,
    String? color,
    double? priceOverride,
    int? stock,
    String? imageUrl,
  }) {
    return ProductVariant(
      id: id,
      sku: sku ?? this.sku,
      size: size ?? this.size,
      color: color ?? this.color,
      priceOverride: priceOverride ?? this.priceOverride,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  double effectivePrice(double basePrice) => priceOverride ?? basePrice;

  String get label => color != null ? '$color / $size' : size;

  @override
  List<Object?> get props => [id, sku, size, color, priceOverride, stock, imageUrl];
}
