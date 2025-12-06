import 'package:equatable/equatable.dart';

class LessonModel extends Equatable {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String videoUrl;
  final int duration; // in seconds
  final int order; // for sorting lessons
  final String? imageBase64; // optional thumbnail image as Base64

  const LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.duration,
    required this.order,
    this.imageBase64,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      videoUrl: json['videoUrl'] as String,
      duration: json['duration'] as int,
      order: json['order'] as int,
      imageBase64: json['imageBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'duration': duration,
      'order': order,
      if (imageBase64 != null) 'imageBase64': imageBase64,
    };
  }

  LessonModel copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    String? videoUrl,
    int? duration,
    int? order,
    String? imageBase64,
  }) {
    return LessonModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      duration: duration ?? this.duration,
      order: order ?? this.order,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }

  @override
  List<Object?> get props => [id, courseId, title, description, videoUrl, duration, order, imageBase64];

  String get durationFormatted {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
