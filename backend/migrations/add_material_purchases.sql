-- Alınan malzeme / stok gider kayıtları tablosu.
CREATE TABLE IF NOT EXISTS material_purchases (
  id SERIAL PRIMARY KEY,
  item_name VARCHAR(100) NOT NULL,
  quantity NUMERIC(10,2) NOT NULL DEFAULT 1,
  unit VARCHAR(30) NOT NULL DEFAULT 'adet',
  unit_price NUMERIC(10,2) NOT NULL DEFAULT 0,
  total_price NUMERIC(10,2) NOT NULL DEFAULT 0,
  description TEXT,
  purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
