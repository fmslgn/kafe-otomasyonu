-- Kafe bilgileri ve etkinlik/duyuru tabloları.

CREATE TABLE IF NOT EXISTS cafe_settings (
  id SERIAL PRIMARY KEY,
  cafe_name VARCHAR(150) NOT NULL DEFAULT 'Kafe Otomasyonu',
  opening_hours TEXT,
  address TEXT,
  phone VARCHAR(30),
  map_url TEXT,
  instagram_url TEXT,
  is_open BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cafe_events (
  id SERIAL PRIMARY KEY,
  title VARCHAR(150) NOT NULL,
  description TEXT,
  event_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Varsayılan kafe ayarı (id=1) yoksa eklenir.
INSERT INTO cafe_settings (id, cafe_name, opening_hours, is_open)
SELECT
  1,
  'Kafe Otomasyonu',
  'Hafta içi 09:00 - 22:00, Hafta sonu 10:00 - 23:00',
  TRUE
WHERE NOT EXISTS (SELECT 1 FROM cafe_settings WHERE id = 1);
