import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/animal_service.dart';

class AsyncAnimalImage extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const AsyncAnimalImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) return _placeholder();
    return FutureBuilder<String>(
      future: AnimalService().signedUrl(path!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _placeholder(loading: true);
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.network(
            snapshot.data!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(),
          ),
        );
      },
    );
  }

  Widget _placeholder({bool loading = false}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: borderRadius),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.agriculture, color: AppColors.darkGreen, size: 30),
      );
}
