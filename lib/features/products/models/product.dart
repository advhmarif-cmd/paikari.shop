class WholesaleTier {
  final int minQuantity;
  final double price;

  const WholesaleTier({
    required this.minQuantity,
    required this.price,
  });

  factory WholesaleTier.fromJson(Map<String, dynamic> json) {
    return WholesaleTier(
      minQuantity: ((json['minQuantity'] ?? json['min_quantity']) as num?)?.toInt() ?? 1,
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
  final String? sku;
  final String unitLabel;
  final int moq;
  final int? stockQuantity;
  final int reservedQuantity;
  final int lowStockThreshold;
  final bool allowBackorder;
  final bool isNegotiable;
  final String approvalStatus;
  final String? vendorId;
  final String? vendorName;
  final int? availableQuantitySnapshot;

  int get availableQuantity {
    if (availableQuantitySnapshot != null) return availableQuantitySnapshot!;
    if (stockQuantity == null) return 0;
    final remaining = stockQuantity! - reservedQuantity;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isLowStock => stockQuantity != null &&
      availableQuantity > 0 &&
      availableQuantity <= lowStockThreshold;

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
    this.sku,
    this.unitLabel = 'unit',
    this.moq = 1,
    this.stockQuantity,
    this.reservedQuantity = 0,
    this.lowStockThreshold = 5,
    this.allowBackorder = false,
    this.isNegotiable = false,
    this.approvalStatus = 'approved',
    this.vendorId,
    this.vendorName,
    this.availableQuantitySnapshot,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawTiers = (json['wholesaleTiers'] ?? json['wholesale_tiers'] ?? const []) as List<dynamic>;
    final rawImages = (json['images'] as List<dynamic>?) ?? const [];
    final rawImageUrl = json['imageUrl'] ?? json['image_url'];
    final imageUrl = rawImageUrl as String? ?? (rawImages.isNotEmpty ? rawImages.first as String : '');
    final rawRetailPrice = json['retailPrice'] ?? json['retail_price'] ?? json['sale_price'];
    final rawAvailable = json['isAvailable'] ?? json['is_active'];
    final stockQuantity = (json['stock_quantity'] as num?)?.toInt();
    final reservedQuantity = (json['reserved_quantity'] as num?)?.toInt() ?? 0;
    final availableQuantitySnapshot = (json['available_quantity'] as num?)?.toInt();
    final allowBackorder = json['allow_backorder'] as bool? ?? false;
    final hasStock = availableQuantitySnapshot != null
        ? availableQuantitySnapshot > 0 || allowBackorder
        : stockQuantity == null || stockQuantity - reservedQuantity > 0 || allowBackorder;

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
      isAvailable: (rawAvailable as bool? ?? true) && hasStock,
      source: (json['source'] ?? 'paikari') as String,
      originProductId: json['origin_product_id'] as String?,
      sku: json['sku'] as String?,
      unitLabel: (json['unit_label'] ?? 'unit') as String,
      moq: (json['moq'] as num?)?.toInt() ?? 1,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt(),
      reservedQuantity: (json['reserved_quantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 5,
      allowBackorder: json['allow_backorder'] as bool? ?? false,
      isNegotiable: json['is_negotiable'] as bool? ?? false,
      approvalStatus: (json['approval_status'] ?? 'approved') as String,
      vendorId: (json['owner_id'] ?? json['vendor_id']) as String?,
      vendorName: (json['vendor_store_name'] ?? json['vendor_name']) as String?,
      availableQuantitySnapshot: availableQuantitySnapshot,
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
      'sku': sku,
      'unit_label': unitLabel,
      'moq': moq,
      'stock_quantity': stockQuantity,
      'reserved_quantity': reservedQuantity,
      'low_stock_threshold': lowStockThreshold,
      'allow_backorder': allowBackorder,
      'is_negotiable': isNegotiable,
      'approval_status': approvalStatus,
      'owner_id': vendorId,
    };
  }
}
