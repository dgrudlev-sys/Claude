import * as SQLite from 'expo-sqlite';
import * as FileSystem from 'expo-file-system';

import migration001 from './migrations/001_initial.sql';
import migration002 from './migrations/002_fts5.sql';
import migration003 from './migrations/003_topics.sql';
import migration004 from './migrations/004_crossrefs.sql';

const MIGRATIONS = [
  { version: 1, sql: migration001 },
  { version: 2, sql: migration002 },
  { version: 3, sql: migration003 },
  { version: 4, sql: migration004 },
];

let _db: SQLite.SQLiteDatabase | null = null;

export async function getDatabase(): Promise<SQLite.SQLiteDatabase> {
  if (_db) return _db;

  _db = await SQLite.openDatabaseAsync('beacon_bible.db', {
    useNewConnection: false,
  });

  await _db.execAsync('PRAGMA journal_mode = WAL;');
  await _db.execAsync('PRAGMA foreign_keys = ON;');
  await _db.execAsync('PRAGMA cache_size = -8000;'); // 8MB cache

  await runMigrations(_db);

  return _db;
}

async function runMigrations(db: SQLite.SQLiteDatabase): Promise<void> {
  // Ensure migrations table exists first
  await db.execAsync(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version     INTEGER PRIMARY KEY,
      applied_at  INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
    );
  `);

  const applied = await db.getAllAsync<{ version: number }>(
    'SELECT version FROM schema_migrations ORDER BY version;'
  );
  const appliedVersions = new Set(applied.map(r => r.version));

  for (const migration of MIGRATIONS) {
    if (appliedVersions.has(migration.version)) continue;

    try {
      await db.execAsync(migration.sql);
      console.log(`[DB] Migration ${migration.version} applied`);
    } catch (err) {
      console.error(`[DB] Migration ${migration.version} failed:`, err);
      throw err;
    }
  }
}

export async function closeDatabase(): Promise<void> {
  if (_db) {
    await _db.closeAsync();
    _db = null;
  }
}
