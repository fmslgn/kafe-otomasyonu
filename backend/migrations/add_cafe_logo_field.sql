-- Kafe logosu URL alanı.

ALTER TABLE cafe_settings
ADD COLUMN IF NOT EXISTS logo_url TEXT;
