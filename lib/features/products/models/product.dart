class WholesaleTier {
  final int minQuantity;
  final double price;

  const WholesaleTier({
    required this.minQuantity,
    required this.price,
  });

  factory WholesaleTier.fromJson(Map<String, dynamic> json) {
    return WholesaleTier(
      minQuantity: json['minQuantity'] as int,
      price: (json['price'] as num).toDouble(),
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

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.retailPrice,
    required this.wholesaleTiers,
    required this.imageUrl,
    required this.category,
    required this.isAvailable,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      retailPrice: (json['retailPrice'] as num).toDouble(),
      wholesaleTiers: (json['wholesaleTiers'] as List<dynamic>)
          .map((e) => WholesaleTier.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      isAvailable: json['isAvailable'] as bool,
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
    };
  }
}
