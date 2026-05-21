# Restaurant POS System — Flutter + MySQL Server

A restaurant point-of-sale system built with **Flutter** and **Node.js + Express**, using **MySQL Server** as the only database.

## Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter 3, BLoC, GoRouter, Dio |
| Backend | Node.js, Express, mysql2 |
| Database | **MySQL Server 8.0+** (local install only) |

## Prerequisites

1. [MySQL Server 8.0+](https://dev.mysql.com/downloads/mysql/) — install and start the service (`MySQL80` on Windows)
2. [Node.js](https://nodejs.org) 18+
3. [Flutter SDK](https://flutter.dev) 3.11+
4. `mysql` command-line client in your PATH

## Quick Start

### 1. Configure MySQL Server

```powershell
cd resto_pos_system
.\scripts\first-run.ps1
```

Enter your MySQL port (default `3306`, or `3305` if customized) and root password.

### 2. Start backend

```powershell
cd backend
npm install
npm run dev
```

API: `http://localhost:8080/api/v1`

### 3. Start Flutter

```powershell
flutter pub get
flutter run -d chrome
```

## Default admin account

| Email | Password |
|-------|----------|
| `admin@system.com` | `admin123` |

All authenticated users have full admin access (no roles).

## Project structure

```
resto_pos_system/
├── database/          # MySQL Server SQL scripts
├── backend/           # Express API (mysql2 driver)
├── lib/               # Flutter app
└── scripts/           # MySQL setup helpers
```

## Backend environment (`backend/.env`)

```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_root_password
DB_NAME=pos_system
PORT=8080
JWT_SECRET=change-me-in-production
TAX_RATE=0.10
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Database connection failed | Run `.\scripts\first-run.ps1` |
| Port 3306 in use / wrong port | Check `my.ini` for `port=`; set `DB_PORT` in `.env` |
| Access denied | Verify MySQL root password |
| MySQL not running | `Start-Service MySQL80` (Windows) |

## License

MIT
