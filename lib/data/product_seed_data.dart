import '../models/product.dart';

/// Demo catalog data. Only ever written to Firestore via an explicit,
/// admin-triggered seed action (Admin Dashboard -> "Seed sample data") —
/// never run implicitly at app startup.
final List<Product> kProductSeedData = [
  const Product(
    id: 'seed-air-runner-classic',
    imagePath: 'assets/images/shoe.jpg',
    name: 'Air Runner Classic',
    category: 'Shoes',
    currentPrice: 89.99,
    oldPrice: 119.99,
    discount: '25% OFF',
    availableSizes: ['S', 'M', 'L', 'XL'],
    description:
        'Lightweight everyday running shoe with a cushioned sole and breathable mesh upper. '
        'Engineered for long-distance comfort without sacrificing style.',
    rating: 4.6,
    reviewCount: 128,
  ),
  const Product(
    id: 'seed-urban-stride',
    imagePath: 'assets/images/shoe2.jpg',
    name: 'Urban Stride',
    category: 'Shoes',
    currentPrice: 74.99,
    availableSizes: ['M', 'L', 'XL'],
    description:
        'A versatile sneaker built for city life — durable rubber outsole, minimalist '
        'silhouette, and all-day comfort for work, errands, or weekend walks.',
    rating: 4.3,
    reviewCount: 76,
  ),
  const Product(
    id: 'seed-sport-pro-max',
    imagePath: 'assets/images/shoes2.jpg',
    name: 'Sport Pro Max',
    category: 'Shoes',
    currentPrice: 109.99,
    oldPrice: 139.99,
    discount: '20% OFF',
    availableSizes: ['S', 'M', 'L'],
    description:
        'High-performance sports shoe with reinforced ankle support and responsive '
        'cushioning, built to handle every terrain from track to trail.',
    rating: 4.8,
    reviewCount: 214,
  ),
  const Product(
    id: 'seed-mountain-boot',
    imagePath: 'assets/images/Lighthouse_MtBlk_R_700x.png',
    name: 'Mountain Boot',
    category: 'Boots',
    currentPrice: 149.99,
    oldPrice: 189.99,
    discount: '21% OFF',
    availableSizes: ['M', 'L', 'XL', 'XXL'],
    description:
        'Rugged mountain boot with a fully waterproof exterior and aggressive tread '
        'pattern, made for unpredictable weather and rough terrain.',
    rating: 4.5,
    reviewCount: 61,
  ),
  const Product(
    id: 'seed-sheepskin-leather-boot',
    imagePath: 'assets/images/mens-sheep-skin-black-leather-bo.jpg',
    name: 'Sheepskin Leather Boot',
    category: 'Boots',
    currentPrice: 199.99,
    availableSizes: ['M', 'L', 'XL'],
    description:
        'Premium sheepskin-lined leather boot for cold weather — natural insulation '
        'with a hand-stitched leather upper that ages beautifully over time.',
    rating: 4.7,
    reviewCount: 89,
  ),
  const Product(
    id: 'seed-varsity-leather-jacket',
    imagePath: 'assets/images/Liberte-USA-Black-Varsity-Leathe.jpg',
    name: 'Varsity Leather Jacket',
    category: 'Jackets',
    currentPrice: 249.99,
    oldPrice: 319.99,
    discount: '22% OFF',
    availableSizes: ['S', 'M', 'L', 'XL'],
    description:
        'Classic varsity leather jacket with a modern tailored cut, ribbed cuffs, '
        'and a soft quilted lining for year-round layering.',
    rating: 4.4,
    reviewCount: 47,
  ),
  const Product(
    id: 'seed-ultrabook-pro-15',
    imagePath: 'assets/images/laptop.jpg',
    name: 'UltraBook Pro 15',
    category: 'Electronics',
    currentPrice: 1199.99,
    oldPrice: 1499.99,
    discount: '20% OFF',
    availableSizes: ['One Size'],
    description:
        'Slim and powerful 15" laptop for professionals — all-day battery life, a '
        'crisp high-resolution display, and enough power for demanding workloads.',
    rating: 4.6,
    reviewCount: 302,
  ),
  const Product(
    id: 'seed-polarized-shades',
    imagePath: 'assets/images/polarized-sunglasses.jpg',
    name: 'Polarized Shades',
    category: 'Eyewear',
    currentPrice: 49.99,
    oldPrice: 69.99,
    discount: '28% OFF',
    availableSizes: ['One Size'],
    description:
        'UV400 polarized lenses cut glare for all-day outdoor wear, set in a '
        'lightweight, flexible frame that stays comfortable for hours.',
    rating: 4.2,
    reviewCount: 55,
  ),
  const Product(
    id: 'seed-wayfarer-grey',
    imagePath: 'assets/images/tomhawk_grey_wayfarer_polarized.jpg',
    name: 'Wayfarer Grey',
    category: 'Eyewear',
    currentPrice: 59.99,
    availableSizes: ['One Size'],
    description:
        'A classic wayfarer frame with grey polarized lenses — timeless shape that '
        'pairs with any outfit, from casual to smart-casual.',
    rating: 4.3,
    reviewCount: 40,
  ),
  const Product(
    id: 'seed-classic-timepiece',
    imagePath: 'assets/images/photo-1523275335684-37898b6baf30.jpg',
    name: 'Classic Timepiece',
    category: 'Watches',
    currentPrice: 299.99,
    oldPrice: 399.99,
    discount: '25% OFF',
    availableSizes: ['One Size'],
    description:
        'Elegant stainless steel watch with a sapphire crystal face, water-resistant '
        'to 50m, suitable for both the boardroom and everyday wear.',
    rating: 4.9,
    reviewCount: 178,
  ),
  const Product(
    id: 'seed-retro-round-frames',
    imagePath: 'assets/images/photo-1572635196237-14b3f281503f.jpg',
    name: 'Retro Round Frames',
    category: 'Eyewear',
    currentPrice: 39.99,
    oldPrice: 55.99,
    discount: '28% OFF',
    availableSizes: ['One Size'],
    description:
        'Vintage-inspired round sunglasses with gradient tinted lenses — a throwback '
        'silhouette that has stayed effortlessly on-trend.',
    rating: 4.1,
    reviewCount: 33,
  ),
  const Product(
    id: 'seed-smart-watch-series-x',
    imagePath: 'assets/images/OIP.2HxDL5GRe5WJSuOHMI1qBwHaHa.png',
    name: 'Smart Watch Series X',
    category: 'Watches',
    currentPrice: 179.99,
    oldPrice: 229.99,
    discount: '21% OFF',
    availableSizes: ['One Size'],
    description:
        'Feature-packed smartwatch with continuous health tracking, GPS, and up to '
        '5 days of battery life — stays connected without weighing you down.',
    rating: 4.5,
    reviewCount: 261,
  ),
];
