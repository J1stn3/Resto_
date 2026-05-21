USE pos_system;

-- Default admin: admin@system.com / admin123
SET @pwd = '$2a$10$FPH.ONfAgquWmXjM3LE61OIgOPgXX8i.jOISCHZ2DpK2gg4krEWfO';

INSERT INTO users (id, name, email, password_hash, is_admin) VALUES
('u0000001-0000-4000-8000-000000000001', 'System Administrator', 'admin@system.com', @pwd, TRUE);

INSERT INTO categories (id, name, description, color, sort_order) VALUES
('c0000001-0000-4000-8000-000000000001', 'Appetizers', 'Starter dishes and small plates', '#FF6B6B', 1),
('c0000001-0000-4000-8000-000000000002', 'Main Courses', 'Primary dishes and entrees', '#4ECDC4', 2),
('c0000001-0000-4000-8000-000000000003', 'Beverages', 'Drinks, sodas, and refreshments', '#45B7D1', 3),
('c0000001-0000-4000-8000-000000000004', 'Desserts', 'Sweet treats and desserts', '#96CEB4', 4),
('c0000001-0000-4000-8000-000000000005', 'Salads', 'Fresh salads and healthy options', '#FECA57', 5),
('c0000001-0000-4000-8000-000000000006', 'Pizza', 'Various pizza options', '#FF9FF3', 6);

-- Prices in Philippine pesos (PHP)
INSERT INTO products (id, category_id, name, description, price, sku, preparation_time, sort_order) VALUES
('p0000001-0000-4000-8000-000000000001', 'c0000001-0000-4000-8000-000000000001', 'Buffalo Wings', 'Crispy chicken wings with buffalo sauce', 650.00, 'APP001', 15, 1),
('p0000001-0000-4000-8000-000000000002', 'c0000001-0000-4000-8000-000000000001', 'Mozzarella Sticks', 'Breaded mozzarella with marinara sauce', 450.00, 'APP002', 10, 2),
('p0000001-0000-4000-8000-000000000003', 'c0000001-0000-4000-8000-000000000001', 'Nachos Supreme', 'Tortilla chips with cheese and toppings', 575.00, 'APP003', 12, 3),
('p0000001-0000-4000-8000-000000000004', 'c0000001-0000-4000-8000-000000000001', 'Onion Rings', 'Crispy beer-battered onion rings', 400.00, 'APP004', 8, 4),
('p0000001-0000-4000-8000-000000000005', 'c0000001-0000-4000-8000-000000000002', 'Grilled Chicken Breast', 'Seasoned grilled chicken with vegetables', 950.00, 'MAIN001', 20, 1),
('p0000001-0000-4000-8000-000000000006', 'c0000001-0000-4000-8000-000000000002', 'Beef Steak', 'Premium cut beef steak cooked to order', 1350.00, 'MAIN002', 25, 2),
('p0000001-0000-4000-8000-000000000007', 'c0000001-0000-4000-8000-000000000002', 'Fish & Chips', 'Beer battered fish with crispy fries', 850.00, 'MAIN003', 18, 3),
('p0000001-0000-4000-8000-000000000008', 'c0000001-0000-4000-8000-000000000002', 'Pasta Carbonara', 'Creamy pasta with bacon and parmesan', 800.00, 'MAIN004', 15, 4),
('p0000001-0000-4000-8000-000000000009', 'c0000001-0000-4000-8000-000000000002', 'BBQ Ribs', 'Slow-cooked ribs with BBQ sauce', 1150.00, 'MAIN005', 30, 5),
('p0000001-0000-4000-8000-000000000010', 'c0000001-0000-4000-8000-000000000003', 'Coca Cola', 'Classic cola soft drink', 150.00, 'BEV001', 0, 1),
('p0000001-0000-4000-8000-000000000011', 'c0000001-0000-4000-8000-000000000003', 'Fresh Orange Juice', 'Freshly squeezed orange juice', 250.00, 'BEV002', 2, 2),
('p0000001-0000-4000-8000-000000000012', 'c0000001-0000-4000-8000-000000000003', 'Coffee', 'Freshly brewed coffee', 175.00, 'BEV003', 3, 3),
('p0000001-0000-4000-8000-000000000013', 'c0000001-0000-4000-8000-000000000003', 'Iced Tea', 'Refreshing iced tea', 150.00, 'BEV004', 1, 4),
('p0000001-0000-4000-8000-000000000014', 'c0000001-0000-4000-8000-000000000003', 'Milkshake - Vanilla', 'Creamy vanilla milkshake', 300.00, 'BEV005', 4, 5),
('p0000001-0000-4000-8000-000000000015', 'c0000001-0000-4000-8000-000000000004', 'Chocolate Cake', 'Rich chocolate cake with frosting', 350.00, 'DES001', 5, 1),
('p0000001-0000-4000-8000-000000000016', 'c0000001-0000-4000-8000-000000000004', 'Apple Pie', 'Classic apple pie with cinnamon', 300.00, 'DES002', 8, 2),
('p0000001-0000-4000-8000-000000000017', 'c0000001-0000-4000-8000-000000000004', 'Ice Cream Sundae', 'Vanilla ice cream with toppings', 250.00, 'DES003', 3, 3),
('p0000001-0000-4000-8000-000000000018', 'c0000001-0000-4000-8000-000000000004', 'Cheesecake', 'New York style cheesecake', 400.00, 'DES004', 5, 4),
('p0000001-0000-4000-8000-000000000019', 'c0000001-0000-4000-8000-000000000005', 'Caesar Salad', 'Romaine lettuce with caesar dressing', 500.00, 'SAL001', 8, 1),
('p0000001-0000-4000-8000-000000000020', 'c0000001-0000-4000-8000-000000000005', 'Greek Salad', 'Fresh vegetables with feta cheese', 600.00, 'SAL002', 10, 2),
('p0000001-0000-4000-8000-000000000021', 'c0000001-0000-4000-8000-000000000005', 'Garden Salad', 'Mixed greens with vegetables', 450.00, 'SAL003', 6, 3),
('p0000001-0000-4000-8000-000000000022', 'c0000001-0000-4000-8000-000000000006', 'Margherita Pizza', 'Classic pizza with tomato and mozzarella', 750.00, 'PIZ001', 16, 1),
('p0000001-0000-4000-8000-000000000023', 'c0000001-0000-4000-8000-000000000006', 'Pepperoni Pizza', 'Pizza with pepperoni and cheese', 850.00, 'PIZ002', 16, 2),
('p0000001-0000-4000-8000-000000000024', 'c0000001-0000-4000-8000-000000000006', 'Supreme Pizza', 'Pizza loaded with multiple toppings', 1000.00, 'PIZ003', 20, 3),
('p0000001-0000-4000-8000-000000000025', 'c0000001-0000-4000-8000-000000000006', 'Hawaiian Pizza', 'Pizza with ham and pineapple', 900.00, 'PIZ004', 16, 4);

