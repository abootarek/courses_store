import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../data/models/course_model.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _videoUrlController = TextEditingController();
  
  String? _imageBase64;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
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
          title: const Text('Add New Course'),
        ),
        body: BlocConsumer<AdminCubit, AdminState>(
          listener: (context, state) {
            if (state is CourseAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Course added successfully!'),
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
                        labelText: 'Course Title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter course title';
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
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter course description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter course price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _discountController,
                      decoration: InputDecoration(
                        labelText: 'Discount (%)',
                        prefixIcon: const Icon(Icons.local_offer),
                        border: const OutlineInputBorder(),
                        hintText: '0-100',
                        helperText: _discountController.text.isNotEmpty &&
                                _priceController.text.isNotEmpty &&
                                int.tryParse(_discountController.text) !=
                                    null &&
                                double.tryParse(_priceController.text) != null
                            ? 'Discounted price: \$${(double.parse(_priceController.text) - (double.parse(_priceController.text) * int.parse(_discountController.text) / 100)).toStringAsFixed(2)}'
                            : 'Optional: Enter discount percentage',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          setState(() {}), // Refresh to show calculated price
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final discount = int.tryParse(value);
                          if (discount == null) {
                            return 'Please enter a valid number';
                          }
                          if (discount < 0 || discount > 100) {
                            return 'Discount must be between 0 and 100';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Course Cover Image',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(_imageBase64 == null
                          ? 'Select Image from Gallery'
                          : 'Change Image'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    if (_imageBytes != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
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
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Preview Video (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Video URL',
                        prefixIcon: Icon(Icons.video_library),
                        border: OutlineInputBorder(),
                        hintText: 'YouTube URL or direct video link',
                        helperText: 'Optional: Add a preview video',
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                if (_imageBase64 == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a course image'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                final course = CourseModel(
                                  id: const Uuid().v4(),
                                  title: _titleController.text.trim(),
                                  description:
                                      _descriptionController.text.trim(),
                                  price: double.parse(_priceController.text),
                                  discount:
                                      int.tryParse(_discountController.text) ??
                                          0,
                                  imageBase64: _imageBase64!,
                                  videoUrl: _videoUrlController.text.trim(),
                                  createdAt: DateTime.now(),
                                );

                                context.read<AdminCubit>().addCourse(course);
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
                          : const Text('Add Course',
                              style: TextStyle(fontSize: 16)),
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
