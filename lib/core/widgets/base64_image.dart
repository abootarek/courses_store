import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Widget to display Base64 encoded images
class Base64Image extends StatelessWidget {
  final String base64String;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const Base64Image({
    super.key,
    required this.base64String,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (base64String.isEmpty) {
      return errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 50, color: Colors.grey),
          );
    }

    try {
      final Uint8List bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              );
        },
      );
    } catch (e) {
      return errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          );
    }
  }
}
