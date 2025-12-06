import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';

class CourseRepository {
  final FirebaseFirestore _firestore;

  CourseRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  // Upload video file
  Future<String> uploadVideo(File file, String folder) async {
    try {
      // Sanitize filename
      final originalName = file.path.split('/').last;
      final sanitizedName = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      final ref = _storage.ref().child('$folder/$fileName');
      
      print('Starting upload to: ${ref.fullPath}');

      // Add metadata
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {'uploaded_by': 'admin'},
      );

      try {
        final uploadTask = await ref.putFile(file, metadata);
        if (uploadTask.state == TaskState.success) {
           return await uploadTask.ref.getDownloadURL();
        } else {
          throw Exception('Upload failed with state: ${uploadTask.state}');
        }
      } catch (e) {
        print('putFile failed: $e. Retrying with putData...');
        // Fallback to putData (non-resumable)
        final bytes = await file.readAsBytes();
        final uploadTask = await ref.putData(bytes, metadata);
        return await uploadTask.ref.getDownloadURL();
      }
     
    } catch (e) {
      print('Error uploading video: $e');
      throw Exception('Failed to upload video: $e');
    }
  }


  // Add a new course (Admin only)
  Future<void> addCourse(CourseModel course) async {
    try {
      await _firestore.collection('courses').doc(course.id).set(course.toJson());
    } catch (e) {
      throw Exception('Failed to add course: $e');
    }
  }

  // Update an existing course (Admin only)
  Future<void> updateCourse(CourseModel course) async {
    try {
      await _firestore.collection('courses').doc(course.id).update(course.toJson());
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }

  // Get all courses
  Future<List<CourseModel>> getCourses() async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CourseModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get courses: $e');
    }
  }

  // Get a single course by ID
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      final doc = await _firestore.collection('courses').doc(courseId).get();
      if (!doc.exists) return null;

      return CourseModel.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      throw Exception('Failed to get course: $e');
    }
  }

  // Delete a course (Admin only)
  Future<void> deleteCourse(String courseId) async {
    try {
      // Delete all lessons first
      final lessonsSnapshot = await _firestore
          .collection('lessons')
          .where('courseId', isEqualTo: courseId)
          .get();
      
      for (var doc in lessonsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Then delete the course
      await _firestore.collection('courses').doc(courseId).delete();
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  // ========== Lesson CRUD Operations ==========

  // Add a new lesson to a course
  Future<void> addLesson(LessonModel lesson) async {
    try {
      await _firestore.collection('lessons').doc(lesson.id).set(lesson.toJson());
      
      // Update course lessons count
      await _updateCourseLessonsCount(lesson.courseId);
    } catch (e) {
      throw Exception('Failed to add lesson: $e');
    }
  }

  // Get all lessons for a course
  Future<List<LessonModel>> getLessonsByCourseId(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('lessons')
          .where('courseId', isEqualTo: courseId)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => LessonModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get lessons: $e');
    }
  }

  // Update an existing lesson
  Future<void> updateLesson(LessonModel lesson) async {
    try {
      await _firestore.collection('lessons').doc(lesson.id).update(lesson.toJson());
    } catch (e) {
      throw Exception('Failed to update lesson: $e');
    }
  }

  // Delete a lesson
  Future<void> deleteLesson(String lessonId, String courseId) async {
    try {
      await _firestore.collection('lessons').doc(lessonId).delete();
      
      // Update course lessons count
      await _updateCourseLessonsCount(courseId);
    } catch (e) {
      throw Exception('Failed to delete lesson: $e');
    }
  }

  // Helper: Update course lessons count
  Future<void> _updateCourseLessonsCount(String courseId) async {
    try {
      final lessonsSnapshot = await _firestore
          .collection('lessons')
          .where('courseId', isEqualTo: courseId)
          .get();

      await _firestore.collection('courses').doc(courseId).update({
        'lessonsCount': lessonsSnapshot.docs.length,
      });
    } catch (e) {
      throw Exception('Failed to update lessons count: $e');
    }
  }
}
