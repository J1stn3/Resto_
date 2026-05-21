-- Point product images to bundled Flutter assets (no network URLs)
USE pos_system;

UPDATE products
SET image_url = CONCAT('products/', sku, '.jpg')
WHERE sku IS NOT NULL AND sku <> '';

SELECT sku, name, image_url FROM products ORDER BY sort_order LIMIT 6;
