import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 14, this.reviewCount});

  final double rating;
  final double size;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size, color: Colors.amber),
        SizedBox(width: size * 0.25),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w600),
        ),
        if (reviewCount != null) ...[
          SizedBox(width: size * 0.4),
          Text(
            '($reviewCount)',
            style: TextStyle(fontSize: size * 0.9, color: Theme.of(context).hintColor),
          ),
        ],
      ],
    );
  }
}
