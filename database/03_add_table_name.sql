-- Add display name for dining tables (run once on existing databases)
ALTER TABLE dining_tables
  ADD COLUMN table_name VARCHAR(100) NULL AFTER table_number;

UPDATE dining_tables SET table_name = CONCAT('Table ', table_number) WHERE table_name IS NULL OR table_name = '';
