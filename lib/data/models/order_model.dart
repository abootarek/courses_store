import 'package:equatable/equatable.dart';

class OrderModel extends Equatable {
  final String id;
  final String userId;
  final String userEmail;
  final String courseId;
  final String courseTitle;
  final double coursePrice;
  final String status; // 'pending', 'approved', or 'rejected'
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.courseId,
    required this.courseTitle,
    required this.coursePrice,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userEmail: json['userEmail'] as String,
      courseId: json['courseId'] as String,
      courseTitle: json['courseTitle'] as String,
      coursePrice: (json['coursePrice'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'coursePrice': coursePrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  OrderModel copyWith({String? status}) {
    return OrderModel(
      id: id,
      userId: userId,
      userEmail: userEmail,
      courseId: courseId,
      courseTitle: courseTitle,
      coursePrice: coursePrice,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, userEmail, courseId, courseTitle, coursePrice, status, createdAt];
}
