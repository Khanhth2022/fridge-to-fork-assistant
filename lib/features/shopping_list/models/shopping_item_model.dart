class ShoppingItemModel {
  const ShoppingItemModel({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.checked,
    required this.sourceQuantities,
  });

  final String itemId;
  final String name;
  final double quantity;
  final String unit;
  final bool checked;
  final Map<String, double> sourceQuantities;

  ShoppingItemModel copyWith({
    String? itemId,
    String? name,
    double? quantity,
    String? unit,
    bool? checked,
    Map<String, double>? sourceQuantities,
  }) {
    return ShoppingItemModel(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      checked: checked ?? this.checked,
      sourceQuantities: sourceQuantities ?? this.sourceQuantities,
    );
  }

  String get normalizedKey => '${_normalize(name)}|${_normalize(unit)}';

  String get displayQuantity {
    if (quantity <= 0) {
      return '';
    }

    final double rounded = quantity.roundToDouble();
    final String quantityText = rounded == quantity
        ? rounded.toInt().toString()
        : quantity.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return unit.trim().isEmpty ? quantityText : '$quantityText $unit';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'checked': checked,
      'sourceQuantities': sourceQuantities,
    };
  }

  factory ShoppingItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingItemModel(
      itemId: (json['itemId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: (json['unit'] ?? '').toString(),
      checked: json['checked'] == true,
      sourceQuantities:
          (json['sourceQuantities'] as Map<dynamic, dynamic>? ??
                  const <dynamic, dynamic>{})
              .map(
                (dynamic key, dynamic value) =>
                    MapEntry(key.toString(), (value as num?)?.toDouble() ?? 0),
              ),
    );
  }

  static String _normalize(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
