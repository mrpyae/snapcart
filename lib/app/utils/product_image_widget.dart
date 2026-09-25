import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app_colors.dart';
import 'formatters.dart';

class ProductImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const ProductImageWidget({
    Key? key,
    this.imageUrl,
    this.width = 44,
    this.height = 44,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildPlaceholder();
    }

    String trimmed = imageUrl!.trim();

    // If multiple images encoded as JSON array or pipe-separated, take the first one
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final List<dynamic> list = jsonDecode(trimmed);
        if (list.isNotEmpty) trimmed = list.first.toString().trim();
      } catch (_) {}
    } else if (trimmed.contains('|')) {
      final parts = trimmed.split('|');
      if (parts.isNotEmpty) trimmed = parts.first.trim();
    }

    // Base64 Data URI
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        final base64Str = commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
        final bytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          ),
        );
      } catch (_) {
        return _buildPlaceholder();
      }
    }

    // HTTP / HTTPS URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: trimmed,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: AppColors.cardBgLight,
            child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5))),
          ),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.checkroom_rounded,
        size: width * 0.5,
        color: AppColors.primaryLight,
      ),
    );
  }
}

// Multi-Image Gallery with Zoom & Dual Price (Retail & Wholesale) Display
class MultiImageGalleryView extends StatefulWidget {
  final List<String> images;
  final double retailPrice;
  final double wholesalePrice;
  final double minWholesaleQty;
  final String unit;

  const MultiImageGalleryView({
    Key? key,
    required this.images,
    required this.retailPrice,
    this.wholesalePrice = 0.0,
    this.minWholesaleQty = 5.0,
    this.unit = 'piece',
  }) : super(key: key);

  @override
  State<MultiImageGalleryView> createState() => _MultiImageGalleryViewState();
}

class _MultiImageGalleryViewState extends State<MultiImageGalleryView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;
    final currentImage = hasImages ? widget.images[_currentIndex] : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Zoomable Image Preview with Price Badges
        Container(
          width: double.infinity,
          height: 290,
          decoration: BoxDecoration(
            color: AppColors.cardBgLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              // Zoomable Interactive Viewer
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: ProductImageWidget(
                      imageUrl: currentImage,
                      width: double.infinity,
                      height: 290,
                      borderRadius: 16,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Top Price Tag Overlay (Retail & Wholesale)
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Retail Price Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondary, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Retail: ', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          Text(
                            Formatters.formatCurrency(widget.retailPrice),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),

                    // Wholesale Price Pill (if set)
                    if (widget.wholesalePrice > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Wholesale (≥${widget.minWholesaleQty.toInt()} ${widget.unit}): ',
                                style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            Text(
                              Formatters.formatCurrency(widget.wholesalePrice),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Indicator / Counter
              if (widget.images.length > 1)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Photo ${_currentIndex + 1} of ${widget.images.length}',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              // Zoom Hint
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.pinch_rounded, size: 12, color: Colors.white70),
                      SizedBox(width: 4),
                      Text('Pinch / Scroll to zoom', style: TextStyle(fontSize: 9.5, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Thumbnail Selector Strip (if multiple photos)
        if (widget.images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final isSelected = _currentIndex == idx;
                return InkWell(
                  onTap: () => setState(() => _currentIndex = idx),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.secondary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ProductImageWidget(
                      imageUrl: widget.images[idx],
                      width: 48,
                      height: 48,
                      borderRadius: 6,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
