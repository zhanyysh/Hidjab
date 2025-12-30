class Product {
  final String id;
  final String name;
  final String description;
  final String type;
  final int quantity;
  final double price;
  final double discount;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.quantity,
    required this.price,
    required this.discount,
    this.imageUrl,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      type: map['type'] as String,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      imageUrl: map['image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'image_url': imageUrl,
    };
  }
}
