const jwt = require('jsonwebtoken');
const { error } = require('../utils/response');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-this-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '24h';

function generateToken(user) {
  return jwt.sign(
    { user_id: user.id, email: user.email, is_admin: true },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN, issuer: 'pos-system' }
  );
}

function authenticate(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return error(res, 'Authentication required', 401, 'auth_required');
  }
  try {
    const payload = jwt.verify(header.slice(7), JWT_SECRET);
    req.user = { id: payload.user_id, email: payload.email, is_admin: true };
    next();
  } catch {
    return error(res, 'Invalid or expired token', 401, 'invalid_token');
  }
}

module.exports = { generateToken, authenticate, JWT_SECRET };
