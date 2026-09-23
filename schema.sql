
CREATE TABLE IF NOT EXISTS route_samples (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  facility TEXT NOT NULL,
  start_point TEXT NOT NULL,
  destination TEXT NOT NULL,
  meters REAL NOT NULL,
  steps INTEGER NOT NULL DEFAULT 0,
  duration_sec INTEGER NOT NULL DEFAULT 0,
  turns INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_route
ON route_samples(facility,start_point,destination,created_at);
