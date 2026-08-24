import 'package:flutter/material.dart';
import 'package:paikari_shop/core/widgets/product_image.dart';

class ProductGallery extends StatefulWidget {
  final List<String> images;
  final String fallbackUrl;

  const ProductGallery({
    super.key,
    required this.images,
    required this.fallbackUrl,
  });

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  late final PageController _pageController;
  int _currentPage = 0;

  List<String> get _imageUrls {
    final urls = [...widget.images, widget.fallbackUrl]
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();
    return urls.isEmpty ? [''] : urls;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = _imageUrls;
    return Semantics(
      label: 'পণ্যের ছবি, ${_currentPage + 1} / ${urls.length}',
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              itemCount: urls.length,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) => ProductImage(
                url: urls[index],
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (urls.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < urls.length; index++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: index == _currentPage ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: index == _currentPage ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
