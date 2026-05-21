const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const pool = require('../config/database');
const { generateToken } = require('../middleware/auth');
const { success, error } = require('../utils/response');

async function login(req, res) {
  const { email, password, username } = req.body;
  const loginEmail = (email || username || '').trim().toLowerCase();
  if (!loginEmail || !password) {
    return error(res, 'Email and password are required', 400, 'missing_credentials');
  }

  let rows;
  try {
    [rows] = await pool.query(
      `SELECT id, name, email, password_hash, is_admin, is_active, created_at, updated_at
       FROM users WHERE LOWER(email) = ? AND is_active = TRUE`,
      [loginEmail]
    );
  } catch (dbErr) {
    if (dbErr.code === 'ER_BAD_FIELD_ERROR') {
      return error(
        res,
        'Database schema outdated. Run: mysql -u root -p < database/03_admin_only_migration.sql',
        503,
        'schema_outdated'
      );
    }
    throw dbErr;
  }

  if (!rows.length) return error(res, 'Invalid email or password', 401, 'invalid_credentials');

  const user = rows[0];
  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) return error(res, 'Invalid email or password', 401, 'invalid_credentials');

  delete user.password_hash;
  user.is_admin = true;
  const token = generateToken(user);
  return success(res, 'Login successful', { token, user });
}

async function me(req, res) {
  const [rows] = await pool.query(
    `SELECT id, name, email, is_admin, is_active, created_at, updated_at
     FROM users WHERE id = ?`,
    [req.user.id]
  );
  if (!rows.length) return error(res, 'User not found', 404, 'user_not_found');
  const user = rows[0];
  user.is_admin = true;
  return success(res, 'User retrieved successfully', user);
}

function logout(req, res) {
  return success(res, 'Logout successful');
}

async function register(req, res) {
  const { name, email, password } = req.body;
  const trimmedName = (name || '').trim();
  const normalizedEmail = (email || '').trim().toLowerCase();

  if (!trimmedName || !normalizedEmail || !password) {
    return error(res, 'Name, email, and password are required', 400, 'missing_credentials');
  }
  if (password.length < 6) {
    return error(res, 'Password must be at least 6 characters', 400, 'weak_password');
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
    return error(res, 'Enter a valid email address', 400, 'invalid_email');
  }

  const [existing] = await pool.query(
    'SELECT id FROM users WHERE LOWER(email) = ?',
    [normalizedEmail]
  );
  if (existing.length) {
    return error(res, 'An account with this email already exists', 409, 'email_taken');
  }

  const id = uuidv4();
  const hash = await bcrypt.hash(password, 10);
  await pool.query(
    `INSERT INTO users (id, name, email, password_hash, is_admin, is_active)
     VALUES (?, ?, ?, ?, TRUE, TRUE)`,
    [id, trimmedName, normalizedEmail, hash]
  );

  const user = {
    id,
    name: trimmedName,
    email: normalizedEmail,
    is_admin: true,
    is_active: true,
  };
  const token = generateToken(user);
  return success(res, 'Account created successfully', { token, user }, 201);
}

module.exports = { login, register, me, logout };
