import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Renders a product image whether it's a bundled asset path (the curated
/// seed catalog) or an uploaded Firebase Storage URL (admin-added products
/// with a real photo) — callers no longer need to know which.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  bool get _isNetwork => path.startsWith('http://') || path.startsWith('https://');

  Widget _errorFallback(BuildContext context) => Container(
    width: width,
    height: height,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(Icons.broken_image, color: Theme.of(context).hintColor),
  );

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, _) => Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        errorWidget: (context, _, __) => _errorFallback(context),
      );
    }
    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => _errorFallback(context),
    );
  }
}
