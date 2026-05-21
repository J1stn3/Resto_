/// Local asset paths for menu / POS images.
const String kProductImagesPath = 'assets/images/products';
const String kCategoryImagesPath = 'assets/images/categories';

String? productAssetForSku(String? sku) {
  if (sku == null || sku.isEmpty) return null;
  if (_productSkus.contains(sku)) return '$kProductImagesPath/$sku.jpg';
  return null;
}

String? categoryAssetForName(String? categoryName) {
  if (categoryName == null || categoryName.isEmpty) return null;
  final key = _categoryKeys[categoryName];
  if (key == null) return null;
  return '$kCategoryImagesPath/$key.jpg';
}

/// Resolves image to a bundled asset path (never a network URL).
String resolveProductAsset({String? imageUrl, String? sku, String? categoryName}) {
  final fromDb = imageUrl?.trim();
  if (fromDb != null && fromDb.isNotEmpty) {
    if (fromDb.startsWith('assets/')) return fromDb;
    // Legacy DB value: products/APP001.jpg
    if (fromDb.startsWith('products/')) return '$kProductImagesPath/${fromDb.substring(9)}';
    if (fromDb.startsWith('categories/')) return '$kCategoryImagesPath/${fromDb.substring(11)}';
  }
  return productAssetForSku(sku) ??
      categoryAssetForName(categoryName) ??
      '$kProductImagesPath/default.jpg';
}

const _productSkus = {
  'APP001', 'APP002', 'APP003', 'APP004',
  'MAIN001', 'MAIN002', 'MAIN003', 'MAIN004', 'MAIN005',
  'BEV001', 'BEV002', 'BEV003', 'BEV004', 'BEV005',
  'DES001', 'DES002', 'DES003', 'DES004',
  'SAL001', 'SAL002', 'SAL003',
  'PIZ001', 'PIZ002', 'PIZ003', 'PIZ004',
};

const _categoryKeys = {
  'Appetizers': 'appetizers',
  'Main Courses': 'main_courses',
  'Beverages': 'beverages',
  'Desserts': 'desserts',
  'Salads': 'salads',
  'Pizza': 'pizza',
};
