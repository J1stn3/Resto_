import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../utils/product_images.dart';
import 'responsive.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    this.imageUrl,
    this.sku,
    this.categoryName,
    this.width,
    this.height,
    this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.fit = BoxFit.cover,
  }) : _kind = null;

  /// Uses [AppImageSizes] when no explicit size is set.
  const ProductImage.adaptive({
    super.key,
    this.imageUrl,
    this.sku,
    this.categoryName,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.fit = BoxFit.cover,
    ImageSizeKind kind = ImageSizeKind.product,
  })  : width = null,
        height = null,
        size = null,
        _kind = kind;

  final String? imageUrl;
  final String? sku;
  final String? categoryName;
  final double? width;
  final double? height;
  final double? size;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final ImageSizeKind? _kind;

  @override
  Widget build(BuildContext context) {
    final resolved = size ?? width ?? _resolveAdaptiveSize(context);
    final h = height ?? size ?? resolved;
    final asset = resolveProductAsset(
      imageUrl: imageUrl,
      sku: sku,
      categoryName: categoryName,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: resolved,
        height: h,
        child: Image.asset(
          asset,
          width: resolved,
          height: h,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(resolved, h),
        ),
      ),
    );
  }

  double _resolveAdaptiveSize(BuildContext context) {
    return switch (_kind) {
      ImageSizeKind.cart => AppImageSizes.cartThumb(context),
      ImageSizeKind.list => AppImageSizes.listThumb(context),
      ImageSizeKind.product => AppImageSizes.productThumb(context),
      null => AppImageSizes.productThumb(context),
    };
  }

  Widget _placeholder(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: AppTheme.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_rounded,
        size: w < 44 ? 20 : 28,
        color: AppTheme.primary.withValues(alpha: 0.5),
      ),
    );
  }
}

enum ImageSizeKind { product, cart, list }

/// Category chip / list avatar from bundled assets.
class CategoryImage extends StatelessWidget {
  const CategoryImage({
    super.key,
    required this.categoryName,
    this.radius,
    this.kind = CategoryImageKind.list,
  });

  final String categoryName;
  final double? radius;
  final CategoryImageKind kind;

  @override
  Widget build(BuildContext context) {
    final r = radius ??
        switch (kind) {
          CategoryImageKind.chip => AppImageSizes.categoryChip(context),
          CategoryImageKind.list => AppImageSizes.categoryList(context),
        };
    final asset = categoryAssetForName(categoryName) ?? '$kCategoryImagesPath/default.jpg';
    return CircleAvatar(
      radius: r,
      backgroundImage: AssetImage(asset),
      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
    );
  }
}

enum CategoryImageKind { chip, list }
