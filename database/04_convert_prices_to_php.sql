-- Migration: convert USD-scale prices to Philippine pesos (PHP)
-- Safe to run once on existing databases. Skips rows already in peso range (price >= 50).
-- Run: mysql -u root -p pos_system < database/04_convert_prices_to_php.sql

USE pos_system;

-- 1) Menu products
UPDATE products
SET price = CASE sku
    WHEN 'APP001' THEN 650.00
    WHEN 'APP002' THEN 450.00
    WHEN 'APP003' THEN 575.00
    WHEN 'APP004' THEN 400.00
    WHEN 'MAIN001' THEN 950.00
    WHEN 'MAIN002' THEN 1350.00
    WHEN 'MAIN003' THEN 850.00
    WHEN 'MAIN004' THEN 800.00
    WHEN 'MAIN005' THEN 1150.00
    WHEN 'BEV001' THEN 150.00
    WHEN 'BEV002' THEN 250.00
    WHEN 'BEV003' THEN 175.00
    WHEN 'BEV004' THEN 150.00
    WHEN 'BEV005' THEN 300.00
    WHEN 'DES001' THEN 350.00
    WHEN 'DES002' THEN 300.00
    WHEN 'DES003' THEN 250.00
    WHEN 'DES004' THEN 400.00
    WHEN 'SAL001' THEN 500.00
    WHEN 'SAL002' THEN 600.00
    WHEN 'SAL003' THEN 450.00
    WHEN 'PIZ001' THEN 750.00
    WHEN 'PIZ002' THEN 850.00
    WHEN 'PIZ003' THEN 1000.00
    WHEN 'PIZ004' THEN 900.00
    ELSE ROUND(price * 50, 2)
END
WHERE price < 50;

-- 2) Inventory unit cost (40% of product price)
UPDATE inventory i
INNER JOIN products p ON i.product_id = p.id
SET i.unit_cost = ROUND(p.price * 0.4, 2);

-- 3) Order line items (match current product prices)
UPDATE order_items oi
INNER JOIN products p ON oi.product_id = p.id
SET
    oi.unit_price = p.price,
    oi.total_price = ROUND(p.price * oi.quantity, 2)
WHERE oi.unit_price < 50;

-- 4) Order totals from line items (10% tax)
UPDATE orders o
INNER JOIN (
    SELECT order_id, COALESCE(SUM(total_price), 0) AS sub
    FROM order_items
    GROUP BY order_id
) s ON s.order_id = o.id
SET
    o.subtotal = s.sub,
    o.tax_amount = ROUND(s.sub * 0.10, 2),
    o.total_amount = ROUND(s.sub * 1.10, 2)
WHERE o.total_amount < 500;

-- 5) Payments linked to migrated orders
UPDATE payments pay
INNER JOIN orders o ON pay.order_id = o.id
SET pay.amount = o.total_amount
WHERE pay.amount < 500;

SELECT 'Migration complete — sample product prices:' AS status;
SELECT sku, name, price FROM products ORDER BY sort_order LIMIT 8;
