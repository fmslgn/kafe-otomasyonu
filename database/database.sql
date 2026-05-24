-- =========================================================
-- Kafe Otomasyonu PostgreSQL Veritabanı Yapısı
-- Bu dosya tabloları oluşturur ve başlangıç verilerini ekler.
-- =========================================================

-- Eski tablolar varsa silinir.
-- Böylece dosya tekrar çalıştırıldığında hata alma ihtimali azalır.
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS expenses CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS cafe_tables CASCADE;
DROP TABLE IF EXISTS app_users CASCADE;

-- =========================================================
-- 1. Kullanıcılar Tablosu
-- Garson ve yönetici kullanıcıları bu tabloda tutulur.
-- =========================================================
CREATE TABLE app_users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('garson', 'yonetici')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 2. Masalar Tablosu
-- Kafedeki masa bilgileri ve masa durumları tutulur.
-- status: bos / dolu
-- =========================================================
CREATE TABLE cafe_tables (
    id SERIAL PRIMARY KEY,
    table_no INTEGER UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'bos' CHECK (status IN ('bos', 'dolu')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 3. Kategoriler Tablosu
-- Menü ürünlerinin kategorileri tutulur.
-- Örnek: Çorbalar, Pideler, Kebaplar
-- =========================================================
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- =========================================================
-- 4. Ürünler Tablosu
-- Menüdeki ürünler ve fiyatları tutulur.
-- =========================================================
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 5. Siparişler Tablosu
-- Masa bazlı ana sipariş bilgileri tutulur.
-- status: aktif / kapandi / iptal
-- =========================================================
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    table_id INTEGER NOT NULL REFERENCES cafe_tables(id),
    user_id INTEGER REFERENCES app_users(id),
    total_price NUMERIC(10, 2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'aktif' CHECK (status IN ('aktif', 'kapandi', 'iptal')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 6. Sipariş Detayları Tablosu
-- Bir siparişin içindeki ürünler burada tutulur.
-- =========================================================
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    total_price NUMERIC(10, 2) NOT NULL CHECK (total_price >= 0)
);

-- =========================================================
-- 7. Giderler Tablosu
-- İşletmeye ait gider kayıtları tutulur.
-- =========================================================
CREATE TABLE expenses (
    id SERIAL PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- Başlangıç Kullanıcıları
-- Not: Şifreler şimdilik düz yazıldı. Backend aşamasında hash yapısı eklenebilir.
-- =========================================================
INSERT INTO app_users (full_name, username, password, role) VALUES
('Garson Kullanıcı', 'garson', '123456', 'garson'),
('Yönetici Kullanıcı', 'yonetici', '123456', 'yonetici');

-- =========================================================
-- Başlangıç Masaları
-- 12 masa oluşturulur.
-- =========================================================
INSERT INTO cafe_tables (table_no, status) VALUES
(1, 'bos'),
(2, 'bos'),
(3, 'bos'),
(4, 'bos'),
(5, 'bos'),
(6, 'bos'),
(7, 'bos'),
(8, 'bos'),
(9, 'bos'),
(10, 'bos'),
(11, 'bos'),
(12, 'bos');

-- =========================================================
-- Menü Kategorileri
-- =========================================================
INSERT INTO categories (name) VALUES
('Çorbalar'),
('Pideler'),
('Kebaplar'),
('Tatlılar'),
('İçecekler');

-- =========================================================
-- Menü Ürünleri
-- category_id değerleri yukarıdaki kategorilere göre verildi.
-- 1: Çorbalar
-- 2: Pideler
-- 3: Kebaplar
-- 4: Tatlılar
-- 5: İçecekler
-- =========================================================
INSERT INTO products (category_id, name, price) VALUES
(1, 'Mercimek Çorbası', 70.00),
(1, 'Ezogelin Çorbası', 75.00),
(1, 'Tavuk Çorbası', 85.00),

(2, 'Kıymalı Pide', 180.00),
(2, 'Kaşarlı Pide', 160.00),
(2, 'Kuşbaşılı Pide', 220.00),

(3, 'Adana Kebap', 250.00),
(3, 'Urfa Kebap', 250.00),
(3, 'Tavuk Şiş', 210.00),

(4, 'Baklava', 120.00),
(4, 'Sütlaç', 90.00),
(4, 'Künefe', 140.00),

(5, 'Çay', 20.00),
(5, 'Ayran', 35.00),
(5, 'Kola', 50.00);

-- =========================================================
-- Örnek Gider Kaydı
-- =========================================================
INSERT INTO expenses (title, amount, expense_date, description) VALUES
('Günlük malzeme alımı', 1500.00, CURRENT_DATE, 'Mutfak ve servis malzemeleri alındı.');