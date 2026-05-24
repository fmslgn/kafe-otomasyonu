// path modülü dosya yollarını güvenli şekilde oluşturmak için kullanılır.
const path = require("path");

// dotenv paketi .env dosyasındaki bilgileri okumak için kullanılır.
// Burada path vererek özellikle backend klasöründeki .env dosyasını okumasını sağlıyoruz.
require("dotenv").config({
  path: path.join(__dirname, ".env"),
});

// pg paketinden Pool sınıfını alıyoruz.
// Pool, PostgreSQL bağlantı havuzu oluşturur.
const { Pool } = require("pg");

// PostgreSQL bağlantı bilgilerini .env dosyasından alıyoruz.
const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

// Bağlantı bilgilerini kontrol etmek için geçici log yazıyoruz.
// Şifreyi güvenlik için ekrana yazdırmıyoruz.
console.log("Veritabanı ayarları:", {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
});

// Veritabanı bağlantısını diğer dosyalarda kullanabilmek için dışa aktarıyoruz.
module.exports = pool;