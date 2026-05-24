-- Garson prim sistemi ayar tablosu.
CREATE TABLE IF NOT EXISTS commission_settings (
  id SERIAL PRIMARY KEY,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  default_rate NUMERIC(5,2) NOT NULL DEFAULT 5,
  employee_of_month_bonus NUMERIC(10,2) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ürün bazlı ekstra prim kuralları tablosu.
CREATE TABLE IF NOT EXISTS product_commission_rules (
  id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  target_quantity NUMERIC(10,2) NOT NULL DEFAULT 1,
  bonus_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Varsayılan prim ayarı (tek kayıt).
INSERT INTO commission_settings (id, is_enabled, default_rate, employee_of_month_bonus)
SELECT 1, TRUE, 5, 0
WHERE NOT EXISTS (SELECT 1 FROM commission_settings WHERE id = 1);
