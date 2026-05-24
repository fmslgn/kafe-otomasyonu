-- Kafe ayarlarına tema rengi ve QR menü görünüm alanları eklenir.

ALTER TABLE cafe_settings
ADD COLUMN IF NOT EXISTS theme_key VARCHAR(30) NOT NULL DEFAULT 'brown';

ALTER TABLE cafe_settings
ADD COLUMN IF NOT EXISTS primary_color VARCHAR(20) NOT NULL DEFAULT '#795548';

ALTER TABLE cafe_settings
ADD COLUMN IF NOT EXISTS menu_layout VARCHAR(30) NOT NULL DEFAULT 'vertical';
