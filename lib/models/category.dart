import 'package:flutter/material.dart';

class Category {
  String id;
  String name;
  String icon; // Icon name as string (e.g., "UtensilsCrossed", "Briefcase")
  String color; // Hex color string (e.g., "#f97316")
  String type; // 'income' or 'expense'
  double? budgetLimit; // Optional budget limit (for local use)
  DateTime? createdAt;
  DateTime? updatedAt;
  String? profileId; // User who created this category
  String? groupId; // Group this category belongs to

  // Backward compatibility: store old format
  int? iconCode;
  int? colorValue;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.type = 'expense',
    this.budgetLimit,
    this.createdAt,
    this.updatedAt,
    this.iconCode,
    this.colorValue,
    this.profileId,
    this.groupId,
  });

  // Getters for UI
  IconData get iconData {
    // Map icon codes to predefined constant IconData
    if (iconCode != null) {
      // Use a map of common Material Icons code points to their constants
      const iconCodeMap = {
        0xe59c: Icons.shopping_cart,
        0xe8cb: Icons.shopping_bag,
        0xe8d1: Icons.store,
        0xe56c: Icons.restaurant,
        0xe57a: Icons.fastfood,
        0xe541: Icons.local_cafe,
        0xe558: Icons.local_pizza,
        0xe556: Icons.lunch_dining,
        0xe533: Icons.dinner_dining,
        0xe318: Icons.home,
        0xe3bf: Icons.house,
        0xe25a: Icons.apartment,
        0xe531: Icons.directions_car,
        0xe542: Icons.local_gas_station,
        0xe559: Icons.local_taxi,
        0xe530: Icons.directions_bus,
        0xe56f: Icons.directions_subway,
        0xe570: Icons.train,
        0xe515: Icons.two_wheeler,
        0xe405: Icons.movie,
        0xe8da: Icons.theater_comedy,
        0xe3a1: Icons.music_note,
        0xe8fd: Icons.sports_soccer,
        0xe25e: Icons.fitness_center,
        0xe3af: Icons.medical_services,
        0xe548: Icons.local_hospital,
        0xeffa: Icons.medication,
        0xe80c: Icons.school,
        0xe865: Icons.book,
        0xe02f: Icons.library_books,
        0xe539: Icons.flight,
        0xe549: Icons.hotel,
        0xe9c4: Icons.luggage,
        0xe0b0: Icons.phone,
        0xe32c: Icons.phone_android,
        0xeb84: Icons.wifi,
        0xe333: Icons.tv,
        0xe30a: Icons.computer,
        0xec1c: Icons.electric_bolt,
        0xe798: Icons.water_drop,
        0xe53e: Icons.local_laundry_service,
        0xe91d: Icons.pets,
        0xe3fb: Icons.child_care,
        0xe7e9: Icons.cake,
        0xe638: Icons.checkroom,
        0xe85e: Icons.spa,
        0xe14e: Icons.content_cut,
        0xe8f9: Icons.work,
        0xe0af: Icons.business,
        0xe84f: Icons.account_balance,
        0xe2eb: Icons.savings,
        0xe227: Icons.attach_money,
        0xf8ff: Icons.wallet,
        0xe870: Icons.credit_card,
        0xeae8: Icons.receipt,
        0xe574: Icons.category,
      };

      return iconCodeMap[iconCode] ?? Icons.category;
    }

    // Try to parse icon string to IconData
    final iconMap = {
      'ShoppingCart': Icons.shopping_cart,
      'ShoppingBag': Icons.shopping_bag,
      'Store': Icons.store,
      'Restaurant': Icons.restaurant,
      'UtensilsCrossed': Icons.restaurant,
      'FastFood': Icons.fastfood,
      'Cafe': Icons.local_cafe,
      'Pizza': Icons.local_pizza,
      'Lunch': Icons.lunch_dining,
      'Dinner': Icons.dinner_dining,
      'Home': Icons.home,
      'House': Icons.house,
      'Apartment': Icons.apartment,
      'Car': Icons.directions_car,
      'GasStation': Icons.local_gas_station,
      'Taxi': Icons.local_taxi,
      'Bus': Icons.directions_bus,
      'Subway': Icons.directions_subway,
      'Train': Icons.train,
      'Bike': Icons.two_wheeler,
      'Movie': Icons.movie,
      'Theater': Icons.theater_comedy,
      'Music': Icons.music_note,
      'Sports': Icons.sports_soccer,
      'Fitness': Icons.fitness_center,
      'MedicalServices': Icons.medical_services,
      'Hospital': Icons.local_hospital,
      'Medication': Icons.medication,
      'School': Icons.school,
      'Book': Icons.book,
      'Library': Icons.library_books,
      'Flight': Icons.flight,
      'Hotel': Icons.hotel,
      'Luggage': Icons.luggage,
      'Phone': Icons.phone,
      'Mobile': Icons.phone_android,
      'Internet': Icons.wifi,
      'TV': Icons.tv,
      'Computer': Icons.computer,
      'Electricity': Icons.electric_bolt,
      'Water': Icons.water_drop,
      'Laundry': Icons.local_laundry_service,
      'Pets': Icons.pets,
      'ChildCare': Icons.child_care,
      'Gifts': Icons.cake,
      'Clothing': Icons.checkroom,
      'Beauty': Icons.spa,
      'Haircut': Icons.content_cut,
      'Work': Icons.work,
      'Briefcase': Icons.work,
      'Business': Icons.business,
      'Bank': Icons.account_balance,
      'Savings': Icons.savings,
      'Money': Icons.attach_money,
      'Wallet': Icons.wallet,
      'CreditCard': Icons.credit_card,
      'Receipt': Icons.receipt,
      'Category': Icons.category,
    };

    return iconMap[icon] ?? Icons.category;
  }

  Color get colorData {
    // Parse hex color string
    if (colorValue != null) {
      return Color(colorValue!);
    }

    try {
      final hexColor = color.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    String? type,
    double? budgetLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? iconCode,
    int? colorValue,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'type': type,
    if (budgetLimit != null) 'budgetLimit': budgetLimit,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (profileId != null) 'profileId': profileId,
    if (groupId != null) 'groupId': groupId,
    // Include old format for backward compatibility
    if (iconCode != null) 'iconCode': iconCode,
    if (colorValue != null) 'colorValue': colorValue,
  };

  factory Category.fromJson(Map<String, dynamic> json) {
    // Handle both old format (iconCode/colorValue) and new format (icon/color)
    final hasOldFormat =
        json.containsKey('iconCode') && json.containsKey('colorValue');
    final hasNewFormat = json.containsKey('icon') && json.containsKey('color');

    String iconStr;
    String colorStr;
    int? iconCodeVal;
    int? colorValueVal;

    if (hasNewFormat) {
      // Firebase format
      iconStr = json['icon'] as String;
      colorStr = json['color'] as String;
    } else if (hasOldFormat) {
      // Old local storage format - convert to new format
      iconCodeVal = json['iconCode'] as int;
      colorValueVal = json['colorValue'] as int;
      iconStr = 'Unknown'; // Placeholder
      colorStr =
          '#${(colorValueVal & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    } else {
      // Default values
      iconStr = 'Category';
      colorStr = '#2196F3';
    }

    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: iconStr,
      color: colorStr,
      type: json['type'] as String? ?? 'expense',
      budgetLimit: json['budgetLimit'] != null
          ? (json['budgetLimit'] as num).toDouble()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      iconCode: iconCodeVal,
      colorValue: colorValueVal,
      profileId: json['profileId'] as String?,
      groupId: json['groupId'] as String?,
    );
  }
}
