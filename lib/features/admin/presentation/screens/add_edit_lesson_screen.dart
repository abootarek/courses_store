import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../data/models/lesson_model.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class AddEditLessonScreen extends StatefulWidget {
  final String courseId;
  final LessonModel? lesson;

  const AddEditLessonScreen({
    super.key,
    required this.courseId,
    this.lesson,
  });

  @override
  State<AddEditLessonScreen> createState() => _AddEditLessonScreenState();
}

class _AddEditLessonScreenState extends State<AddEditLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _videoUrlController;
  late TextEditingController _minutesController;
  late TextEditingController _secondsController;
  late TextEditingController _orderController;
  
  String? _imageBase64;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  bool get isEditing => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _descriptionController = TextEditingController(text: widget.lesson?.description ?? '');
    _videoUrlController = TextEditingController(text: widget.lesson?.videoUrl ?? '');
    
    final duration = widget.lesson?.duration ?? 0;
    _minutesController = TextEditingController(text: (duration ~/ 60).toString());
    _secondsController = TextEditingController(text: (duration % 60).toString());

    _orderController = TextEditingController(
      text: widget.lesson != null ? widget.lesson!.order.toString() : '1',
    );
    
    // Load existing image if editing
    if (widget.lesson?.imageBase64 != null) {
      _imageBase64 = widget.lesson!.imageBase64;
      try {
        _imageBytes = base64Decode(widget.lesson!.imageBase64!);
      } catch (e) {
        // Invalid base64, ignore
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        
        setState(() {
          _imageBase64 = base64String;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Lesson' : 'Add Lesson'),
        ),
        body: BlocConsumer<AdminCubit, AdminState>(
          listener: (context, state) {
            if (state is LessonsLoaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing ? 'Lesson updated!' : 'Lesson added!'),
                  backgroundColor: Colors.green,
                ),
              );
              context.pop();
            } else if (state is AdminError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AdminLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Lesson Title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter lesson title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter lesson description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Video URL',
                        prefixIcon: Icon(Icons.video_library),
                        border: OutlineInputBorder(),
                        hintText: 'YouTube URL or direct video link',
                        helperText: 'Paste YouTube link or direct video URL',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter video URL';
                        }
                        if (!value.startsWith('http')) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Lesson Thumbnail (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(_imageBase64 == null
                          ? 'Select Thumbnail Image'
                          : 'Change Thumbnail'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    if (_imageBytes != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minutesController,
                            decoration: const InputDecoration(
                              labelText: 'Minutes',
                              prefixIcon: Icon(Icons.timer),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _secondsController,
                            decoration: const InputDecoration(
                              labelText: 'Seconds',
                              prefixIcon: Icon(Icons.timer_outlined),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final seconds = int.tryParse(value);
                              if (seconds == null || seconds < 0 || seconds >= 60) {
                                return '0-59';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _orderController,
                      decoration: const InputDecoration(
                        labelText: 'Order',
                        prefixIcon: Icon(Icons.format_list_numbered),
                        border: OutlineInputBorder(),
                        hintText: 'Lesson order in the course',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter order';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                final lesson = LessonModel(
                                  id: widget.lesson?.id ?? const Uuid().v4(),
                                  courseId: widget.courseId,
                                  title: _titleController.text.trim(),
                                  description: _descriptionController.text.trim(),
                                  videoUrl: _videoUrlController.text.trim(),
                                  duration: (int.parse(_minutesController.text) * 60) +
                                      int.parse(_secondsController.text),
                                  order: int.parse(_orderController.text),
                                  imageBase64: _imageBase64,
                                );

                                if (isEditing) {
                                  context.read<AdminCubit>().updateLesson(lesson);
                                } else {
                                  context.read<AdminCubit>().addLesson(lesson);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEditing ? 'Update Lesson' : 'Add Lesson',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
