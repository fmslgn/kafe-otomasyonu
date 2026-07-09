-- =========================================================
-- Modern Kafe Otomasyonu - PostgreSQL Kurulum Dosyası
-- Veritabanı adı önerisi: kafe_otomasyonu_db
-- =========================================================

-- Temiz kurulum için tabloları bağımlılık sırasına göre kaldırır.
DROP TABLE IF EXISTS cafe_events CASCADE;
DROP TABLE IF EXISTS cafe_settings CASCADE;
DROP TABLE IF EXISTS customer_feedback CASCADE;
DROP TABLE IF EXISTS product_commission_rules CASCADE;
DROP TABLE IF EXISTS commission_settings CASCADE;
DROP TABLE IF EXISTS material_purchases CASCADE;
DROP TABLE IF EXISTS expenses CASCADE;
DROP TABLE IF EXISTS package_order_items CASCADE;
DROP TABLE IF EXISTS package_orders CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS cafe_tables CASCADE;
DROP TABLE IF EXISTS app_users CASCADE;

-- updated_at alanlarını otomatik güncellemek için ortak trigger fonksiyonu.
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- Kullanıcılar
-- Roller: yonetici, garson, kurye
-- =========================================================
CREATE TABLE app_users (
  id SERIAL PRIMARY KEY,
  full_name VARCHAR(120) NOT NULL,
  username VARCHAR(60) NOT NULL UNIQUE,
  password VARCHAR(120) NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('yonetici', 'garson', 'kurye')),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- Kategoriler ve Ürünler
-- =========================================================
CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
  category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  description TEXT,
  image_url TEXT,
  is_visible BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- Masalar ve Masa Siparişleri
-- Masa durumları: bos, dolu
-- Sipariş durumları: aktif, kapandi
-- =========================================================
CREATE TABLE cafe_tables (
  id SERIAL PRIMARY KEY,
  table_no INTEGER NOT NULL UNIQUE CHECK (table_no > 0),
  status VARCHAR(20) NOT NULL DEFAULT 'bos' CHECK (status IN ('bos', 'dolu')),
  section VARCHAR(80) NOT NULL DEFAULT 'Genel'
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  table_id INTEGER NOT NULL REFERENCES cafe_tables(id) ON DELETE RESTRICT,
  user_id INTEGER NOT NULL REFERENCES app_users(id) ON DELETE RESTRICT,
  total_price NUMERIC(10, 2) NOT NULL DEFAULT 0,
  status VARCHAR(20) NOT NULL DEFAULT 'aktif' CHECK (status IN ('aktif', 'kapandi')),
  note TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity NUMERIC(10, 2) NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
  total_price NUMERIC(10, 2) NOT NULL CHECK (total_price >= 0)
);

