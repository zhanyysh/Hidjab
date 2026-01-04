class OrderModel {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final String? variantColor;
  final String? variantSize;
  final String? address;
  final double? locationLat;
  final double? locationLng;
  final Map<String, dynamic>? product; // Joined product data

  OrderModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.variantColor,
    this.variantSize,
    this.address,
    this.locationLat,
    this.locationLng,
    this.product,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      productId: map['product_id'] as String,
      quantity: map['quantity'] as int,
      totalPrice: (map['total_price'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      variantColor: map['variant_color'] as String?,
      variantSize: map['variant_size'] as String?,
      address: map['address'] as String?,
      locationLat: (map['location_lat'] as num?)?.toDouble(),
      locationLng: (map['location_lng'] as num?)?.toDouble(),
      product: map['products'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'total_price': totalPrice,
      'status': status,
      'variant_color': variantColor,
      'variant_size': variantSize,
      'address': address,
      'location_lat': locationLat,
      'location_lng': locationLng,
    };
  }
}
