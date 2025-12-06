import 'package:equatable/equatable.dart';

class CourseModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageBase64; // Course cover image as Base64
  final String videoUrl; // Preview video URL
  final int lessonsCount;
  final int discount; // Discount percentage (0-100)
  final DateTime createdAt;

  // Computed properties
  bool get hasDiscount => discount > 0;
  double get discountedPrice => price - (price * discount / 100);

  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.imageBase64 = '', // Default empty for backward compatibility
    required this.videoUrl,
    this.lessonsCount = 0,
    this.discount = 0, // Default no discount
    required this.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageBase64: json['imageBase64'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      lessonsCount: json['lessonsCount'] as int? ?? 0,
      discount: json['discount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imageBase64': imageBase64,
      'videoUrl': videoUrl,
      'lessonsCount': lessonsCount,
      'discount': discount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? imageBase64,
    String? videoUrl,
    int? lessonsCount,
    int? discount,
    DateTime? createdAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageBase64: imageBase64 ?? this.imageBase64,
      videoUrl: videoUrl ?? this.videoUrl,
      lessonsCount: lessonsCount ?? this.lessonsCount,
      discount: discount ?? this.discount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, description, price, imageBase64, videoUrl, lessonsCount, discount, createdAt];
}