-- =========================================================
-- Paket Siparişler ve Kurye Süreci
-- Sipariş durumları: aktif, kapandi, iptal
-- Teslimat durumları: bekliyor, kuryeye_atandi, yolda, teslim_edildi, iptal
-- =========================================================
CREATE TABLE package_orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES app_users(id) ON DELETE RESTRICT,
  courier_id INTEGER REFERENCES app_users(id) ON DELETE SET NULL,
  customer_name VARCHAR(120),
  customer_phone VARCHAR(40),
  address TEXT,
  note TEXT,
  total_price NUMERIC(10, 2) NOT NULL DEFAULT 0,
  status VARCHAR(20) NOT NULL DEFAULT 'aktif' CHECK (status IN ('aktif', 'kapandi', 'iptal')),
  delivery_status VARCHAR(30) NOT NULL DEFAULT 'bekliyor' CHECK (delivery_status IN ('bekliyor', 'kuryeye_atandi', 'yolda', 'teslim_edildi', 'iptal')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE package_order_items (
  id SERIAL PRIMARY KEY,
  package_order_id INTEGER NOT NULL REFERENCES package_orders(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity NUMERIC(10, 2) NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
  total_price NUMERIC(10, 2) NOT NULL CHECK (total_price >= 0)
);

-- =========================================================
-- Finans, Gider ve Malzeme Alım
-- =========================================================
CREATE TABLE expenses (
  id SERIAL PRIMARY KEY,
  title VARCHAR(160) NOT NULL,
  amount NUMERIC(10, 2) NOT NULL CHECK (amount > 0),
  description TEXT,
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE material_purchases (
  id SERIAL PRIMARY KEY,
  item_name VARCHAR(160) NOT NULL,
  quantity NUMERIC(10, 2) NOT NULL CHECK (quantity > 0),
  unit VARCHAR(30) NOT NULL DEFAULT 'adet',
  unit_price NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (unit_price >= 0),
  total_price NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (total_price >= 0),
  description TEXT,
  purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- Personel Prim Sistemi
-- =========================================================
CREATE TABLE commission_settings (
  id INTEGER PRIMARY KEY DEFAULT 1,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  default_rate NUMERIC(5, 2) NOT NULL DEFAULT 5,
  employee_of_month_bonus NUMERIC(10, 2) NOT NULL DEFAULT 0,
  courier_commission_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  courier_default_rate NUMERIC(5, 2) NOT NULL DEFAULT 3,
  courier_delivery_bonus NUMERIC(10, 2) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT commission_settings_single_row CHECK (id = 1)
);

CREATE TRIGGER trg_commission_settings_updated_at
BEFORE UPDATE ON commission_settings
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE product_commission_rules (
  id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  target_quantity NUMERIC(10, 2) NOT NULL CHECK (target_quantity > 0),
  bonus_amount NUMERIC(10, 2) NOT NULL CHECK (bonus_amount >= 0),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_product_commission_rules_updated_at
BEFORE UPDATE ON product_commission_rules
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- Müşteri Geri Bildirimleri
-- Türler: istek, sikayet, oneri
-- Durumlar: bekliyor, incelendi, tamamlandi, reddedildi
-- =========================================================
CREATE TABLE customer_feedback (
  id SERIAL PRIMARY KEY,
  feedback_type VARCHAR(20) NOT NULL DEFAULT 'istek' CHECK (feedback_type IN ('istek', 'sikayet', 'oneri')),
  customer_name VARCHAR(120),
  customer_phone VARCHAR(40),
  table_number INTEGER,
  message TEXT NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'bekliyor' CHECK (status IN ('bekliyor', 'incelendi', 'tamamlandi', 'reddedildi')),
  manager_note TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_customer_feedback_updated_at
BEFORE UPDATE ON customer_feedback
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- Kafe Ayarları ve Etkinlikler
-- =========================================================
CREATE TABLE cafe_settings (
  id INTEGER PRIMARY KEY DEFAULT 1,
  cafe_name VARCHAR(160) NOT NULL DEFAULT 'Modern Kafe',
  opening_hours VARCHAR(160),
  address TEXT,
  phone VARCHAR(40),
  map_url TEXT,
  instagram_url TEXT,
  is_open BOOLEAN NOT NULL DEFAULT TRUE,
  theme_key VARCHAR(40) NOT NULL DEFAULT 'brown',
  primary_color VARCHAR(20) NOT NULL DEFAULT '#795548',
  menu_layout VARCHAR(20) NOT NULL DEFAULT 'vertical' CHECK (menu_layout IN ('vertical', 'horizontal')),
  logo_url TEXT,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT cafe_settings_single_row CHECK (id = 1)
);

CREATE TRIGGER trg_cafe_settings_updated_at
BEFORE UPDATE ON cafe_settings
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE cafe_events (
  id SERIAL PRIMARY KEY,
  title VARCHAR(160) NOT NULL,
  description TEXT,
  event_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_cafe_events_updated_at
BEFORE UPDATE ON cafe_events
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- Varsayılan Kayıtlar
-- =========================================================
INSERT INTO app_users (full_name, username, password, role, is_active) VALUES
('Sistem Yöneticisi', 'admin', '1234', 'yonetici', TRUE),
('Garson Kullanıcı', 'garson', '1234', 'garson', TRUE),
('Kurye Kullanıcı', 'kurye', '1234', 'kurye', TRUE);

INSERT INTO categories (name) VALUES
('Sıcak İçecekler'),
('Soğuk İçecekler'),
('Tatlılar'),
('Yiyecekler');

INSERT INTO products (name, price, category_id, description, is_active, is_visible) VALUES
('Türk Kahvesi', 60.00, 1, 'Geleneksel Türk kahvesi', TRUE, TRUE),
('Çay', 25.00, 1, 'Demleme çay', TRUE, TRUE),
('Limonata', 55.00, 2, 'Ev yapımı limonata', TRUE, TRUE),
('Cheesecake', 95.00, 3, 'Günlük tatlı seçeneği', TRUE, TRUE),
('Tost', 80.00, 4, 'Kaşarlı tost', TRUE, TRUE);

INSERT INTO cafe_tables (table_no, status, section) VALUES
(1, 'bos', 'Salon'),
(2, 'bos', 'Salon'),
(3, 'bos', 'Salon'),
(4, 'bos', 'Bahçe'),
(5, 'bos', 'Bahçe');

INSERT INTO commission_settings (
  id,
  is_enabled,
  default_rate,
  employee_of_month_bonus,
  courier_commission_enabled,
  courier_default_rate,
  courier_delivery_bonus
) VALUES (1, TRUE, 5, 0, TRUE, 3, 0);

INSERT INTO cafe_settings (
  id,
  cafe_name,
  opening_hours,
  address,
  phone,
  is_open,
  theme_key,
  primary_color,
  menu_layout
) VALUES (
  1,
  'Modern Kafe',
  '09:00 - 23:00',
  'Adres bilgisi yönetici panelinden güncellenebilir.',
  '0000 000 00 00',
  TRUE,
  'brown',
  '#795548',
  'vertical'
);

INSERT INTO cafe_events (title, description, event_date, is_active) VALUES
('Haftanın Fırsatı', 'QR menü üzerinden güncel kampanyaları takip edebilirsiniz.', CURRENT_DATE, TRUE);

-- Sık kullanılan alanlar için indeksler.
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_package_orders_status ON package_orders(status);
CREATE INDEX idx_package_orders_courier_id ON package_orders(courier_id);
CREATE INDEX idx_package_orders_created_at ON package_orders(created_at);
CREATE INDEX idx_package_order_items_package_order_id ON package_order_items(package_order_id);
CREATE INDEX idx_expenses_expense_date ON expenses(expense_date);
CREATE INDEX idx_material_purchases_purchase_date ON material_purchases(purchase_date);
CREATE INDEX idx_customer_feedback_status ON customer_feedback(status);

-- Kurulum sonrası kontrol için örnek sorgular:
-- SELECT * FROM app_users;
-- SELECT * FROM categories;
-- SELECT * FROM products;
-- SELECT * FROM cafe_tables;
