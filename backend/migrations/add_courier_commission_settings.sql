-- Kurye prim ayarları için commission_settings tablosuna alanlar eklenir.
-- Mevcut garson prim ayarları korunur.

ALTER TABLE commission_settings
ADD COLUMN IF NOT EXISTS courier_commission_enabled BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE commission_settings
ADD COLUMN IF NOT EXISTS courier_default_rate NUMERIC(5, 2) NOT NULL DEFAULT 3;

ALTER TABLE commission_settings
ADD COLUMN IF NOT EXISTS courier_delivery_bonus NUMERIC(10, 2) NOT NULL DEFAULT 0;
