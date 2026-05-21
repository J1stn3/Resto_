-- Migration: convert multi-role users table to admin-only schema
-- Run once on existing databases: mysql -u root -p pos_system < database/03_admin_only_migration.sql

USE pos_system;

-- Rebuild users table (admin-only)
CREATE TABLE IF NOT EXISTS users_new (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_admin BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO users_new (id, name, email, password_hash, is_admin, is_active, created_at, updated_at)
SELECT
    id,
    TRIM(CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, ''))),
    email,
    password_hash,
    TRUE,
    is_active,
    created_at,
    updated_at
FROM users
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- Ensure default admin exists
INSERT INTO users_new (id, name, email, password_hash, is_admin)
VALUES (
    'u0000001-0000-4000-8000-000000000001',
    'System Administrator',
    'admin@system.com',
    '$2a$10$FPH.ONfAgquWmXjM3LE61OIgOPgXX8i.jOISCHZ2DpK2gg4krEWfO',
    TRUE
)
ON DUPLICATE KEY UPDATE
    name = 'System Administrator',
    password_hash = '$2a$10$FPH.ONfAgquWmXjM3LE61OIgOPgXX8i.jOISCHZ2DpK2gg4krEWfO',
    is_admin = TRUE;

DROP TABLE users;
RENAME TABLE users_new TO users;

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);
