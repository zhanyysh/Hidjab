class ProductVariant {
  final String color;
  final String size;
  final int quantity;

  ProductVariant({
    required this.color,
    required this.size,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'size': size,
      'quantity': quantity,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      color: map['color'] as String,
      size: map['size'] as String,
      quantity: map['quantity'] as int,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final String type;
  final int quantity;
  final double price;
  final double originalPrice;
  final double discount;
  final List<String> imageUrls;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.quantity,
    required this.price,
    required this.originalPrice,
    required this.discount,
    required this.imageUrls,
    required this.variants,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      type: map['type'] as String,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      originalPrice: (map['original_price'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num).toDouble(),
      imageUrls: (map['image_urls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      variants: (map['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'quantity': quantity,
      'price': price,
      'original_price': originalPrice,
      'discount': discount,
      'image_urls': imageUrls,
      'variants': variants.map((e) => e.toMap()).toList(),
    };
  }
}
