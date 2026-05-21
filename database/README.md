# Database — MySQL Server Only

This project uses **MySQL Server** exclusively (not PostgreSQL, SQLite, or containerized databases).

## Requirements

- [MySQL Server 8.0+](https://dev.mysql.com/downloads/mysql/) installed locally
- MySQL service running (Windows: `MySQL80`)
- `mysql` CLI available in PATH

## Setup (recommended)

From project root:

```powershell
.\scripts\first-run.ps1
```

Enter your MySQL root password when prompted.

## Manual setup

```powershell
mysql -u root -p -P YOUR_PORT < database\01_schema.sql
mysql -u root -p -P YOUR_PORT < database\02_seed_data.sql
```

If MySQL uses a non-default port (e.g. `3305`), add `-P 3305` and set `DB_PORT=3305` in `backend\.env`.

## Convert existing prices to pesos

If your database still has old dollar-scale amounts (e.g. `12.99`):

```powershell
cd database
.\migrate-prices-to-php.cmd
```

Or manually:

```powershell
mysql -u root -p -P 3306 pos_system < database\04_convert_prices_to_php.sql
```

Safe to run once — rows already at PHP amounts (price ≥ 50) are skipped.

## Files

| File | Purpose |
|------|---------|
| `01_schema.sql` | Creates `pos_system` database and all tables |
| `02_seed_data.sql` | Default admin + sample menu data |
| `03_admin_only_migration.sql` | Migrates older multi-role schema to admin-only |
| `04_convert_prices_to_php.sql` | Converts existing USD-scale prices to Philippine pesos |
| `migrate-prices-to-php.cmd` | Runs the peso price migration (reads `backend\.env` port) |

## Default login

- Email: `admin@system.com`
- Password: `admin123`
