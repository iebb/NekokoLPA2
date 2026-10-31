-- For a new local/test database. No automatic production migration is performed.
CREATE TABLE IF NOT EXISTS app_updates (
  app_name TEXT NOT NULL, platform TEXT NOT NULL, identifier TEXT NOT NULL,
  version TEXT, build INTEGER, url TEXT, data TEXT, updated_at TEXT, raw TEXT,
  PRIMARY KEY(app_name, platform, identifier)
);
CREATE TABLE IF NOT EXISTS git_records (
  app_name TEXT NOT NULL, commit_hash TEXT NOT NULL, version TEXT, build INTEGER,
  updated_at TEXT, PRIMARY KEY(app_name, commit_hash)
);
CREATE TABLE IF NOT EXISTS submissions (
  id INTEGER PRIMARY KEY, app_name TEXT, appId TEXT, bundleId TEXT, version TEXT,
  platform TEXT, state TEXT, notificationType TEXT, raw TEXT, timestamp TEXT
);
