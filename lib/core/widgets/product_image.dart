import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;

  const ProductImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final image = url.trim().isEmpty
        ? _placeholder(context)
        : Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            semanticLabel: 'পণ্যের ছবি',
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _placeholder(
                context,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes == null
                      ? null
                      : progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _placeholder(context),
          );

    return ClipRRect(borderRadius: borderRadius, child: image);
  }

  Widget _placeholder(BuildContext context, {Widget? child}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: child ?? Icon(Icons.image_outlined, color: colors.outline, size: 32),
    );
  }
}
