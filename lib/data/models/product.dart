class Dimensions {
  final double width;
  final double height;
  final double depth;

  const Dimensions(this.width, this.height, this.depth);

  factory Dimensions.fromJson(Map<String, dynamic> json) => Dimensions(
    (json['width'] as num?)?.toDouble() ?? 0,
    (json['height'] as num?)?.toDouble() ?? 0,
    (json['depth'] as num?)?.toDouble() ?? 0,
  );
}

class Review {
  final int rating;
  final String comment;
  final DateTime? date;
  final String reviewerName;
  final String reviewerEmail;

  const Review({
    required this.rating,
    required this.comment,
    required this.date,
    required this.reviewerName,
    required this.reviewerEmail,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    rating: (json['rating'] as num?)?.toInt() ?? 0,
    comment: json['comment'] as String? ?? '',
    date: DateTime.tryParse(json['date'] as String? ?? ''),
    reviewerName: json['reviewerName'] as String? ?? 'Anonymous',
    reviewerEmail: json['reviewerEmail'] as String? ?? '',
  );
}

class ProductMeta {
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? barcode;
  final String? qrCode;

  const ProductMeta({
    this.createdAt,
    this.updatedAt,
    this.barcode,
    this.qrCode,
  });

  factory ProductMeta.fromJson(Map<String, dynamic> json) => ProductMeta(
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    barcode: json['barcode'] as String?,
    qrCode: json['qrCode'] as String?,
  );
}

class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final List<String> tags;
  final String? brand;
  final String? sku;
  final double? weight;
  final Dimensions? dimensions;
  final String? warrantyInformation;
  final String? shippingInformation;
  final String? availabilityStatus;
  final List<Review> reviews;
  final String? returnPolicy;
  final int? minimumOrderQuantity;
  final ProductMeta? meta;
  final String thumbnail;
  final List<String> images;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.thumbnail,
    required this.images,
    this.tags = const [],
    this.brand,
    this.sku,
    this.weight,
    this.dimensions,
    this.warrantyInformation,
    this.shippingInformation,
    this.availabilityStatus,
    this.reviews = const [],
    this.returnPolicy,
    this.minimumOrderQuantity,
    this.meta,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
    brand: json['brand'] as String?,
    sku: json['sku'] as String?,
    weight: (json['weight'] as num?)?.toDouble(),
    dimensions: json['dimensions'] is Map<String, dynamic>
        ? Dimensions.fromJson(json['dimensions'] as Map<String, dynamic>)
        : null,
    warrantyInformation: json['warrantyInformation'] as String?,
    shippingInformation: json['shippingInformation'] as String?,
    availabilityStatus: json['availabilityStatus'] as String?,
    reviews: (json['reviews'] as List<dynamic>? ?? const [])
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList(),
    returnPolicy: json['returnPolicy'] as String?,
    minimumOrderQuantity: (json['minimumOrderQuantity'] as num?)?.toInt(),
    meta: json['meta'] is Map<String, dynamic>
        ? ProductMeta.fromJson(json['meta'] as Map<String, dynamic>)
        : null,
    thumbnail: json['thumbnail'] as String? ?? '',
    images: (json['images'] as List<dynamic>? ?? const []).cast<String>(),
  );
}

class ProductPage {
  final List<Product> products;
  final int total;

  const ProductPage(this.products, this.total);
}