INSERT INTO dining_tables (id, table_number, seating_capacity, location) VALUES
('t0000001-0000-4000-8000-000000000001', 'T01', 2, 'Main Floor'),
('t0000001-0000-4000-8000-000000000002', 'T02', 4, 'Main Floor'),
('t0000001-0000-4000-8000-000000000003', 'T03', 4, 'Main Floor'),
('t0000001-0000-4000-8000-000000000004', 'T04', 6, 'Main Floor'),
('t0000001-0000-4000-8000-000000000005', 'T05', 2, 'Main Floor'),
('t0000001-0000-4000-8000-000000000006', 'T06', 4, 'Window Side'),
('t0000001-0000-4000-8000-000000000007', 'T07', 4, 'Window Side'),
('t0000001-0000-4000-8000-000000000008', 'T08', 8, 'Private Room'),
('t0000001-0000-4000-8000-000000000009', 'T09', 2, 'Patio'),
('t0000001-0000-4000-8000-000000000010', 'T10', 4, 'Patio'),
('t0000001-0000-4000-8000-000000000011', 'BAR01', 1, 'Bar Counter'),
('t0000001-0000-4000-8000-000000000012', 'BAR02', 1, 'Bar Counter'),
('t0000001-0000-4000-8000-000000000013', 'BAR03', 1, 'Bar Counter'),
('t0000001-0000-4000-8000-000000000014', 'TAKEOUT', 1, 'Takeout Counter');

INSERT INTO inventory (id, product_id, current_stock, minimum_stock, maximum_stock, unit_cost)
SELECT UUID(), id, 50, 10, 100, price * 0.4 FROM products;

INSERT INTO orders (id, order_number, table_id, user_id, order_type, status, subtotal, tax_amount, total_amount) VALUES
('o0000001-0000-4000-8000-000000000001', 'ORD001', 't0000001-0000-4000-8000-000000000002', 'u0000001-0000-4000-8000-000000000001', 'dine_in', 'pending', 1600.00, 160.00, 1760.00),
('o0000001-0000-4000-8000-000000000002', 'ORD002', 't0000001-0000-4000-8000-000000000005', 'u0000001-0000-4000-8000-000000000001', 'dine_in', 'preparing', 950.00, 95.00, 1045.00),
('o0000001-0000-4000-8000-000000000003', 'ORD003', 't0000001-0000-4000-8000-000000000014', 'u0000001-0000-4000-8000-000000000001', 'takeout', 'completed', 750.00, 75.00, 825.00);

UPDATE dining_tables SET is_occupied = TRUE WHERE id IN ('t0000001-0000-4000-8000-000000000002', 't0000001-0000-4000-8000-000000000005');

INSERT INTO order_items (id, order_id, product_id, quantity, unit_price, total_price) VALUES
(UUID(), 'o0000001-0000-4000-8000-000000000001', 'p0000001-0000-4000-8000-000000000001', 1, 650.00, 650.00),
(UUID(), 'o0000001-0000-4000-8000-000000000001', 'p0000001-0000-4000-8000-000000000005', 1, 950.00, 950.00),
(UUID(), 'o0000001-0000-4000-8000-000000000002', 'p0000001-0000-4000-8000-000000000005', 1, 950.00, 950.00),
(UUID(), 'o0000001-0000-4000-8000-000000000003', 'p0000001-0000-4000-8000-000000000022', 1, 750.00, 750.00);

INSERT INTO payments (id, order_id, payment_method, amount, status, processed_by, processed_at) VALUES
(UUID(), 'o0000001-0000-4000-8000-000000000003', 'cash', 825.00, 'completed', 'u0000001-0000-4000-8000-000000000001', NOW());

UPDATE orders SET completed_at = NOW() WHERE order_number = 'ORD003';
