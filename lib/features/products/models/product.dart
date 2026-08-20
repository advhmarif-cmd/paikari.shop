class WholesaleTier {
  final int minQuantity;
  final double price;

  const WholesaleTier({
    required this.minQuantity,
    required this.price,
  });

  factory WholesaleTier.fromJson(Map<String, dynamic> json) {
    return WholesaleTier(
      minQuantity: (json['minQuantity'] ?? json['min_quantity'] ?? 1) as int,
      price: ((json['price'] as num?) ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minQuantity': minQuantity,
      'price': price,
    };
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double retailPrice;
  final List<WholesaleTier> wholesaleTiers;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final String source;
  final String? originProductId;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.retailPrice,
    required this.wholesaleTiers,
    required this.imageUrl,
    required this.category,
    required this.isAvailable,
    this.source = 'paikari',
    this.originProductId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawTiers = (json['wholesaleTiers'] ?? json['wholesale_tiers'] ?? const []) as List<dynamic>;
    final rawImages = (json['images'] as List<dynamic>?) ?? const [];
    final rawImageUrl = json['imageUrl'] ?? json['image_url'];
    final imageUrl = rawImageUrl as String? ?? (rawImages.isNotEmpty ? rawImages.first as String : '');
    final rawRetailPrice = json['retailPrice'] ?? json['retail_price'] ?? json['sale_price'];
    final rawAvailable = json['isAvailable'] ?? json['is_active'];

    return Product(
      id: json['id'] as String,
      name: (json['name'] ?? json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      retailPrice: (rawRetailPrice as num? ?? 0).toDouble(),
      wholesaleTiers: rawTiers
          .map((tier) => WholesaleTier.fromJson(Map<String, dynamic>.from(tier as Map)))
          .toList(),
      imageUrl: imageUrl,
      category: (json['category'] ?? '') as String,
      isAvailable: (rawAvailable as bool?) ?? true,
      source: (json['source'] ?? 'paikari') as String,
      originProductId: json['origin_product_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'retailPrice': retailPrice,
      'wholesaleTiers': wholesaleTiers.map((e) => e.toJson()).toList(),
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'source': source,
      'origin_product_id': originProductId,
    };
  }
}
