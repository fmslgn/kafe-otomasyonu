-- QR menü müşteri istek / şikayet / öneri tablosu.

CREATE TABLE IF NOT EXISTS customer_feedback (
  id SERIAL PRIMARY KEY,
  feedback_type VARCHAR(30) NOT NULL DEFAULT 'istek',
  customer_name VARCHAR(100),
  customer_phone VARCHAR(30),
  table_number INTEGER,
  message TEXT NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'bekliyor',
  manager_note TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
