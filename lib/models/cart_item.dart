class CartItem {
  final String id;
  final String title;
  final String price;
  final String originalPrice;
  final String image;
  final String description;
  final String codigoSap;
  final String? textura;
  int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.image,
    required this.description,
    required this.codigoSap,
    this.textura,
    this.quantity = 1,
  });

  // Precio numérico para cálculos
  double get numericPrice {
    try {
      // Remover símbolos y convertir a número
      final cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanPrice) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Precio original numérico
  double get numericOriginalPrice {
    try {
      if (originalPrice.isEmpty) return 0.0;
      final cleanPrice = originalPrice.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanPrice) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Precio total del item
  double get totalPrice => numericPrice * quantity;

  // Precio total original del item
  double get totalOriginalPrice => numericOriginalPrice * quantity;

  // Descuento por item
  double get discount {
    if (numericOriginalPrice <= 0) return 0.0;
    return numericOriginalPrice - numericPrice;
  }

  // Porcentaje de descuento
  double get discountPercentage {
    if (numericOriginalPrice <= 0) return 0.0;
    return (discount / numericOriginalPrice) * 100;
  }

  // Descuento total del item (descuento por unidad * cantidad)
  double get totalDiscount => discount * quantity;

  // Verificar si el item tiene descuento
  bool get hasDiscount => discount > 0;

  // Precio formateado para mostrar
  String get formattedPrice {
    return '\$${numericPrice.toStringAsFixed(2)}';
  }

  // Precio original formateado
  String get formattedOriginalPrice {
    if (numericOriginalPrice <= 0) return '';
    return '\$${numericOriginalPrice.toStringAsFixed(2)}';
  }

  // Precio total formateado
  String get formattedTotalPrice {
    return '\$${totalPrice.toStringAsFixed(2)}';
  }

  // Descuento formateado
  String get formattedDiscount {
    if (!hasDiscount) return '';
    return '\$${discount.toStringAsFixed(2)}';
  }

  // Porcentaje de descuento formateado
  String get formattedDiscountPercentage {
    if (!hasDiscount) return '';
    return '${discountPercentage.toStringAsFixed(0)}% OFF';
  }

  // Convertir a JSON para envío a API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'originalPrice': originalPrice,
      'image': image,
      'description': description,
      'codigoSap': codigoSap,
      'textura': textura,
      'quantity': quantity,
      'numericPrice': numericPrice,
      'totalPrice': totalPrice,
      'discount': discount,
      'hasDiscount': hasDiscount,
    };
  }

  // Crear desde JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: json['price']?.toString() ?? '\$0',
      originalPrice: json['originalPrice']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      codigoSap: json['codigoSap']?.toString() ?? '',
      textura: json['textura']?.toString(),
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
    );
  }

  // Crear copia con modificaciones
  CartItem copyWith({
    String? id,
    String? title,
    String? price,
    String? originalPrice,
    String? image,
    String? description,
    String? codigoSap,
    String? textura,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      image: image ?? this.image,
      description: description ?? this.description,
      codigoSap: codigoSap ?? this.codigoSap,
      textura: textura ?? this.textura,
      quantity: quantity ?? this.quantity,
    );
  }

  // Incrementar cantidad
  CartItem incrementQuantity() {
    return copyWith(quantity: quantity + 1);
  }

  // Decrementar cantidad
  CartItem decrementQuantity() {
    if (quantity <= 1) return this;
    return copyWith(quantity: quantity - 1);
  }

  // Establecer cantidad específica
  CartItem setQuantity(int newQuantity) {
    if (newQuantity < 1) return this;
    return copyWith(quantity: newQuantity);
  }

  // Validar si el item es válido
  bool get isValid {
    return id.isNotEmpty && 
           title.isNotEmpty && 
           codigoSap.isNotEmpty && 
           numericPrice > 0 && 
           quantity > 0;
  }

  // Obtener información resumida del item
  String get summary {
    final discountInfo = hasDiscount ? ' ($formattedDiscountPercentage)' : '';
    return '$title - $formattedPrice x$quantity$discountInfo';
  }

  @override
  String toString() {
    return 'CartItem('
        'id: $id, '
        'title: $title, '
        'price: $price, '
        'quantity: $quantity, '
        'codigoSap: $codigoSap, '
        'totalPrice: $formattedTotalPrice'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && 
           other.id == id && 
           other.codigoSap == codigoSap;
  }

  @override
  int get hashCode => Object.hash(id, codigoSap);

  // Método para debugging
  String toDebugString() {
    return '''
CartItem Debug Info:
  ID: $id
  Title: $title
  CodigoSAP: $codigoSap
  Price: $price (Numeric: $numericPrice)
  Original Price: $originalPrice (Numeric: $numericOriginalPrice)
  Quantity: $quantity
  Total Price: $formattedTotalPrice
  Discount: $formattedDiscount ($formattedDiscountPercentage)
  Has Discount: $hasDiscount
  Is Valid: $isValid
  Textura: ${textura ?? 'N/A'}
  Image: $image
  Description: ${description.length > 50 ? '${description.substring(0, 50)}...' : description}
''';
  }
}
