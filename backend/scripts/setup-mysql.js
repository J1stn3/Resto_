   /**
 * Initialize MySQL Server database for Restaurant POS.
 * Usage: node scripts/setup-mysql.js YOUR_ROOT_PASSWORD
 *    or: set MYSQL_PASSWORD=xxx && node scripts/setup-mysql.js
 */
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

const password = process.argv[2] || process.env.MYSQL_PASSWORD;
const port = parseInt(process.env.DB_PORT || '3305', 10);
const host = process.env.DB_HOST || '127.0.0.1';
const user = process.env.DB_USER || 'root';

if (!password) {
  console.error('\nUsage: node scripts/setup-mysql.js YOUR_MYSQL_ROOT_PASSWORD');
  console.error('Example: node scripts/setup-mysql.js MySecretPass123\n');
  process.exit(1);
}

const rootDir = path.join(__dirname, '..', '..');
const schemaFile = path.join(rootDir, 'database', '01_schema.sql');
const seedFile = path.join(rootDir, 'database', '02_seed_data.sql');
const envFile = path.join(__dirname, '..', '.env');

async function runSqlFile(conn, filePath) {
  const sql = fs.readFileSync(filePath, 'utf8');
  await conn.query(sql);
}

async function main() {
  console.log(`Connecting to MySQL Server at ${host}:${port}...`);

  const conn = await mysql.createConnection({
    host,
    port,
    user,
    password,
    multipleStatements: true,
  });

  const [[{ version }]] = await conn.query('SELECT VERSION() AS version');
  console.log(`Connected: MySQL ${version}`);

  console.log('Creating schema...');
  await runSqlFile(conn, schemaFile);

  console.log('Seeding data...');
  await runSqlFile(conn, seedFile);

  await conn.end();

  // Write .env
  const env = `DB_HOST=${host}
DB_PORT=${port}
DB_USER=${user}
DB_PASSWORD=${password}
DB_NAME=pos_system
PORT=8080
NODE_ENV=development
JWT_SECRET=your-secret-key-change-this-in-production
JWT_EXPIRES_IN=24h
TAX_RATE=0.10
`;
  fs.writeFileSync(envFile, env);
  console.log(`\nUpdated ${envFile}`);
  console.log('\nDone! Login with: admin@system.com / admin123');
  console.log('Restart backend: npm run dev\n');
}

main().catch((err) => {
  console.error('\nSetup failed:', err.message);
  if (err.code === 'ER_ACCESS_DENIED_ERROR') {
    console.error('Wrong MySQL password. Use the root password from MySQL installation.');
  }
  if (err.code === 'ECONNREFUSED') {
    console.error('MySQL Server not running. Start service: Start-Service MySQL80');
  }
  process.exit(1);
});
