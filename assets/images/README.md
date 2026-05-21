# Menu images (bundled assets)


## Products

- Path: `assets/images/products/{SKU}.jpg`
- Example: `APP001.jpg` for SKU `APP001`
- Fallback: `default.jpg`

## Categories

- Path: `assets/images/categories/{slug}.jpg`
- Slugs: `appetizers`, `main_courses`, `beverages`, `desserts`, `salads`, `pizza`

## Add a new product

1. Save a JPG as `assets/images/products/YOUR_SKU.jpg`
2. Run `flutter pub get` (if you added new files)
3. Hot restart the app

Optional: set DB `image_url` to `products/YOUR_SKU.jpg` via Admin → Menu.
