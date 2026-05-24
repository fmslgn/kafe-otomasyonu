// Express framework'ünü projeye dahil ediyoruz.
const express = require("express");

// PostgreSQL bağlantısı için pg paketini kullanıyoruz.
const { Pool } = require("pg");

// Flutter frontend ile backend arasında istek yapılabilmesi için CORS kullanıyoruz.
const cors = require("cors");

// Ürün görseli yükleme için multer kullanıyoruz.
const multer = require("multer");

// Dosya sistemi ve path işlemleri için kullanıyoruz.
const fs = require("fs");
const path = require("path");

// .env dosyasındaki veritabanı bilgilerini okumak için dotenv kullanıyoruz.
require("dotenv").config();

// Express uygulamasını oluşturuyoruz.
const app = express();

// Backend port değeridir.
const PORT = process.env.PORT || 3000;

// Yüklenen dosyaların saklanacağı ana klasördür.
const uploadsRoot = path.join(__dirname, "uploads");
const productUploadsDir = path.join(uploadsRoot, "products");
const cafeUploadsDir = path.join(uploadsRoot, "cafe");

// Ürün ve kafe logo klasörleri yoksa otomatik oluşturulur.
if (!fs.existsSync(productUploadsDir)) {
  fs.mkdirSync(productUploadsDir, { recursive: true });
}
if (!fs.existsSync(cafeUploadsDir)) {
  fs.mkdirSync(cafeUploadsDir, { recursive: true });
}

// JSON verilerini okuyabilmek için middleware kullanıyoruz.
app.use(express.json());

// CORS izni veriyoruz.
app.use(cors());

// Yüklenen görseller public olarak servis edilir.
// Örnek: http://localhost:3000/uploads/products/product_1_1710000000.jpg
app.use("/uploads", express.static(uploadsRoot));

// Ürün görseli için izin verilen MIME türleri ve uzantılar.
const izinliGorselMimeTurleri = ["image/jpeg", "image/png", "image/webp"];
const izinliGorselUzantilari = [".jpg", ".jpeg", ".png", ".webp"];
const engelliGorselUzantilari = [
  ".exe",
  ".pdf",
  ".js",
  ".html",
  ".htm",
  ".php",
  ".bat",
  ".cmd",
  ".sh",
  ".svg",
  ".msi",
  ".dll",
];

// Ürün görseli yükleme ayarları (multer disk storage).
const urunGorselDepolama = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, productUploadsDir);
  },
  filename: (req, file, cb) => {
    const productId = req.params.productId;
    const uzanti = path.extname(file.originalname || "").toLowerCase();
    const secilenUzantı = izinliGorselUzantilari.includes(uzanti)
      ? uzanti
      : ".jpg";
    cb(null, `product_${productId}_${Date.now()}${secilenUzantı}`);
  },
});

// Kafe logosu yükleme ayarları (multer disk storage).
const kafeLogoDepolama = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, cafeUploadsDir);
  },
  filename: (req, file, cb) => {
    const uzanti = path.extname(file.originalname || "").toLowerCase();
    const secilenUzantı = izinliGorselUzantilari.includes(uzanti)
      ? uzanti
      : ".jpg";
    cb(null, `cafe_logo_${Date.now()}${secilenUzantı}`);
  },
});

const kafeLogoYukle = multer({
  storage: kafeLogoDepolama,
  limits: {
    fileSize: 5 * 1024 * 1024,
  },
  fileFilter: (req, file, cb) => {
    const dosyaUzantisi = path.extname(file.originalname || "").toLowerCase();

    if (engelliGorselUzantilari.includes(dosyaUzantisi)) {
      return cb(
        new Error("Sadece JPEG, PNG veya WEBP görselleri yüklenebilir.")
      );
    }

    const mimeTypeUygun = izinliGorselMimeTurleri.includes(file.mimetype);
    const uzantiUygun = izinliGorselUzantilari.includes(dosyaUzantisi);

    if (mimeTypeUygun || uzantiUygun) {
      cb(null, true);
    } else {
      cb(new Error("Sadece JPEG, PNG veya WEBP görselleri yüklenebilir."));
    }
  },
});

const urunGorselYukle = multer({
  storage: urunGorselDepolama,
  limits: {
    fileSize: 5 * 1024 * 1024,
  },
  fileFilter: (req, file, cb) => {
    const dosyaUzantisi = path.extname(file.originalname || "").toLowerCase();

    // Tehlikeli dosya uzantıları kesinlikle reddedilir.
    if (engelliGorselUzantilari.includes(dosyaUzantisi)) {
      return cb(
        new Error("Sadece JPEG, PNG veya WEBP görselleri yüklenebilir.")
      );
    }

    const mimeTypeUygun = izinliGorselMimeTurleri.includes(file.mimetype);
    const uzantiUygun = izinliGorselUzantilari.includes(dosyaUzantisi);

    // Flutter Web bazen application/octet-stream gönderir; uzantı uygunsa kabul edilir.
    if (mimeTypeUygun || uzantiUygun) {
      cb(null, true);
    } else {
      cb(new Error("Sadece JPEG, PNG veya WEBP görselleri yüklenebilir."));
    }
  },
});

// Sunucuda saklanan ürün görseli dosyasını güvenli şekilde siler.
function sunucuUrunGorseliniSil(imageUrl) {
  if (!imageUrl || typeof imageUrl !== "string") {
    return;
  }

  if (!imageUrl.startsWith("/uploads/products/")) {
    return;
  }

  const dosyaYolu = path.join(uploadsRoot, imageUrl.replace("/uploads/", ""));

  if (fs.existsSync(dosyaYolu)) {
    fs.unlinkSync(dosyaYolu);
  }
}

// Sunucuda saklanan kafe logosu dosyasını güvenli şekilde siler.
function sunucuKafeLogosunuSil(logoUrl) {
  if (!logoUrl || typeof logoUrl !== "string") {
    return;
  }

  if (!logoUrl.startsWith("/uploads/cafe/")) {
    return;
  }

  const dosyaYolu = path.join(uploadsRoot, logoUrl.replace("/uploads/", ""));

  if (fs.existsSync(dosyaYolu)) {
    fs.unlinkSync(dosyaYolu);
  }
}

// PostgreSQL bağlantı havuzu oluşturulur.
const pool = new Pool({
  host: process.env.DB_HOST || "127.0.0.1",
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || "kafe_otomasyonu_db",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
});

// Veritabanı ayarlarını terminalde görmek için yazdırıyoruz.
console.log("Veritabanı ayarları:", {
  host: process.env.DB_HOST || "127.0.0.1",
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || "kafe_otomasyonu_db",
  user: process.env.DB_USER || "postgres",
});

// Ana endpoint.
app.get("/", (req, res) => {
  res.send("Kafe Otomasyonu Backend API çalışıyor.");
});

// Veritabanı bağlantısını test eden endpoint.
app.get("/api/test-db", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW() AS time");

    res.json({
      success: true,
      message: "Veritabanı bağlantısı başarılı.",
      time: result.rows[0].time,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Veritabanı bağlantısı başarısız.",
      error: error.message || String(error),
    });
  }
});

// TIMESTAMP sütunları için dönem filtresi (orders, package_orders created_at).
function getTimestampPeriodFilter(columnRef, period) {
  if (period === "daily") {
    return `AND ${columnRef}::date = CURRENT_DATE`;
  }

  if (period === "weekly") {
    return `AND date_trunc('week', ${columnRef}) = date_trunc('week', CURRENT_DATE)`;
  }

  if (period === "monthly") {
    return `AND date_trunc('month', ${columnRef}) = date_trunc('month', CURRENT_DATE)`;
  }

  return "";
}

// DATE sütunları için dönem filtresi (expense_date, purchase_date).
function getDatePeriodFilter(columnRef, period) {
  if (period === "daily") {
    return `AND ${columnRef} = CURRENT_DATE`;
  }

  if (period === "weekly") {
    return `AND date_trunc('week', ${columnRef}::timestamp) = date_trunc('week', CURRENT_DATE)`;
  }

  if (period === "monthly") {
    return `AND date_trunc('month', ${columnRef}::timestamp) = date_trunc('month', CURRENT_DATE)`;
  }

  return "";
}

// Dönem filtrelerinde orders tablosu için tarih filtresi oluşturur.
function getOrderDateFilter(period) {
  return getTimestampPeriodFilter("orders.created_at", period);
}

// Dönem filtrelerinde package_orders tablosu için tarih filtresi oluşturur.
function getPackageOrderDateFilter(period) {
  return getTimestampPeriodFilter("package_orders.created_at", period);
}

// Dönem filtrelerinde expenses tablosu için tarih filtresi oluşturur.
function getExpenseDateFilter(period) {
  return getDatePeriodFilter("expense_date", period);
}

// Malzeme alım kayıtları için purchase_date dönem filtresi oluşturur.
function getMaterialPurchaseDateFilter(period) {
  return getDatePeriodFilter("purchase_date", period);
}

// Sipariş tablolarında created_at için dönem filtresi (CTE içinde alias ile).
function getTableTimestampPeriodFilter(tableRef, period) {
  if (period === "daily") {
    return `AND ${tableRef}.created_at::date = CURRENT_DATE`;
  }

  if (period === "weekly") {
    return `AND date_trunc('week', ${tableRef}.created_at) = date_trunc('week', CURRENT_DATE)`;
  }

  if (period === "monthly") {
    return `AND date_trunc('month', ${tableRef}.created_at) = date_trunc('month', CURRENT_DATE)`;
  }

  return "";
}

// Kullanıcı giriş endpoint'idir.
// Garson, yönetici ve kurye girişlerini destekler.
app.post("/api/login", async (req, res) => {
  const { username, password } = req.body;

  if (!username || username.trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Kullanıcı adı boş bırakılamaz.",
    });
  }

  if (!password || password.trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Şifre boş bırakılamaz.",
    });
  }

  try {
    const result = await pool.query(
      `
      SELECT
        id,
        full_name,
        username,
        role,
        is_active,
        created_at
      FROM app_users
      WHERE username = $1
        AND password = $2
      LIMIT 1
      `,
      [username.trim(), password.trim()]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: "Kullanıcı adı veya şifre hatalı.",
      });
    }

    const user = result.rows[0];

    if (user.is_active !== true) {
      return res.status(403).json({
        success: false,
        message: "Bu kullanıcı pasif durumdadır. Giriş yapılamaz.",
      });
    }

    res.json({
      success: true,
      message: "Giriş başarılı.",
      user,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Giriş yapılırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Kategorileri listeleyen endpoint.
app.get("/api/categories", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, name
      FROM categories
      ORDER BY id ASC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kategoriler listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yeni kategori ekleyen endpoint.
app.post("/api/categories", async (req, res) => {
  const { name } = req.body;

  if (!name || name.trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Kategori adı boş bırakılamaz.",
    });
  }

  try {
    const existingCategory = await pool.query(
      `
      SELECT id
      FROM categories
      WHERE LOWER(name) = LOWER($1)
      `,
      [name.trim()]
    );

    if (existingCategory.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: "Bu kategori zaten mevcut.",
      });
    }

    const result = await pool.query(
      `
      INSERT INTO categories (name)
      VALUES ($1)
      RETURNING id, name
      `,
      [name.trim()]
    );

    res.status(201).json({
      success: true,
      message: "Kategori başarıyla eklendi.",
      category: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kategori eklenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Ürünleri listeleyen endpoint.
// Yönetici menü yönetiminde açıklama, görsel ve görünürlük bilgilerini de döndürür.
app.get("/api/products", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        products.id,
        products.name,
        products.price,
        products.is_active,
        products.description,
        products.image_url,
        products.is_visible,
        categories.name AS category_name
      FROM products
      INNER JOIN categories ON products.category_id = categories.id
      ORDER BY products.id ASC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      message: "Ürünler listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Müşteri QR menüsü için giriş gerektirmeyen public ürün listesi.
// Sadece aktif ve müşteri menüsünde görünür ürünler döner.
app.get("/api/public-menu", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        products.id,
        products.name,
        products.price,
        categories.name AS category_name,
        products.description,
        products.image_url
      FROM products
      INNER JOIN categories ON products.category_id = categories.id
      WHERE products.is_active = TRUE
        AND products.is_visible = TRUE
      ORDER BY categories.name ASC, products.name ASC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      message: "Public menü listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yeni ürün ekleyen endpoint.
app.post("/api/products", async (req, res) => {
  const {
    name,
    price,
    categoryId,
    description,
    imageUrl,
    isVisible,
  } = req.body;

  if (!name || name.trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Ürün adı boş bırakılamaz.",
    });
  }

  if (!price || Number(price) <= 0) {
    return res.status(400).json({
      success: false,
      message: "Geçerli bir ürün fiyatı girilmelidir.",
    });
  }

  if (!categoryId) {
    return res.status(400).json({
      success: false,
      message: "Kategori seçilmelidir.",
    });
  }

  // Eski istemciler bu alanları göndermese de varsayılan değerler kullanılır.
  const urunAciklamasi =
    description && String(description).trim() !== ""
      ? String(description).trim()
      : null;
  const urunGorselUrl =
    imageUrl && String(imageUrl).trim() !== ""
      ? String(imageUrl).trim()
      : null;
  const musteriMenudeGorunsun =
    isVisible === undefined || isVisible === null ? true : Boolean(isVisible);

  try {
    const result = await pool.query(
      `
      INSERT INTO products (
        name,
        price,
        category_id,
        is_active,
        description,
        image_url,
        is_visible
      )
      VALUES ($1, $2, $3, TRUE, $4, $5, $6)
      RETURNING id, name, price, category_id, is_active, description, image_url, is_visible
      `,
      [
        name.trim(),
        Number(price),
        categoryId,
        urunAciklamasi,
        urunGorselUrl,
        musteriMenudeGorunsun,
      ]
    );

    res.status(201).json({
      success: true,
      message: "Ürün başarıyla eklendi.",
      product: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Ürün eklenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yönetici ürün güncelleme endpoint'i.
app.put("/api/products/:productId", async (req, res) => {
  const { productId } = req.params;
  const {
    name,
    price,
    categoryId,
    description,
    imageUrl,
    isVisible,
    isActive,
  } = req.body;

  if (!name || name.trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Ürün adı boş bırakılamaz.",
    });
  }

  if (!price || Number(price) <= 0) {
    return res.status(400).json({
      success: false,
      message: "Geçerli bir ürün fiyatı girilmelidir.",
    });
  }

  if (!categoryId) {
    return res.status(400).json({
      success: false,
      message: "Kategori seçilmelidir.",
    });
  }

  const urunAciklamasi =
    description && String(description).trim() !== ""
      ? String(description).trim()
      : null;
  const musteriMenudeGorunsun =
    isVisible === undefined || isVisible === null ? true : Boolean(isVisible);
  const urunAktif =
    isActive === undefined || isActive === null ? true : Boolean(isActive);

  // imageUrl gönderilmediyse veya boşsa mevcut görsel korunur.
  const gorselGuncellenecek =
    Object.prototype.hasOwnProperty.call(req.body, "imageUrl") &&
    imageUrl !== null &&
    imageUrl !== undefined &&
    String(imageUrl).trim() !== "";
  const yeniGorselUrl = gorselGuncellenecek ? String(imageUrl).trim() : null;

  try {
    const mevcutUrun = await pool.query(
      "SELECT image_url FROM products WHERE id = $1",
      [productId]
    );

    if (mevcutUrun.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: "Güncellenecek ürün bulunamadı.",
      });
    }

    const korunacakGorselUrl = gorselGuncellenecek
      ? yeniGorselUrl
      : mevcutUrun.rows[0].image_url;

    const result = await pool.query(
      `
      UPDATE products
      SET
        name = $1,
        price = $2,
        category_id = $3,
        description = $4,
        image_url = $5,
        is_visible = $6,
        is_active = $7
      WHERE id = $8
      RETURNING id, name, price, category_id, is_active, description, image_url, is_visible
      `,
      [
        name.trim(),
        Number(price),
        categoryId,
        urunAciklamasi,
        korunacakGorselUrl,
        musteriMenudeGorunsun,
        urunAktif,
        productId,
      ]
    );

    res.json({
      success: true,
      message: "Ürün başarıyla güncellendi.",
      product: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Ürün güncellenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Ürün görseli yükleme endpoint'i (multipart/form-data, field: image).
app.post(
  "/api/products/:productId/image",
  (req, res, next) => {
    urunGorselYukle.single("image")(req, res, (error) => {
      if (error) {
        return res.status(400).json({
          success: false,
          message: error.message || "Görsel yüklenemedi.",
        });
      }
      next();
    });
  },
  async (req, res) => {
    const { productId } = req.params;

    try {
      const mevcutUrun = await pool.query(
        "SELECT id, image_url FROM products WHERE id = $1",
        [productId]
      );

      if (mevcutUrun.rowCount === 0) {
        if (req.file) {
          fs.unlinkSync(req.file.path);
        }

        return res.status(404).json({
          success: false,
          message: "Ürün bulunamadı.",
        });
      }

      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "Görsel dosyası gönderilmedi.",
        });
      }

      const eskiGorselUrl = mevcutUrun.rows[0].image_url;
      const publicGorselYolu = `/uploads/products/${req.file.filename}`;

      // Eski sunucu görseli varsa fiziksel dosyayı siler.
      sunucuUrunGorseliniSil(eskiGorselUrl);

      const result = await pool.query(
        `
        UPDATE products
        SET image_url = $1
        WHERE id = $2
        RETURNING id, name, price, category_id, is_active, description, image_url, is_visible
        `,
        [publicGorselYolu, productId]
      );

      res.json({
        success: true,
        message: "Ürün görseli başarıyla yüklendi.",
        imageUrl: publicGorselYolu,
        product: result.rows[0],
      });
    } catch (error) {
      if (req.file && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }

      res.status(500).json({
        success: false,
        message: "Ürün görseli yüklenirken hata oluştu.",
        error: error.message || String(error),
      });
    }
  }
);

// Ürün görselini kaldıran endpoint.
app.delete("/api/products/:productId/image", async (req, res) => {
  const { productId } = req.params;

  try {
    const mevcutUrun = await pool.query(
      "SELECT id, image_url FROM products WHERE id = $1",
      [productId]
    );

    if (mevcutUrun.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: "Ürün bulunamadı.",
      });
    }

    const eskiGorselUrl = mevcutUrun.rows[0].image_url;
    sunucuUrunGorseliniSil(eskiGorselUrl);

    await pool.query("UPDATE products SET image_url = NULL WHERE id = $1", [
      productId,
    ]);

    res.json({
      success: true,
      message: "Ürün görseli kaldırıldı.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Ürün görseli kaldırılırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Masaları listeleyen endpoint.
app.get("/api/tables", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, table_no, status, section
      FROM cafe_tables
      ORDER BY table_no ASC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      message: "Masalar listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yeni masa ekleme endpoint'i.
app.post("/api/tables", async (req, res) => {
  const { tableNo, section } = req.body;

  if (!tableNo || Number(tableNo) <= 0) {
    return res.status(400).json({
      success: false,
      message: "Geçerli bir masa numarası girilmelidir.",
    });
  }

  try {
    const existingTable = await pool.query(
      `
      SELECT id
      FROM cafe_tables
      WHERE table_no = $1
      `,
      [Number(tableNo)]
    );

    if (existingTable.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: "Bu masa numarası zaten mevcut.",
      });
    }

    const result = await pool.query(
      `
      INSERT INTO cafe_tables (table_no, status, section)
      VALUES ($1, 'bos', $2)
      RETURNING id, table_no, status, section
      `,
      [
        Number(tableNo),
        section && section.trim() !== "" ? section.trim() : "Genel",
      ]
    );

    res.status(201).json({
      success: true,
      message: "Masa başarıyla eklendi.",
      table: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Masa eklenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Masa silme endpoint'i.
app.delete("/api/tables/:tableId", async (req, res) => {
  const tableId = req.params.tableId;

  try {
    const activeOrder = await pool.query(
      `
      SELECT id
      FROM orders
      WHERE table_id = $1
        AND status = 'aktif'
      `,
      [tableId]
    );

    if (activeOrder.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Aktif siparişi olan masa silinemez.",
      });
    }

    const result = await pool.query(
      `
      DELETE FROM cafe_tables
      WHERE id = $1
      RETURNING id, table_no, status, section
      `,
      [tableId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Masa bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Masa başarıyla silindi.",
      table: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Masa silinirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Masa bölümünü/kategorisini güncelleyen endpoint.
app.put("/api/tables/:tableId/section", async (req, res) => {
  const tableId = req.params.tableId;
  const { section } = req.body;

  if (!section || section.trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Masa bölümü boş bırakılamaz.",
    });
  }

  try {
    const result = await pool.query(
      `
      UPDATE cafe_tables
      SET section = $1
      WHERE id = $2
      RETURNING id, table_no, status, section
      `,
      [section.trim(), tableId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Masa bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Masa bölümü başarıyla güncellendi.",
      table: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Masa bölümü güncellenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Seçilen masanın aktif siparişini getiren endpoint.
app.get("/api/orders/active/:tableNo", async (req, res) => {
  const tableNo = req.params.tableNo;

  try {
    const tableResult = await pool.query(
      `
      SELECT id, table_no
      FROM cafe_tables
      WHERE table_no = $1
      `,
      [tableNo]
    );

    if (tableResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Masa bulunamadı.",
      });
    }

    const tableId = tableResult.rows[0].id;

    const orderResult = await pool.query(
      `
      SELECT
        orders.id,
        cafe_tables.table_no,
        orders.total_price,
        orders.status,
        orders.note,
        orders.created_at
      FROM orders
      INNER JOIN cafe_tables ON orders.table_id = cafe_tables.id
      WHERE orders.table_id = $1
        AND orders.status = 'aktif'
      ORDER BY orders.id DESC
      LIMIT 1
      `,
      [tableId]
    );

    if (orderResult.rows.length === 0) {
      return res.json({
        success: true,
        order: null,
      });
    }

    const order = orderResult.rows[0];

    const itemsResult = await pool.query(
      `
      SELECT
        order_items.id,
        order_items.product_id,
        products.name,
        products.price,
        categories.name AS category_name,
        order_items.quantity,
        order_items.unit_price,
        order_items.total_price
      FROM order_items
      INNER JOIN products ON order_items.product_id = products.id
      INNER JOIN categories ON products.category_id = categories.id
      WHERE order_items.order_id = $1
      ORDER BY order_items.id ASC
      `,
      [order.id]
    );

    order.items = itemsResult.rows;

    res.json({
      success: true,
      order,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Aktif sipariş alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Aktif masa siparişlerini listeleyen endpoint.
app.get("/api/orders/active", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        orders.id,
        cafe_tables.table_no,
        app_users.full_name AS waiter_name,
        orders.total_price,
        orders.status,
        orders.note,
        orders.created_at,
        COALESCE(SUM(order_items.quantity), 0)::int AS item_count
      FROM orders
      INNER JOIN cafe_tables ON orders.table_id = cafe_tables.id
      INNER JOIN app_users ON orders.user_id = app_users.id
      LEFT JOIN order_items ON orders.id = order_items.order_id
      WHERE orders.status = 'aktif'
      GROUP BY orders.id, cafe_tables.table_no, app_users.full_name
      ORDER BY cafe_tables.table_no ASC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Aktif siparişler listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Masa siparişi oluşturma veya mevcut aktif siparişi güncelleme endpoint'i.
app.post("/api/orders", async (req, res) => {
  const { tableNo, userId, items, note } = req.body;

  if (!tableNo) {
    return res.status(400).json({
      success: false,
      message: "Masa numarası gönderilmelidir.",
    });
  }

  if (!userId) {
    return res.status(400).json({
      success: false,
      message: "Kullanıcı bilgisi gönderilmelidir.",
    });
  }

  if (!items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({
      success: false,
      message: "Sipariş için en az bir ürün eklenmelidir.",
    });
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const tableResult = await client.query(
      `
      SELECT id
      FROM cafe_tables
      WHERE table_no = $1
      `,
      [tableNo]
    );

    if (tableResult.rows.length === 0) {
      await client.query("ROLLBACK");

      return res.status(404).json({
        success: false,
        message: "Masa bulunamadı.",
      });
    }

    const tableId = tableResult.rows[0].id;

    let totalPrice = 0;
    const preparedItems = [];

    for (const item of items) {
      const productId = item.productId;
      const quantity = Number(item.quantity);

      if (!productId || quantity <= 0) {
        await client.query("ROLLBACK");

        return res.status(400).json({
          success: false,
          message: "Geçersiz ürün veya adet bilgisi gönderildi.",
        });
      }

      const productResult = await client.query(
        `
        SELECT id, price
        FROM products
        WHERE id = $1
          AND is_active = TRUE
        `,
        [productId]
      );

      if (productResult.rows.length === 0) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          success: false,
          message: `Ürün bulunamadı veya pasif durumda. Ürün ID: ${productId}`,
        });
      }

      const unitPrice = Number(productResult.rows[0].price);
      const itemTotalPrice = unitPrice * quantity;

      totalPrice += itemTotalPrice;

      preparedItems.push({
        productId,
        quantity,
        unitPrice,
        totalPrice: itemTotalPrice,
      });
    }

    const activeOrderResult = await client.query(
      `
      SELECT id
      FROM orders
      WHERE table_id = $1
        AND status = 'aktif'
      ORDER BY id DESC
      LIMIT 1
      `,
      [tableId]
    );

    let orderId;

    if (activeOrderResult.rows.length > 0) {
      orderId = activeOrderResult.rows[0].id;

      await client.query(
        `
        UPDATE orders
        SET user_id = $1,
            total_price = $2,
            note = $3
        WHERE id = $4
        `,
        [userId, totalPrice, note || null, orderId]
      );

      await client.query(
        `
        DELETE FROM order_items
        WHERE order_id = $1
        `,
        [orderId]
      );
    } else {
      const orderResult = await client.query(
        `
        INSERT INTO orders (table_id, user_id, total_price, status, note)
        VALUES ($1, $2, $3, 'aktif', $4)
        RETURNING id
        `,
        [tableId, userId, totalPrice, note || null]
      );

      orderId = orderResult.rows[0].id;
    }

    for (const item of preparedItems) {
      await client.query(
        `
        INSERT INTO order_items
        (order_id, product_id, quantity, unit_price, total_price)
        VALUES ($1, $2, $3, $4, $5)
        `,
        [
          orderId,
          item.productId,
          item.quantity,
          item.unitPrice,
          item.totalPrice,
        ]
      );
    }

    await client.query(
      `
      UPDATE cafe_tables
      SET status = 'dolu'
      WHERE id = $1
      `,
      [tableId]
    );

    await client.query("COMMIT");

    res.status(201).json({
      success: true,
      message: "Sipariş başarıyla kaydedildi.",
      orderId,
      totalPrice: totalPrice.toFixed(2),
    });
  } catch (error) {
    await client.query("ROLLBACK");

    res.status(500).json({
      success: false,
      message: "Sipariş kaydedilirken hata oluştu.",
      error: error.message || String(error),
    });
  } finally {
    client.release();
  }
});

// Siparişi kapatan endpoint.
app.put("/api/orders/:orderId/close", async (req, res) => {
  const orderId = req.params.orderId;

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const orderResult = await client.query(
      `
      SELECT id, table_id, status
      FROM orders
      WHERE id = $1
      `,
      [orderId]
    );

    if (orderResult.rows.length === 0) {
      await client.query("ROLLBACK");

      return res.status(404).json({
        success: false,
        message: "Sipariş bulunamadı.",
      });
    }

    const order = orderResult.rows[0];

    if (order.status === "kapandi") {
      await client.query("ROLLBACK");

      return res.status(400).json({
        success: false,
        message: "Bu hesap zaten kapatılmış.",
      });
    }

    await client.query(
      `
      UPDATE orders
      SET status = 'kapandi'
      WHERE id = $1
      `,
      [orderId]
    );

    await client.query(
      `
      UPDATE cafe_tables
      SET status = 'bos'
      WHERE id = $1
      `,
      [order.table_id]
    );

    await client.query("COMMIT");

    res.json({
      success: true,
      message: "Hesap başarıyla kapatıldı.",
    });
  } catch (error) {
    await client.query("ROLLBACK");

    res.status(500).json({
      success: false,
      message: "Hesap kapatılırken hata oluştu.",
      error: error.message || String(error),
    });
  } finally {
    client.release();
  }
});

// Alternatif hesap kapatma endpoint'i.
app.put("/api/orders/close/:orderId", async (req, res) => {
  const orderId = req.params.orderId;

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const orderResult = await client.query(
      `
      SELECT id, table_id, status
      FROM orders
      WHERE id = $1
      `,
      [orderId]
    );

    if (orderResult.rows.length === 0) {
      await client.query("ROLLBACK");

      return res.status(404).json({
        success: false,
        message: "Sipariş bulunamadı.",
      });
    }

    const order = orderResult.rows[0];

    if (order.status === "kapandi") {
      await client.query("ROLLBACK");

      return res.status(400).json({
        success: false,
        message: "Bu hesap zaten kapatılmış.",
      });
    }

    await client.query(
      `
      UPDATE orders
      SET status = 'kapandi'
      WHERE id = $1
      `,
      [orderId]
    );

    await client.query(
      `
      UPDATE cafe_tables
      SET status = 'bos'
      WHERE id = $1
      `,
      [order.table_id]
    );

    await client.query("COMMIT");

    res.json({
      success: true,
      message: "Hesap başarıyla kapatıldı.",
    });
  } catch (error) {
    await client.query("ROLLBACK");

    res.status(500).json({
      success: false,
      message: "Hesap kapatılırken hata oluştu.",
      error: error.message || String(error),
    });
  } finally {
    client.release();
  }
});

// Aktif kurye kullanıcılarını listeleyen endpoint.
// Yönetici paket siparişe kurye atarken kullanır.
app.get("/api/couriers", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        id,
        full_name,
        username,
        role,
        is_active,
        created_at
      FROM app_users
      WHERE role = 'kurye'
        AND is_active = TRUE
      ORDER BY full_name ASC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kuryeler listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Aktif paket siparişleri listeleyen endpoint.
app.get("/api/package-orders/active", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        package_orders.id,
        package_orders.customer_name,
        package_orders.customer_phone,
        package_orders.address,
        package_orders.note,
        package_orders.total_price,
        package_orders.status,
        package_orders.delivery_status,
        package_orders.courier_id,
        package_orders.created_at,
        app_users.full_name AS waiter_name,
        couriers.full_name AS courier_name,
        COALESCE(SUM(package_order_items.quantity), 0)::int AS item_count
      FROM package_orders
      INNER JOIN app_users ON package_orders.user_id = app_users.id
      LEFT JOIN app_users AS couriers ON package_orders.courier_id = couriers.id
      LEFT JOIN package_order_items
        ON package_orders.id = package_order_items.package_order_id
      WHERE package_orders.status = 'aktif'
      GROUP BY package_orders.id, app_users.full_name, couriers.full_name
      ORDER BY package_orders.created_at DESC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Aktif paket siparişler listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Tüm paket siparişleri listeleyen endpoint.
app.get("/api/package-orders", async (req, res) => {
  const status = req.query.status || "all";

  const allowedStatuses = ["all", "aktif", "kapandi", "iptal"];

  if (!allowedStatuses.includes(status)) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz paket sipariş durumu.",
    });
  }

  let statusFilter = "";

  if (status !== "all") {
    statusFilter = `WHERE package_orders.status = '${status}'`;
  }

  try {
    const result = await pool.query(`
      SELECT
        package_orders.id,
        package_orders.customer_name,
        package_orders.customer_phone,
        package_orders.address,
        package_orders.note,
        package_orders.total_price,
        package_orders.status,
        package_orders.delivery_status,
        package_orders.courier_id,
        package_orders.created_at,
        app_users.full_name AS waiter_name,
        couriers.full_name AS courier_name,
        COALESCE(SUM(package_order_items.quantity), 0)::int AS item_count
      FROM package_orders
      INNER JOIN app_users ON package_orders.user_id = app_users.id
      LEFT JOIN app_users AS couriers ON package_orders.courier_id = couriers.id
      LEFT JOIN package_order_items
        ON package_orders.id = package_order_items.package_order_id
      ${statusFilter}
      GROUP BY package_orders.id, app_users.full_name, couriers.full_name
      ORDER BY package_orders.created_at DESC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Paket siparişler listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Kurye kendisine atanmış aktif paketleri görür.
app.get("/api/couriers/:courierId/package-orders", async (req, res) => {
  const courierId = req.params.courierId;

  try {
    const result = await pool.query(
      `
      SELECT
        package_orders.id,
        package_orders.customer_name,
        package_orders.customer_phone,
        package_orders.address,
        package_orders.note,
        package_orders.total_price,
        package_orders.status,
        package_orders.delivery_status,
        package_orders.courier_id,
        package_orders.created_at,
        app_users.full_name AS waiter_name,
        couriers.full_name AS courier_name,
        COALESCE(SUM(package_order_items.quantity), 0)::int AS item_count
      FROM package_orders
      INNER JOIN app_users ON package_orders.user_id = app_users.id
      LEFT JOIN app_users AS couriers ON package_orders.courier_id = couriers.id
      LEFT JOIN package_order_items
        ON package_orders.id = package_order_items.package_order_id
      WHERE package_orders.courier_id = $1
        AND package_orders.status = 'aktif'
      GROUP BY package_orders.id, app_users.full_name, couriers.full_name
      ORDER BY package_orders.created_at DESC
      `,
      [courierId]
    );

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kurye paketleri listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Paket sipariş detayını getiren endpoint.
app.get("/api/package-orders/:packageOrderId", async (req, res) => {
  const packageOrderId = req.params.packageOrderId;

  try {
    const orderResult = await pool.query(
      `
      SELECT
        package_orders.id,
        package_orders.customer_name,
        package_orders.customer_phone,
        package_orders.address,
        package_orders.note,
        package_orders.total_price,
        package_orders.status,
        package_orders.delivery_status,
        package_orders.courier_id,
        package_orders.created_at,
        app_users.full_name AS waiter_name,
        couriers.full_name AS courier_name
      FROM package_orders
      INNER JOIN app_users ON package_orders.user_id = app_users.id
      LEFT JOIN app_users AS couriers ON package_orders.courier_id = couriers.id
      WHERE package_orders.id = $1
      `,
      [packageOrderId]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Paket sipariş bulunamadı.",
      });
    }

    const packageOrder = orderResult.rows[0];

    const itemsResult = await pool.query(
      `
      SELECT
        package_order_items.id,
        package_order_items.product_id,
        products.name,
        products.price,
        categories.name AS category_name,
        package_order_items.quantity,
        package_order_items.unit_price,
        package_order_items.total_price
      FROM package_order_items
      INNER JOIN products ON package_order_items.product_id = products.id
      INNER JOIN categories ON products.category_id = categories.id
      WHERE package_order_items.package_order_id = $1
      ORDER BY package_order_items.id ASC
      `,
      [packageOrderId]
    );

    packageOrder.items = itemsResult.rows;

    res.json({
      success: true,
      packageOrder,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Paket sipariş detayı alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yeni paket sipariş oluşturan endpoint.
app.post("/api/package-orders", async (req, res) => {
  const { userId, customerName, customerPhone, address, note, items } = req.body;

  if (!userId) {
    return res.status(400).json({
      success: false,
      message: "Kullanıcı bilgisi gönderilmelidir.",
    });
  }

  if (!items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({
      success: false,
      message: "Paket sipariş için en az bir ürün eklenmelidir.",
    });
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    let totalPrice = 0;
    const preparedItems = [];

    for (const item of items) {
      const productId = item.productId;
      const quantity = Number(item.quantity);

      if (!productId || quantity <= 0) {
        await client.query("ROLLBACK");

        return res.status(400).json({
          success: false,
          message: "Geçersiz ürün veya adet bilgisi gönderildi.",
        });
      }

      const productResult = await client.query(
        `
        SELECT id, price
        FROM products
        WHERE id = $1
          AND is_active = TRUE
        `,
        [productId]
      );

      if (productResult.rows.length === 0) {
        await client.query("ROLLBACK");

        return res.status(404).json({
          success: false,
          message: `Ürün bulunamadı veya pasif durumda. Ürün ID: ${productId}`,
        });
      }

      const unitPrice = Number(productResult.rows[0].price);
      const itemTotalPrice = unitPrice * quantity;

      totalPrice += itemTotalPrice;

      preparedItems.push({
        productId,
        quantity,
        unitPrice,
        totalPrice: itemTotalPrice,
      });
    }

    const orderResult = await client.query(
      `
      INSERT INTO package_orders
      (
        user_id,
        customer_name,
        customer_phone,
        address,
        note,
        total_price,
        status,
        delivery_status
      )
      VALUES ($1, $2, $3, $4, $5, $6, 'aktif', 'bekliyor')
      RETURNING id
      `,
      [
        userId,
        customerName && customerName.trim() !== ""
          ? customerName.trim()
          : null,
        customerPhone && customerPhone.trim() !== ""
          ? customerPhone.trim()
          : null,
        address && address.trim() !== "" ? address.trim() : null,
        note && note.trim() !== "" ? note.trim() : null,
        totalPrice,
      ]
    );

    const packageOrderId = orderResult.rows[0].id;

    for (const item of preparedItems) {
      await client.query(
        `
        INSERT INTO package_order_items
        (
          package_order_id,
          product_id,
          quantity,
          unit_price,
          total_price
        )
        VALUES ($1, $2, $3, $4, $5)
        `,
        [
          packageOrderId,
          item.productId,
          item.quantity,
          item.unitPrice,
          item.totalPrice,
        ]
      );
    }

    await client.query("COMMIT");

    res.status(201).json({
      success: true,
      message: "Paket sipariş başarıyla kaydedildi.",
      packageOrderId,
      totalPrice: totalPrice.toFixed(2),
    });
  } catch (error) {
    await client.query("ROLLBACK");

    res.status(500).json({
      success: false,
      message: "Paket sipariş kaydedilirken hata oluştu.",
      error: error.message || String(error),
    });
  } finally {
    client.release();
  }
});

// Paket siparişe kurye atayan endpoint.
app.put("/api/package-orders/:packageOrderId/assign-courier", async (req, res) => {
  const packageOrderId = req.params.packageOrderId;
  const { courierId } = req.body;

  if (!courierId) {
    return res.status(400).json({
      success: false,
      message: "Kurye seçilmelidir.",
    });
  }

  try {
    const courierResult = await pool.query(
      `
      SELECT id
      FROM app_users
      WHERE id = $1
        AND role = 'kurye'
        AND is_active = TRUE
      `,
      [courierId]
    );

    if (courierResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Aktif kurye bulunamadı.",
      });
    }

    const result = await pool.query(
      `
      UPDATE package_orders
      SET courier_id = $1,
          delivery_status = 'kuryeye_atandi'
      WHERE id = $2
        AND status = 'aktif'
      RETURNING id
      `,
      [courierId, packageOrderId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Aktif paket sipariş bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Paket sipariş kuryeye atandı.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kurye ataması yapılırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Paket siparişin teslimat durumunu güncelleyen endpoint.
// Kurye bu endpoint ile siparişi yolda veya teslim edildi yapar.
app.put("/api/package-orders/:packageOrderId/delivery-status", async (req, res) => {
  const packageOrderId = req.params.packageOrderId;
  const { deliveryStatus } = req.body;

  const allowedDeliveryStatuses = [
    "bekliyor",
    "kuryeye_atandi",
    "yolda",
    "teslim_edildi",
    "iptal",
  ];

  if (!allowedDeliveryStatuses.includes(deliveryStatus)) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz teslimat durumu.",
    });
  }

  try {
    let result;

    if (deliveryStatus === "teslim_edildi") {
      result = await pool.query(
        `
        UPDATE package_orders
        SET delivery_status = $1,
            status = 'kapandi'
        WHERE id = $2
          AND status = 'aktif'
        RETURNING id
        `,
        [deliveryStatus, packageOrderId]
      );
    } else if (deliveryStatus === "iptal") {
      result = await pool.query(
        `
        UPDATE package_orders
        SET delivery_status = $1,
            status = 'iptal'
        WHERE id = $2
          AND status = 'aktif'
        RETURNING id
        `,
        [deliveryStatus, packageOrderId]
      );
    } else {
      result = await pool.query(
        `
        UPDATE package_orders
        SET delivery_status = $1
        WHERE id = $2
          AND status = 'aktif'
        RETURNING id
        `,
        [deliveryStatus, packageOrderId]
      );
    }

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Aktif paket sipariş bulunamadı.",
      });
    }

    res.json({
      success: true,
      message:
        deliveryStatus === "teslim_edildi"
          ? "Paket sipariş teslim edildi ve kapatıldı."
          : "Paket sipariş teslimat durumu güncellendi.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Teslimat durumu güncellenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Paket siparişi tamamlayan endpoint.
app.put("/api/package-orders/:packageOrderId/close", async (req, res) => {
  const packageOrderId = req.params.packageOrderId;

  try {
    const result = await pool.query(
      `
      UPDATE package_orders
      SET status = 'kapandi',
          delivery_status = 'teslim_edildi'
      WHERE id = $1
        AND status = 'aktif'
      RETURNING id
      `,
      [packageOrderId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Aktif paket sipariş bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Paket sipariş başarıyla tamamlandı.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Paket sipariş tamamlanırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Paket siparişi iptal eden endpoint.
app.put("/api/package-orders/:packageOrderId/cancel", async (req, res) => {
  const packageOrderId = req.params.packageOrderId;

  try {
    const result = await pool.query(
      `
      UPDATE package_orders
      SET status = 'iptal',
          delivery_status = 'iptal'
      WHERE id = $1
        AND status = 'aktif'
      RETURNING id
      `,
      [packageOrderId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Aktif paket sipariş bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Paket sipariş iptal edildi.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Paket sipariş iptal edilirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Gelir-gider özetini getiren endpoint.
// Toplam gelir = kapanan masa siparişleri + kapanan paket siparişleri.
app.get("/api/finance/summary", async (req, res) => {
  const period = req.query.period || "all";

  const orderDateFilter = getOrderDateFilter(period);
  const packageOrderDateFilter = getPackageOrderDateFilter(period);
  const expenseDateFilter = getExpenseDateFilter(period);
  const materialDateFilter = getMaterialPurchaseDateFilter(period);

  try {
    const masaGelirResult = await pool.query(`
      SELECT COALESCE(SUM(total_price), 0) AS total_income
      FROM orders
      WHERE status = 'kapandi'
      ${orderDateFilter}
    `);

    const paketGelirResult = await pool.query(`
      SELECT COALESCE(SUM(total_price), 0) AS total_income
      FROM package_orders
      WHERE status = 'kapandi'
      ${packageOrderDateFilter}
    `);

    const giderResult = await pool.query(`
      SELECT COALESCE(SUM(amount), 0) AS total_expense
      FROM expenses
      WHERE 1 = 1
      ${expenseDateFilter}
    `);

    const malzemeGiderResult = await pool.query(`
      SELECT COALESCE(SUM(total_price), 0) AS total_expense
      FROM material_purchases
      WHERE 1 = 1
      ${materialDateFilter}
    `);

    const masaIncome = Number(masaGelirResult.rows[0].total_income);
    const paketIncome = Number(paketGelirResult.rows[0].total_income);
    const totalIncome = masaIncome + paketIncome;
    const normalExpense = Number(giderResult.rows[0].total_expense);
    const materialExpense = Number(malzemeGiderResult.rows[0].total_expense);
    const totalExpense = normalExpense + materialExpense;
    const netProfit = totalIncome - totalExpense;

    res.json({
      totalIncome,
      totalExpense,
      netProfit,
      period,
      tableIncome: masaIncome,
      packageIncome: paketIncome,
      normalExpense,
      materialExpense,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Gelir-gider özeti alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Genel giderler + malzeme alımlarını birleşik listeleyen endpoint (Gelir-Gider ekranı).
app.get("/api/finance/expense-records", async (req, res) => {
  const period = req.query.period || "all";
  const expenseDateFilter = getExpenseDateFilter(period);
  const materialDateFilter = getMaterialPurchaseDateFilter(period);

  try {
    const result = await pool.query(`
      SELECT *
      FROM (
        SELECT
          id,
          'normal'::text AS type,
          title,
          amount,
          description,
          expense_date AS record_date,
          created_at,
          NULL::numeric AS quantity,
          NULL::text AS unit,
          NULL::numeric AS unit_price
        FROM expenses
        WHERE 1 = 1
        ${expenseDateFilter}

        UNION ALL

        SELECT
          id,
          'material'::text AS type,
          item_name AS title,
          total_price AS amount,
          description,
          purchase_date AS record_date,
          created_at,
          quantity,
          unit,
          unit_price
        FROM material_purchases
        WHERE 1 = 1
        ${materialDateFilter}
      ) AS combined_records
      ORDER BY record_date DESC, created_at DESC, id DESC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Gider kayıtları listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Gider kayıtlarını listeleyen endpoint.
app.get("/api/expenses", async (req, res) => {
  const period = req.query.period || "all";

  const expenseDateFilter = getExpenseDateFilter(period);

  try {
    const result = await pool.query(`
      SELECT
        id,
        title,
        amount,
        description,
        expense_date,
        created_at
      FROM expenses
      WHERE 1 = 1
      ${expenseDateFilter}
      ORDER BY expense_date DESC, id DESC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Giderler listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yeni gider ekleyen endpoint.
app.post("/api/expenses", async (req, res) => {
  const { title, amount, description } = req.body;

  if (!title || title.trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Gider başlığı boş bırakılamaz.",
    });
  }

  if (!amount || Number(amount) <= 0) {
    return res.status(400).json({
      success: false,
      message: "Geçerli bir gider tutarı girilmelidir.",
    });
  }

  try {
    const result = await pool.query(
      `
      INSERT INTO expenses (title, amount, description)
      VALUES ($1, $2, $3)
      RETURNING id, title, amount, expense_date, description, created_at
      `,
      [title.trim(), Number(amount), description || null]
    );

    res.status(201).json({
      success: true,
      message: "Gider başarıyla eklendi.",
      expense: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Gider eklenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Malzeme alım kayıtlarını listeleyen endpoint.
app.get("/api/material-purchases", async (req, res) => {
  const period = req.query.period || "all";
  const materialDateFilter = getMaterialPurchaseDateFilter(period);

  try {
    const result = await pool.query(`
      SELECT
        id,
        item_name,
        quantity,
        unit,
        unit_price,
        total_price,
        description,
        purchase_date,
        created_at
      FROM material_purchases
      WHERE 1 = 1
      ${materialDateFilter}
      ORDER BY purchase_date DESC, id DESC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Malzeme alım kayıtları listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yeni malzeme alım kaydı ekleyen endpoint.
app.post("/api/material-purchases", async (req, res) => {
  const {
    itemName,
    quantity,
    unit,
    unitPrice,
    description,
    purchaseDate,
  } = req.body;

  if (!itemName || itemName.trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Malzeme adı boş bırakılamaz.",
    });
  }

  const miktar = Number(quantity);
  if (!quantity || Number.isNaN(miktar) || miktar <= 0) {
    return res.status(400).json({
      success: false,
      message: "Miktar 0'dan büyük olmalıdır.",
    });
  }

  const birimFiyat = Number(unitPrice);
  if (unitPrice === undefined || unitPrice === null || Number.isNaN(birimFiyat) || birimFiyat < 0) {
    return res.status(400).json({
      success: false,
      message: "Birim fiyat negatif olamaz.",
    });
  }

  const birim = unit && unit.trim() !== "" ? unit.trim() : "adet";
  const toplamFiyat = miktar * birimFiyat;
  const alimTarihi =
    purchaseDate && purchaseDate.trim() !== ""
      ? purchaseDate.trim()
      : null;

  try {
    const result = await pool.query(
      `
      INSERT INTO material_purchases (
        item_name,
        quantity,
        unit,
        unit_price,
        total_price,
        description,
        purchase_date
      )
      VALUES ($1, $2, $3, $4, $5, $6, COALESCE($7::date, CURRENT_DATE))
      RETURNING
        id,
        item_name,
        quantity,
        unit,
        unit_price,
        total_price,
        description,
        purchase_date,
        created_at
      `,
      [
        itemName.trim(),
        miktar,
        birim,
        birimFiyat,
        toplamFiyat,
        description || null,
        alimTarihi,
      ]
    );

    res.status(201).json({
      success: true,
      message: "Malzeme alım kaydı başarıyla eklendi.",
      purchase: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Malzeme alım kaydı eklenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Malzeme alım kaydını silen endpoint.
app.delete("/api/material-purchases/:id", async (req, res) => {
  const purchaseId = Number(req.params.id);

  if (!purchaseId || Number.isNaN(purchaseId)) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz kayıt numarası.",
    });
  }

  try {
    const result = await pool.query(
      `
      DELETE FROM material_purchases
      WHERE id = $1
      RETURNING id
      `,
      [purchaseId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Malzeme alım kaydı bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Malzeme alım kaydı silindi.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Malzeme alım kaydı silinirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Rapor özetini getiren endpoint.
// Toplam satış = kapanan masa siparişleri + kapanan paket siparişleri.
app.get("/api/reports/summary", async (req, res) => {
  const period = req.query.period || "all";

  const orderDateFilter = getOrderDateFilter(period);
  const packageOrderDateFilter = getPackageOrderDateFilter(period);

  try {
    const masaSalesResult = await pool.query(`
      SELECT
        COALESCE(SUM(total_price), 0) AS total_sales,
        COUNT(*)::int AS closed_order_count,
        COALESCE(AVG(total_price), 0) AS average_order_amount
      FROM orders
      WHERE status = 'kapandi'
      ${orderDateFilter}
    `);

    const paketSalesResult = await pool.query(`
      SELECT
        COALESCE(SUM(total_price), 0) AS total_sales,
        COUNT(*)::int AS closed_order_count,
        COALESCE(AVG(total_price), 0) AS average_order_amount
      FROM package_orders
      WHERE status = 'kapandi'
      ${packageOrderDateFilter}
    `);

    const masaItemResult = await pool.query(`
      SELECT
        COALESCE(SUM(order_items.quantity), 0)::int AS total_items_sold
      FROM order_items
      INNER JOIN orders ON order_items.order_id = orders.id
      WHERE orders.status = 'kapandi'
      ${orderDateFilter}
    `);

    const paketItemResult = await pool.query(`
      SELECT
        COALESCE(SUM(package_order_items.quantity), 0)::int AS total_items_sold
      FROM package_order_items
      INNER JOIN package_orders
        ON package_order_items.package_order_id = package_orders.id
      WHERE package_orders.status = 'kapandi'
      ${packageOrderDateFilter}
    `);

    const masaSales = Number(masaSalesResult.rows[0].total_sales);
    const paketSales = Number(paketSalesResult.rows[0].total_sales);
    const totalSales = masaSales + paketSales;

    const masaCount = Number(masaSalesResult.rows[0].closed_order_count);
    const paketCount = Number(paketSalesResult.rows[0].closed_order_count);
    const closedOrderCount = masaCount + paketCount;

    const averageOrderAmount =
      closedOrderCount > 0 ? totalSales / closedOrderCount : 0;

    const totalItemsSold =
      Number(masaItemResult.rows[0].total_items_sold) +
      Number(paketItemResult.rows[0].total_items_sold);

    res.json({
      period,
      totalSales,
      closedOrderCount,
      averageOrderAmount,
      totalItemsSold,
      tableSales: masaSales,
      packageSales: paketSales,
      tableOrderCount: masaCount,
      packageOrderCount: paketCount,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Rapor özeti alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// En çok satılan ürünleri getiren endpoint.
// Masa siparişleri ve paket siparişleri birlikte hesaplanır.
app.get("/api/reports/top-products", async (req, res) => {
  const period = req.query.period || "all";

  const orderDateFilter = getOrderDateFilter(period);
  const packageOrderDateFilter = getPackageOrderDateFilter(period);

  try {
    const result = await pool.query(`
      SELECT
        product_id,
        product_name,
        category_name,
        SUM(total_quantity)::int AS total_quantity,
        SUM(total_revenue) AS total_revenue
      FROM (
        SELECT
          products.id AS product_id,
          products.name AS product_name,
          categories.name AS category_name,
          COALESCE(SUM(order_items.quantity), 0)::int AS total_quantity,
          COALESCE(SUM(order_items.total_price), 0) AS total_revenue
        FROM order_items
        INNER JOIN orders ON order_items.order_id = orders.id
        INNER JOIN products ON order_items.product_id = products.id
        INNER JOIN categories ON products.category_id = categories.id
        WHERE orders.status = 'kapandi'
        ${orderDateFilter}
        GROUP BY products.id, products.name, categories.name

        UNION ALL

        SELECT
          products.id AS product_id,
          products.name AS product_name,
          categories.name AS category_name,
          COALESCE(SUM(package_order_items.quantity), 0)::int AS total_quantity,
          COALESCE(SUM(package_order_items.total_price), 0) AS total_revenue
        FROM package_order_items
        INNER JOIN package_orders
          ON package_order_items.package_order_id = package_orders.id
        INNER JOIN products ON package_order_items.product_id = products.id
        INNER JOIN categories ON products.category_id = categories.id
        WHERE package_orders.status = 'kapandi'
        ${packageOrderDateFilter}
        GROUP BY products.id, products.name, categories.name
      ) AS combined_products
      GROUP BY product_id, product_name, category_name
      ORDER BY total_quantity DESC, total_revenue DESC
      LIMIT 10
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "En çok satılan ürünler alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Kapanan masa hesaplarını listeleyen endpoint.
app.get("/api/reports/closed-orders", async (req, res) => {
  const period = req.query.period || "all";
  const orderDateFilter = getOrderDateFilter(period);

  try {
    const result = await pool.query(`
      SELECT
        orders.id,
        cafe_tables.table_no,
        orders.total_price,
        orders.status,
        orders.note,
        orders.created_at,
        COALESCE(SUM(order_items.quantity), 0)::int AS item_count
      FROM orders
      INNER JOIN cafe_tables ON orders.table_id = cafe_tables.id
      LEFT JOIN order_items ON orders.id = order_items.order_id
      WHERE orders.status = 'kapandi'
      ${orderDateFilter}
      GROUP BY orders.id, cafe_tables.table_no
      ORDER BY orders.created_at DESC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kapanan hesaplar alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Kullanıcıları listeleyen endpoint.
app.get("/api/users", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        id,
        full_name,
        username,
        password,
        role,
        is_active,
        created_at
      FROM app_users
      ORDER BY id ASC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kullanıcılar listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yeni kullanıcı ekleyen endpoint.
// Garson, yönetici ve kurye eklemeyi destekler.
app.post("/api/users", async (req, res) => {
  const { fullName, username, password, role } = req.body;

  if (!fullName || fullName.trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Ad soyad boş bırakılamaz.",
    });
  }

  if (!username || username.trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Kullanıcı adı boş bırakılamaz.",
    });
  }

  if (!password || password.trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Şifre boş bırakılamaz.",
    });
  }

  if (!role || !["garson", "yonetici", "kurye"].includes(role)) {
    return res.status(400).json({
      success: false,
      message: "Geçerli bir rol seçilmelidir.",
    });
  }

  try {
    const existingUser = await pool.query(
      `
      SELECT id
      FROM app_users
      WHERE username = $1
      `,
      [username.trim()]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: "Bu kullanıcı adı zaten kullanılıyor.",
      });
    }

    const result = await pool.query(
      `
      INSERT INTO app_users
      (full_name, username, password, role, is_active)
      VALUES ($1, $2, $3, $4, TRUE)
      RETURNING id, full_name, username, role, is_active, created_at
      `,
      [fullName.trim(), username.trim(), password.trim(), role]
    );

    res.status(201).json({
      success: true,
      message: "Kullanıcı başarıyla eklendi.",
      user: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kullanıcı eklenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Kullanıcı aktif/pasif durumunu güncelleyen endpoint.
app.put("/api/users/:userId/status", async (req, res) => {
  const userId = req.params.userId;
  const { isActive } = req.body;

  if (typeof isActive !== "boolean") {
    return res.status(400).json({
      success: false,
      message: "isActive değeri true veya false olmalıdır.",
    });
  }

  try {
    const result = await pool.query(
      `
      UPDATE app_users
      SET is_active = $1
      WHERE id = $2
      RETURNING id, full_name, username, role, is_active, created_at
      `,
      [isActive, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Kullanıcı bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: isActive
        ? "Kullanıcı aktif hale getirildi."
        : "Kullanıcı pasif hale getirildi.",
      user: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kullanıcı durumu güncellenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Kullanıcının rolünü güncelleyen endpoint.
app.put("/api/users/:userId/role", async (req, res) => {
  const userId = req.params.userId;
  const { role } = req.body;

  if (!role || !["garson", "yonetici", "kurye"].includes(role)) {
    return res.status(400).json({
      success: false,
      message: "Geçerli bir rol seçilmelidir.",
    });
  }

  try {
    const result = await pool.query(
      `
      UPDATE app_users
      SET role = $1
      WHERE id = $2
      RETURNING id, full_name, username, role, is_active, created_at
      `,
      [role, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Kullanıcı bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Kullanıcı rolü başarıyla güncellendi.",
      user: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kullanıcı rolü güncellenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Kullanıcı şifresini değiştiren endpoint.
// Giriş endpoint'i ile aynı password alanı güncellenir (plain text).
app.put("/api/users/:userId/password", async (req, res) => {
  const userId = Number.parseInt(req.params.userId, 10);
  // Frontend password veya newPassword gönderebilir.
  const hamSifre = req.body.password ?? req.body.newPassword;

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz kullanıcı kimliği.",
    });
  }

  if (!hamSifre || String(hamSifre).trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Yeni şifre boş bırakılamaz.",
    });
  }

  const yeniSifre = String(hamSifre).trim();

  if (yeniSifre.length < 3) {
    return res.status(400).json({
      success: false,
      message: "Şifre en az 3 karakter olmalıdır.",
    });
  }

  try {
    const result = await pool.query(
      `
      UPDATE app_users
      SET password = $1
      WHERE id = $2
      RETURNING id, full_name, username, password, role, is_active
      `,
      [yeniSifre, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Kullanıcı bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Kullanıcı şifresi başarıyla güncellendi.",
      user: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Şifre güncellenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Kullanıcının kendi şifresini değiştiren endpoint (mevcut şifre doğrulaması ile).
app.put("/api/users/:userId/change-own-password", async (req, res) => {
  const userId = Number.parseInt(req.params.userId, 10);
  const { currentPassword, newPassword } = req.body;

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz kullanıcı kimliği.",
    });
  }

  if (!currentPassword || String(currentPassword).trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Mevcut şifre boş bırakılamaz.",
    });
  }

  if (!newPassword || String(newPassword).trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Yeni şifre boş bırakılamaz.",
    });
  }

  const mevcutSifre = String(currentPassword).trim();
  const yeniSifre = String(newPassword).trim();

  if (yeniSifre.length < 3) {
    return res.status(400).json({
      success: false,
      message: "Şifre en az 3 karakter olmalıdır.",
    });
  }

  try {
    const kullanici = await pool.query(
      `
      SELECT id, password
      FROM app_users
      WHERE id = $1
      LIMIT 1
      `,
      [userId]
    );

    if (kullanici.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Kullanıcı bulunamadı.",
      });
    }

    if (kullanici.rows[0].password !== mevcutSifre) {
      return res.status(400).json({
        success: false,
        message: "Mevcut şifre hatalı.",
      });
    }

    await pool.query(
      `
      UPDATE app_users
      SET password = $1
      WHERE id = $2
      `,
      [yeniSifre, userId]
    );

    res.json({
      success: true,
      message: "Şifreniz başarıyla güncellendi.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Şifre güncellenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Garson satış raporu endpoint'i.
// Masa siparişleri + paket siparişleri birlikte hesaplanır.
app.get("/api/users/sales-report", async (req, res) => {
  const period = req.query.period || "all";

  const orderDateFilter = getOrderDateFilter(period);
  const packageOrderDateFilter = getPackageOrderDateFilter(period);

  try {
    const result = await pool.query(`
      SELECT
        app_users.id AS user_id,
        app_users.full_name,
        app_users.username,
        app_users.role,
        (
          COALESCE(masa_satis.closed_order_count, 0)
          +
          COALESCE(paket_satis.closed_order_count, 0)
        )::int AS closed_order_count,
        (
          COALESCE(masa_satis.total_sales, 0)
          +
          COALESCE(paket_satis.total_sales, 0)
        ) AS total_sales
      FROM app_users
      LEFT JOIN (
        SELECT
          orders.user_id,
          COUNT(orders.id)::int AS closed_order_count,
          COALESCE(SUM(orders.total_price), 0) AS total_sales
        FROM orders
        WHERE orders.status = 'kapandi'
        ${orderDateFilter}
        GROUP BY orders.user_id
      ) AS masa_satis ON app_users.id = masa_satis.user_id
      LEFT JOIN (
        SELECT
          package_orders.user_id,
          COUNT(package_orders.id)::int AS closed_order_count,
          COALESCE(SUM(package_orders.total_price), 0) AS total_sales
        FROM package_orders
        WHERE package_orders.status = 'kapandi'
        ${packageOrderDateFilter}
        GROUP BY package_orders.user_id
      ) AS paket_satis ON app_users.id = paket_satis.user_id
      ORDER BY total_sales DESC, closed_order_count DESC
    `);

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Garson satış raporu alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Prim ayarlarını veritabanından okur; yoksa varsayılan kayıt oluşturur.
async function getCommissionSettingsRow() {
  const mevcut = await pool.query(
    `
    SELECT
      id,
      is_enabled,
      default_rate,
      employee_of_month_bonus,
      courier_commission_enabled,
      courier_default_rate,
      courier_delivery_bonus,
      updated_at
    FROM commission_settings
    WHERE id = 1
    LIMIT 1
    `
  );

  if (mevcut.rows.length > 0) {
    return mevcut.rows[0];
  }

  const yeni = await pool.query(
    `
    INSERT INTO commission_settings (
      id,
      is_enabled,
      default_rate,
      employee_of_month_bonus,
      courier_commission_enabled,
      courier_default_rate,
      courier_delivery_bonus
    )
    VALUES (1, TRUE, 5, 0, TRUE, 3, 0)
    RETURNING
      id,
      is_enabled,
      default_rate,
      employee_of_month_bonus,
      courier_commission_enabled,
      courier_default_rate,
      courier_delivery_bonus,
      updated_at
    `
  );

  return yeni.rows[0];
}

// Garsonların masa + paket satış özetini döndürür (sadece role = garson).
async function getGarsonSalesSummary(period) {
  const masaFiltre = getTableTimestampPeriodFilter("o", period);
  const paketFiltre = getTableTimestampPeriodFilter("po", period);

  const result = await pool.query(
    `
    WITH masa_satis AS (
      SELECT
        o.user_id,
        COUNT(o.id)::int AS closed_order_count,
        COALESCE(SUM(o.total_price), 0) AS total_sales
      FROM orders o
      WHERE o.status = 'kapandi'
      ${masaFiltre}
      GROUP BY o.user_id
    ),
    paket_satis AS (
      SELECT
        po.user_id,
        COUNT(po.id)::int AS closed_order_count,
        COALESCE(SUM(po.total_price), 0) AS total_sales
      FROM package_orders po
      WHERE po.status = 'kapandi'
      ${paketFiltre}
      GROUP BY po.user_id
    ),
    garson_satis AS (
      SELECT
        u.id AS user_id,
        u.full_name,
        u.username,
        (
          COALESCE(ms.closed_order_count, 0)
          + COALESCE(ps.closed_order_count, 0)
        )::int AS closed_order_count,
        (
          COALESCE(ms.total_sales, 0)
          + COALESCE(ps.total_sales, 0)
        ) AS total_sales
      FROM app_users u
      LEFT JOIN masa_satis ms ON ms.user_id = u.id
      LEFT JOIN paket_satis ps ON ps.user_id = u.id
      WHERE u.role = 'garson'
        AND u.is_active = TRUE
    )
    SELECT *
    FROM garson_satis
    ORDER BY total_sales DESC, closed_order_count DESC
    `,
    []
  );

  return result.rows;
}

// Garsonların ürün bazlı satış miktarlarını döndürür (kapalı siparişler).
async function getGarsonProductQuantities(period) {
  const masaFiltre = getTableTimestampPeriodFilter("o", period);
  const paketFiltre = getTableTimestampPeriodFilter("po", period);

  const result = await pool.query(
    `
    WITH urun_satis AS (
      SELECT
        user_id,
        product_id,
        SUM(quantity)::numeric AS sold_quantity
      FROM (
        SELECT
          o.user_id,
          oi.product_id,
          oi.quantity
        FROM orders o
        INNER JOIN order_items oi ON oi.order_id = o.id
        WHERE o.status = 'kapandi'
        ${masaFiltre}

        UNION ALL

        SELECT
          po.user_id,
          poi.product_id,
          poi.quantity
        FROM package_orders po
        INNER JOIN package_order_items poi
          ON poi.package_order_id = po.id
        WHERE po.status = 'kapandi'
        ${paketFiltre}
      ) AS combined_sales
      GROUP BY user_id, product_id
    )
    SELECT *
    FROM urun_satis
    `,
    []
  );

  return result.rows;
}

// Aktif ürün prim kurallarını ürün/kategori adıyla getirir.
async function getActiveProductCommissionRules() {
  const result = await pool.query(
    `
    SELECT
      product_commission_rules.id,
      product_commission_rules.product_id,
      products.name AS product_name,
      categories.name AS category_name,
      product_commission_rules.target_quantity,
      product_commission_rules.bonus_amount,
      product_commission_rules.is_active,
      product_commission_rules.created_at,
      product_commission_rules.updated_at
    FROM product_commission_rules
    INNER JOIN products ON product_commission_rules.product_id = products.id
    INNER JOIN categories ON products.category_id = categories.id
    WHERE product_commission_rules.is_active = TRUE
    ORDER BY products.name ASC
    `
  );

  return result.rows;
}

// Garson prim raporu verilerini hesaplar.
async function buildWaiterCommissionReport(period) {
  const settings = await getCommissionSettingsRow();
  const isEnabled = settings.is_enabled === true;
  const defaultRate = Number(settings.default_rate);
  const employeeOfMonthBonusAmount = Number(settings.employee_of_month_bonus);

  const garsonlar = await getGarsonSalesSummary(period);
  const productQuantities = await getGarsonProductQuantities(period);
  const activeRules = isEnabled ? await getActiveProductCommissionRules() : [];

  const quantityMap = {};
  for (const row of productQuantities) {
    const key = `${row.user_id}_${row.product_id}`;
    quantityMap[key] = Number(row.sold_quantity);
  }

  const waiters = garsonlar.map((garson) => {
    const userId = garson.user_id;
    const totalSales = Number(garson.total_sales);
    const closedOrderCount = Number(garson.closed_order_count);

    const baseCommission = isEnabled ? (totalSales * defaultRate) / 100 : 0;
    let productBonus = 0;
    const productBonusDetails = [];

    for (const rule of activeRules) {
      const productId = rule.product_id;
      const soldQuantity =
        quantityMap[`${userId}_${productId}`] !== undefined
          ? quantityMap[`${userId}_${productId}`]
          : 0;
      const targetQuantity = Number(rule.target_quantity);
      const bonusAmount = Number(rule.bonus_amount);
      const earned = soldQuantity >= targetQuantity;

      if (earned) {
        productBonus += bonusAmount;
      }

      productBonusDetails.push({
        product_id: productId,
        product_name: rule.product_name,
        sold_quantity: soldQuantity,
        target_quantity: targetQuantity,
        bonus_amount: bonusAmount,
        earned,
      });
    }

    const visibleTotalCommission = isEnabled
      ? baseCommission + productBonus
      : 0;

    return {
      user_id: userId,
      full_name: garson.full_name,
      username: garson.username,
      closed_order_count: closedOrderCount,
      total_sales: totalSales,
      default_rate: defaultRate,
      base_commission: baseCommission,
      product_bonus: productBonus,
      visible_total_commission: visibleTotalCommission,
      product_bonus_details: productBonusDetails,
      is_employee_of_month: false,
      employee_of_month_bonus: 0,
      manager_total_commission: visibleTotalCommission,
    };
  });

  if (period === "monthly" && waiters.length > 0) {
    const siralama = [...waiters].sort((a, b) => {
      if (b.total_sales !== a.total_sales) {
        return b.total_sales - a.total_sales;
      }
      return b.closed_order_count - a.closed_order_count;
    });

    const ayinElemaniId = siralama[0].user_id;

    for (const garson of waiters) {
      if (garson.user_id === ayinElemaniId) {
        garson.is_employee_of_month = true;
        garson.employee_of_month_bonus = isEnabled ? employeeOfMonthBonusAmount : 0;
        garson.manager_total_commission =
          garson.visible_total_commission + garson.employee_of_month_bonus;
      }
    }
  }

  return {
    is_enabled: isEnabled,
    settings,
    waiters,
  };
}

// Kuryelerin teslim edilen paket sipariş özetini döndürür.
async function getCourierDeliverySummary(period) {
  const paketFiltre = getTableTimestampPeriodFilter("po", period);

  const result = await pool.query(
    `
    SELECT
      u.id AS user_id,
      u.full_name,
      u.username,
      COUNT(po.id)::int AS delivered_order_count,
      COALESCE(SUM(po.total_price), 0) AS delivered_sales
    FROM app_users u
    INNER JOIN package_orders po ON po.courier_id = u.id
    WHERE u.role = 'kurye'
      AND u.is_active = TRUE
      AND po.status = 'kapandi'
      AND po.delivery_status = 'teslim_edildi'
      AND po.courier_id IS NOT NULL
      ${paketFiltre}
    GROUP BY u.id, u.full_name, u.username
    ORDER BY delivered_sales DESC, delivered_order_count DESC
    `,
    []
  );

  return result.rows;
}

// Kurye prim raporu verilerini hesaplar.
async function buildCourierCommissionReport(period) {
  const settings = await getCommissionSettingsRow();
  const isEnabled = settings.courier_commission_enabled === true;
  const defaultRate = Number(settings.courier_default_rate);
  const deliveryBonus = Number(settings.courier_delivery_bonus);

  const kuryeler = await getCourierDeliverySummary(period);

  const couriers = kuryeler.map((kurye) => {
    const deliveredSales = Number(kurye.delivered_sales);
    const deliveredOrderCount = Number(kurye.delivered_order_count);

    const salesCommission = isEnabled
      ? (deliveredSales * defaultRate) / 100
      : 0;
    const deliveryBonusTotal = isEnabled
      ? deliveredOrderCount * deliveryBonus
      : 0;
    const visibleTotalCommission = isEnabled
      ? salesCommission + deliveryBonusTotal
      : 0;

    return {
      user_id: kurye.user_id,
      full_name: kurye.full_name,
      username: kurye.username,
      delivered_order_count: deliveredOrderCount,
      delivered_sales: deliveredSales,
      courier_default_rate: defaultRate,
      sales_commission: salesCommission,
      delivery_bonus: deliveryBonusTotal,
      visible_total_commission: visibleTotalCommission,
    };
  });

  return {
    is_enabled: isEnabled,
    settings,
    couriers,
  };
}

// Prim ayarlarını getirir.
app.get("/api/commission/settings", async (req, res) => {
  try {
    const settings = await getCommissionSettingsRow();

    res.json({
      id: settings.id,
      is_enabled: settings.is_enabled,
      default_rate: settings.default_rate,
      employee_of_month_bonus: settings.employee_of_month_bonus,
      courier_commission_enabled: settings.courier_commission_enabled,
      courier_default_rate: settings.courier_default_rate,
      courier_delivery_bonus: settings.courier_delivery_bonus,
      updated_at: settings.updated_at,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Prim ayarları alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Prim ayarlarını günceller (garson + kurye alanları).
app.put("/api/commission/settings", async (req, res) => {
  const {
    isEnabled,
    defaultRate,
    employeeOfMonthBonus,
    courierCommissionEnabled,
    courierDefaultRate,
    courierDeliveryBonus,
  } = req.body;

  if (typeof isEnabled !== "boolean") {
    return res.status(400).json({
      success: false,
      message: "isEnabled alanı boolean olmalıdır.",
    });
  }

  if (typeof courierCommissionEnabled !== "boolean") {
    return res.status(400).json({
      success: false,
      message: "courierCommissionEnabled alanı boolean olmalıdır.",
    });
  }

  const oran = Number(defaultRate);
  const ayinElemaniPrim = Number(employeeOfMonthBonus);
  const kuryeOran = Number(courierDefaultRate);
  const kuryeTeslimatPrimi = Number(courierDeliveryBonus);

  if (Number.isNaN(oran) || oran < 0) {
    return res.status(400).json({
      success: false,
      message: "Genel prim oranı negatif olamaz.",
    });
  }

  if (Number.isNaN(ayinElemaniPrim) || ayinElemaniPrim < 0) {
    return res.status(400).json({
      success: false,
      message: "Ayın elemanı primi negatif olamaz.",
    });
  }

  if (Number.isNaN(kuryeOran) || kuryeOran < 0) {
    return res.status(400).json({
      success: false,
      message: "Kurye prim oranı negatif olamaz.",
    });
  }

  if (Number.isNaN(kuryeTeslimatPrimi) || kuryeTeslimatPrimi < 0) {
    return res.status(400).json({
      success: false,
      message: "Teslimat başı prim negatif olamaz.",
    });
  }

  try {
    await getCommissionSettingsRow();

    const result = await pool.query(
      `
      UPDATE commission_settings
      SET
        is_enabled = $1,
        default_rate = $2,
        employee_of_month_bonus = $3,
        courier_commission_enabled = $4,
        courier_default_rate = $5,
        courier_delivery_bonus = $6,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = 1
      RETURNING
        id,
        is_enabled,
        default_rate,
        employee_of_month_bonus,
        courier_commission_enabled,
        courier_default_rate,
        courier_delivery_bonus,
        updated_at
      `,
      [
        isEnabled,
        oran,
        ayinElemaniPrim,
        courierCommissionEnabled,
        kuryeOran,
        kuryeTeslimatPrimi,
      ]
    );

    const settings = result.rows[0];

    res.json({
      success: true,
      message: "Prim ayarları güncellendi.",
      id: settings.id,
      is_enabled: settings.is_enabled,
      default_rate: settings.default_rate,
      employee_of_month_bonus: settings.employee_of_month_bonus,
      courier_commission_enabled: settings.courier_commission_enabled,
      courier_default_rate: settings.courier_default_rate,
      courier_delivery_bonus: settings.courier_delivery_bonus,
      updated_at: settings.updated_at,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Prim ayarları güncellenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Ürün bazlı prim kurallarını listeler.
app.get("/api/commission/product-rules", async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT
        product_commission_rules.id,
        product_commission_rules.product_id,
        products.name AS product_name,
        categories.name AS category_name,
        product_commission_rules.target_quantity,
        product_commission_rules.bonus_amount,
        product_commission_rules.is_active,
        product_commission_rules.created_at,
        product_commission_rules.updated_at
      FROM product_commission_rules
      INNER JOIN products ON product_commission_rules.product_id = products.id
      INNER JOIN categories ON products.category_id = categories.id
      ORDER BY products.name ASC, product_commission_rules.id ASC
      `
    );

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Ürün prim kuralları listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Ürün bazlı prim kuralı ekler (aynı ürün için aktif kural varsa günceller).
app.post("/api/commission/product-rules", async (req, res) => {
  const { productId, targetQuantity, bonusAmount, isActive } = req.body;

  const urunId = Number(productId);
  const hedefMiktar = Number(targetQuantity);
  const ekstraPrim = Number(bonusAmount);
  const aktifMi = isActive !== false;

  if (!urunId || Number.isNaN(urunId)) {
    return res.status(400).json({
      success: false,
      message: "Geçerli bir ürün seçilmelidir.",
    });
  }

  if (Number.isNaN(hedefMiktar) || hedefMiktar <= 0) {
    return res.status(400).json({
      success: false,
      message: "Hedef miktar 0'dan büyük olmalıdır.",
    });
  }

  if (Number.isNaN(ekstraPrim) || ekstraPrim < 0) {
    return res.status(400).json({
      success: false,
      message: "Ekstra prim tutarı negatif olamaz.",
    });
  }

  try {
    const urunKontrol = await pool.query(
      `SELECT id FROM products WHERE id = $1 LIMIT 1`,
      [urunId]
    );

    if (urunKontrol.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Ürün bulunamadı.",
      });
    }

    const mevcutAktif = await pool.query(
      `
      SELECT id
      FROM product_commission_rules
      WHERE product_id = $1 AND is_active = TRUE
      LIMIT 1
      `,
      [urunId]
    );

    let result;

    if (mevcutAktif.rows.length > 0) {
      result = await pool.query(
        `
        UPDATE product_commission_rules
        SET
          target_quantity = $1,
          bonus_amount = $2,
          is_active = $3,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = $4
        RETURNING *
        `,
        [hedefMiktar, ekstraPrim, aktifMi, mevcutAktif.rows[0].id]
      );
    } else {
      result = await pool.query(
        `
        INSERT INTO product_commission_rules (
          product_id, target_quantity, bonus_amount, is_active
        )
        VALUES ($1, $2, $3, $4)
        RETURNING *
        `,
        [urunId, hedefMiktar, ekstraPrim, aktifMi]
      );
    }

    res.status(201).json({
      success: true,
      message: "Ürün prim kuralı kaydedildi.",
      rule: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Ürün prim kuralı eklenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Ürün bazlı prim kuralını günceller.
app.put("/api/commission/product-rules/:id", async (req, res) => {
  const ruleId = Number(req.params.id);
  const { productId, targetQuantity, bonusAmount, isActive } = req.body;

  const urunId = Number(productId);
  const hedefMiktar = Number(targetQuantity);
  const ekstraPrim = Number(bonusAmount);
  const aktifMi = isActive !== false;

  if (!ruleId || Number.isNaN(ruleId)) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz kural numarası.",
    });
  }

  if (!urunId || Number.isNaN(urunId)) {
    return res.status(400).json({
      success: false,
      message: "Geçerli bir ürün seçilmelidir.",
    });
  }

  if (Number.isNaN(hedefMiktar) || hedefMiktar <= 0) {
    return res.status(400).json({
      success: false,
      message: "Hedef miktar 0'dan büyük olmalıdır.",
    });
  }

  if (Number.isNaN(ekstraPrim) || ekstraPrim < 0) {
    return res.status(400).json({
      success: false,
      message: "Ekstra prim tutarı negatif olamaz.",
    });
  }

  try {
    const result = await pool.query(
      `
      UPDATE product_commission_rules
      SET
        product_id = $1,
        target_quantity = $2,
        bonus_amount = $3,
        is_active = $4,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $5
      RETURNING *
      `,
      [urunId, hedefMiktar, ekstraPrim, aktifMi, ruleId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Prim kuralı bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Ürün prim kuralı güncellendi.",
      rule: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Ürün prim kuralı güncellenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Ürün bazlı prim kuralını siler.
app.delete("/api/commission/product-rules/:id", async (req, res) => {
  const ruleId = Number(req.params.id);

  if (!ruleId || Number.isNaN(ruleId)) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz kural numarası.",
    });
  }

  try {
    const result = await pool.query(
      `
      DELETE FROM product_commission_rules
      WHERE id = $1
      RETURNING id
      `,
      [ruleId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Prim kuralı bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Ürün prim kuralı silindi.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Ürün prim kuralı silinirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yönetici garson prim raporu (ayın elemanı özel primi dahil).
app.get("/api/commission/waiter-report", async (req, res) => {
  const period = req.query.period || "monthly";

  try {
    const rapor = await buildWaiterCommissionReport(period);

    const cevap = rapor.waiters.map((garson) => ({
      user_id: garson.user_id,
      full_name: garson.full_name,
      username: garson.username,
      closed_order_count: garson.closed_order_count,
      total_sales: garson.total_sales,
      default_rate: garson.default_rate,
      base_commission: garson.base_commission,
      product_bonus: garson.product_bonus,
      visible_total_commission: garson.visible_total_commission,
      is_employee_of_month: garson.is_employee_of_month,
      employee_of_month_bonus: garson.employee_of_month_bonus,
      manager_total_commission: garson.manager_total_commission,
    }));

    res.json({
      is_enabled: rapor.is_enabled,
      period,
      waiters: cevap,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Garson prim raporu alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Garsonun kendi prim raporu (ayın elemanı özel primi GÖNDERİLMEZ).
app.get("/api/commission/my-report/:userId", async (req, res) => {
  const userId = Number(req.params.userId);
  const period = req.query.period || "monthly";

  if (!userId || Number.isNaN(userId)) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz kullanıcı numarası.",
    });
  }

  try {
    const kullanici = await pool.query(
      `
      SELECT id, full_name, username, role
      FROM app_users
      WHERE id = $1
      LIMIT 1
      `,
      [userId]
    );

    if (kullanici.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Kullanıcı bulunamadı.",
      });
    }

    if (kullanici.rows[0].role !== "garson") {
      return res.status(403).json({
        success: false,
        message: "Bu rapor sadece garson kullanıcıları içindir.",
      });
    }

    const rapor = await buildWaiterCommissionReport(period);
    const garsonRapor = rapor.waiters.find((g) => g.user_id === userId);

    if (!garsonRapor) {
      return res.json({
        is_enabled: rapor.is_enabled,
        user_id: userId,
        full_name: kullanici.rows[0].full_name,
        closed_order_count: 0,
        total_sales: 0,
        default_rate: Number(rapor.settings.default_rate),
        base_commission: 0,
        product_bonus: 0,
        visible_total_commission: 0,
        product_bonus_details: [],
      });
    }

    res.json({
      is_enabled: rapor.is_enabled,
      user_id: garsonRapor.user_id,
      full_name: garsonRapor.full_name,
      closed_order_count: garsonRapor.closed_order_count,
      total_sales: garsonRapor.total_sales,
      default_rate: garsonRapor.default_rate,
      base_commission: garsonRapor.base_commission,
      product_bonus: garsonRapor.product_bonus,
      visible_total_commission: garsonRapor.visible_total_commission,
      product_bonus_details: garsonRapor.product_bonus_details.map((detay) => ({
        product_name: detay.product_name,
        sold_quantity: detay.sold_quantity,
        target_quantity: detay.target_quantity,
        bonus_amount: detay.bonus_amount,
        earned: detay.earned,
      })),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Garson prim raporu alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yönetici kurye prim raporu.
app.get("/api/commission/courier-report", async (req, res) => {
  const period = req.query.period || "monthly";

  try {
    const rapor = await buildCourierCommissionReport(period);

    res.json({
      is_enabled: rapor.is_enabled,
      period,
      couriers: rapor.couriers,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kurye prim raporu alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Kuryenin kendi prim raporu.
app.get("/api/commission/my-courier-report/:userId", async (req, res) => {
  const userId = Number(req.params.userId);
  const period = req.query.period || "monthly";

  if (!userId || Number.isNaN(userId)) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz kullanıcı numarası.",
    });
  }

  try {
    const kullanici = await pool.query(
      `
      SELECT id, full_name, username, role
      FROM app_users
      WHERE id = $1
      LIMIT 1
      `,
      [userId]
    );

    if (kullanici.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Kullanıcı bulunamadı.",
      });
    }

    if (kullanici.rows[0].role !== "kurye") {
      return res.status(403).json({
        success: false,
        message: "Bu rapor sadece kurye kullanıcıları içindir.",
      });
    }

    const rapor = await buildCourierCommissionReport(period);
    const kuryeRapor = rapor.couriers.find((k) => k.user_id === userId);

    if (!kuryeRapor) {
      return res.json({
        is_enabled: rapor.is_enabled,
        user_id: userId,
        full_name: kullanici.rows[0].full_name,
        delivered_order_count: 0,
        delivered_sales: 0,
        courier_default_rate: Number(rapor.settings.courier_default_rate),
        sales_commission: 0,
        delivery_bonus: 0,
        visible_total_commission: 0,
      });
    }

    res.json({
      is_enabled: rapor.is_enabled,
      user_id: kuryeRapor.user_id,
      full_name: kuryeRapor.full_name,
      delivered_order_count: kuryeRapor.delivered_order_count,
      delivered_sales: kuryeRapor.delivered_sales,
      courier_default_rate: kuryeRapor.courier_default_rate,
      sales_commission: kuryeRapor.sales_commission,
      delivery_bonus: kuryeRapor.delivery_bonus,
      visible_total_commission: kuryeRapor.visible_total_commission,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kurye prim raporu alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Geçerli müşteri geri bildirim türleri.
const gecerliFeedbackTurleri = ["istek", "sikayet", "oneri"];

// Geçerli müşteri geri bildirim durumları.
const gecerliFeedbackDurumlari = [
  "bekliyor",
  "incelendi",
  "tamamlandi",
  "reddedildi",
];

// Müşteri geri bildirimi gönderir (QR menü, giriş gerekmez).
app.post("/api/customer-feedback", async (req, res) => {
  let { feedbackType, customerName, customerPhone, tableNumber, message } =
    req.body;

  if (!message || String(message).trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Mesaj boş bırakılamaz.",
    });
  }

  const tur = feedbackType ? String(feedbackType).trim().toLowerCase() : "istek";

  if (!gecerliFeedbackTurleri.includes(tur)) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz mesaj türü. istek, sikayet veya oneri olmalıdır.",
    });
  }

  const ad =
    customerName && String(customerName).trim() !== ""
      ? String(customerName).trim()
      : null;
  const telefon =
    customerPhone && String(customerPhone).trim() !== ""
      ? String(customerPhone).trim()
      : null;

  let masaNo = null;
  if (tableNumber !== undefined && tableNumber !== null && tableNumber !== "") {
    const parsed = Number.parseInt(String(tableNumber), 10);
    if (!Number.isNaN(parsed)) {
      masaNo = parsed;
    }
  }

  try {
    await pool.query(
      `
      INSERT INTO customer_feedback (
        feedback_type,
        customer_name,
        customer_phone,
        table_number,
        message,
        status
      )
      VALUES ($1, $2, $3, $4, $5, 'bekliyor')
      `,
      [tur, ad, telefon, masaNo, String(message).trim()]
    );

    res.status(201).json({
      success: true,
      message: "Mesajınız başarıyla iletildi.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Mesaj gönderilirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yönetici: müşteri geri bildirimlerini listeler.
app.get("/api/customer-feedback", async (req, res) => {
  const status = (req.query.status || "all").toString().toLowerCase();
  const type = (req.query.type || "all").toString().toLowerCase();

  if (status !== "all" && !gecerliFeedbackDurumlari.includes(status)) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz durum filtresi.",
    });
  }

  if (type !== "all" && !gecerliFeedbackTurleri.includes(type)) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz tür filtresi.",
    });
  }

  try {
    const kosullar = [];
    const parametreler = [];

    if (status !== "all") {
      parametreler.push(status);
      kosullar.push(`status = $${parametreler.length}`);
    }

    if (type !== "all") {
      parametreler.push(type);
      kosullar.push(`feedback_type = $${parametreler.length}`);
    }

    const whereClause =
      kosullar.length > 0 ? `WHERE ${kosullar.join(" AND ")}` : "";

    const result = await pool.query(
      `
      SELECT
        id,
        feedback_type,
        customer_name,
        customer_phone,
        table_number,
        message,
        status,
        manager_note,
        created_at,
        updated_at
      FROM customer_feedback
      ${whereClause}
      ORDER BY created_at DESC, id DESC
      `,
      parametreler
    );

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Geri bildirimler listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yönetici: geri bildirim durumunu günceller.
app.put("/api/customer-feedback/:id", async (req, res) => {
  const feedbackId = Number.parseInt(req.params.id, 10);
  const { status, managerNote } = req.body;

  if (!Number.isInteger(feedbackId) || feedbackId <= 0) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz geri bildirim numarası.",
    });
  }

  if (!status || !gecerliFeedbackDurumlari.includes(String(status).trim())) {
    return res.status(400).json({
      success: false,
      message: "Geçerli bir durum seçilmelidir.",
    });
  }

  const not =
    managerNote !== undefined && managerNote !== null
      ? String(managerNote).trim()
      : null;

  try {
    const result = await pool.query(
      `
      UPDATE customer_feedback
      SET
        status = $1,
        manager_note = $2,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $3
      RETURNING
        id,
        feedback_type,
        customer_name,
        customer_phone,
        table_number,
        message,
        status,
        manager_note,
        created_at,
        updated_at
      `,
      [String(status).trim(), not === "" ? null : not, feedbackId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Geri bildirim bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Geri bildirim güncellendi.",
      feedback: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Geri bildirim güncellenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yönetici: geri bildirimi siler.
app.delete("/api/customer-feedback/:id", async (req, res) => {
  const feedbackId = Number.parseInt(req.params.id, 10);

  if (!Number.isInteger(feedbackId) || feedbackId <= 0) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz geri bildirim numarası.",
    });
  }

  try {
    const result = await pool.query(
      `
      DELETE FROM customer_feedback
      WHERE id = $1
      RETURNING id
      `,
      [feedbackId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Geri bildirim bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Geri bildirim silindi.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Geri bildirim silinirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Kafe ayarlarını okur; yoksa varsayılan kayıt oluşturur.
async function getCafeSettingsRow() {
  const mevcut = await pool.query(
    `
    SELECT
      id,
      cafe_name,
      opening_hours,
      address,
      phone,
      map_url,
      instagram_url,
      is_open,
      theme_key,
      primary_color,
      menu_layout,
      logo_url,
      updated_at
    FROM cafe_settings
    WHERE id = 1
    LIMIT 1
    `
  );

  if (mevcut.rows.length > 0) {
    return mevcut.rows[0];
  }

  const yeni = await pool.query(
    `
    INSERT INTO cafe_settings (id, cafe_name, opening_hours, is_open)
    VALUES (
      1,
      'Kafe Otomasyonu',
      'Hafta içi 09:00 - 22:00, Hafta sonu 10:00 - 23:00',
      TRUE
    )
    RETURNING
      id,
      cafe_name,
      opening_hours,
      address,
      phone,
      map_url,
      instagram_url,
      is_open,
      theme_key,
      primary_color,
      menu_layout,
      logo_url,
      updated_at
    `
  );

  return yeni.rows[0];
}

// Kafe logosu yükleme endpoint'i (multipart/form-data, field: logo).
app.post(
  "/api/cafe-settings/logo",
  (req, res, next) => {
    kafeLogoYukle.single("logo")(req, res, (error) => {
      if (error) {
        return res.status(400).json({
          success: false,
          message: error.message || "Logo yüklenemedi.",
        });
      }
      next();
    });
  },
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "Logo dosyası gönderilmedi.",
        });
      }

      const mevcutAyar = await getCafeSettingsRow();
      const eskiLogoUrl = mevcutAyar.logo_url;
      const publicLogoYolu = `/uploads/cafe/${req.file.filename}`;

      sunucuKafeLogosunuSil(eskiLogoUrl);

      const result = await pool.query(
        `
        UPDATE cafe_settings
        SET logo_url = $1, updated_at = CURRENT_TIMESTAMP
        WHERE id = 1
        RETURNING logo_url
        `,
        [publicLogoYolu]
      );

      res.json({
        success: true,
        message: "Kafe logosu başarıyla yüklendi.",
        logo_url: result.rows[0].logo_url,
      });
    } catch (error) {
      if (req.file && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }

      res.status(500).json({
        success: false,
        message: "Kafe logosu yüklenirken hata oluştu.",
        error: error.message || String(error),
      });
    }
  }
);

// Kafe logosunu kaldıran endpoint.
app.delete("/api/cafe-settings/logo", async (req, res) => {
  try {
    const mevcutAyar = await getCafeSettingsRow();
    sunucuKafeLogosunuSil(mevcutAyar.logo_url);

    await pool.query(
      `
      UPDATE cafe_settings
      SET logo_url = NULL, updated_at = CURRENT_TIMESTAMP
      WHERE id = 1
      `
    );

    res.json({
      success: true,
      message: "Kafe logosu kaldırıldı.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kafe logosu kaldırılırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Public: QR menü için kafe bilgisi ve aktif etkinlikler.
app.get("/api/public-cafe-info", async (req, res) => {
  try {
    const settings = await getCafeSettingsRow();

    const events = await pool.query(
      `
      SELECT
        id,
        title,
        description,
        event_date,
        is_active,
        created_at,
        updated_at
      FROM cafe_events
      WHERE is_active = TRUE
      ORDER BY event_date ASC NULLS LAST, created_at DESC
      `
    );

    res.json({
      settings,
      events: events.rows,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kafe bilgileri alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yönetici: kafe ayarlarını getirir.
app.get("/api/cafe-settings", async (req, res) => {
  try {
    const settings = await getCafeSettingsRow();
    res.json(settings);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kafe ayarları alınırken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yönetici: kafe ayarlarını günceller.
app.put("/api/cafe-settings", async (req, res) => {
  const {
    cafeName,
    openingHours,
    address,
    phone,
    mapUrl,
    instagramUrl,
    isOpen,
    themeKey,
    primaryColor,
    menuLayout,
  } = req.body;

  if (!cafeName || String(cafeName).trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Kafe adı boş bırakılamaz.",
    });
  }

  if (typeof isOpen !== "boolean") {
    return res.status(400).json({
      success: false,
      message: "isOpen alanı boolean olmalıdır.",
    });
  }

  // Tema ve menü görünümü varsayılanları.
  let gecerliThemeKey = themeKey ? String(themeKey).trim() : "brown";
  if (!gecerliThemeKey) gecerliThemeKey = "brown";

  let gecerliPrimaryColor = primaryColor
    ? String(primaryColor).trim()
    : "#795548";
  if (!gecerliPrimaryColor) gecerliPrimaryColor = "#795548";

  let gecerliMenuLayout = menuLayout ? String(menuLayout).trim() : "vertical";
  if (gecerliMenuLayout !== "horizontal") gecerliMenuLayout = "vertical";

  try {
    await getCafeSettingsRow();

    const result = await pool.query(
      `
      UPDATE cafe_settings
      SET
        cafe_name = $1,
        opening_hours = $2,
        address = $3,
        phone = $4,
        map_url = $5,
        instagram_url = $6,
        is_open = $7,
        theme_key = $8,
        primary_color = $9,
        menu_layout = $10,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = 1
      RETURNING
        id,
        cafe_name,
        opening_hours,
        address,
        phone,
        map_url,
        instagram_url,
        is_open,
        theme_key,
        primary_color,
        menu_layout,
        logo_url,
        updated_at
      `,
      [
        String(cafeName).trim(),
        openingHours ? String(openingHours).trim() : null,
        address ? String(address).trim() : null,
        phone ? String(phone).trim() : null,
        mapUrl ? String(mapUrl).trim() : null,
        instagramUrl ? String(instagramUrl).trim() : null,
        isOpen,
        gecerliThemeKey,
        gecerliPrimaryColor,
        gecerliMenuLayout,
      ]
    );

    res.json({
      success: true,
      message: "Kafe bilgileri güncellendi.",
      settings: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Kafe ayarları güncellenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yönetici: tüm etkinlikleri listeler.
app.get("/api/cafe-events", async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT
        id,
        title,
        description,
        event_date,
        is_active,
        created_at,
        updated_at
      FROM cafe_events
      ORDER BY event_date ASC NULLS LAST, created_at DESC
      `
    );

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Etkinlikler listelenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yönetici: etkinlik ekler.
app.post("/api/cafe-events", async (req, res) => {
  const { title, description, eventDate, isActive } = req.body;

  if (!title || String(title).trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Etkinlik başlığı boş bırakılamaz.",
    });
  }

  const aktifMi = isActive !== false;
  const aciklama =
    description && String(description).trim() !== ""
      ? String(description).trim()
      : null;
  const tarih =
    eventDate && String(eventDate).trim() !== ""
      ? String(eventDate).trim()
      : null;

  try {
    const result = await pool.query(
      `
      INSERT INTO cafe_events (title, description, event_date, is_active)
      VALUES ($1, $2, $3, $4)
      RETURNING
        id,
        title,
        description,
        event_date,
        is_active,
        created_at,
        updated_at
      `,
      [String(title).trim(), aciklama, tarih, aktifMi]
    );

    res.status(201).json({
      success: true,
      message: "Etkinlik eklendi.",
      event: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Etkinlik eklenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yönetici: etkinlik günceller.
app.put("/api/cafe-events/:id", async (req, res) => {
  const eventId = Number.parseInt(req.params.id, 10);
  const { title, description, eventDate, isActive } = req.body;

  if (!Number.isInteger(eventId) || eventId <= 0) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz etkinlik numarası.",
    });
  }

  if (!title || String(title).trim() === "") {
    return res.status(400).json({
      success: false,
      message: "Etkinlik başlığı boş bırakılamaz.",
    });
  }

  if (typeof isActive !== "boolean") {
    return res.status(400).json({
      success: false,
      message: "isActive alanı boolean olmalıdır.",
    });
  }

  const aciklama =
    description && String(description).trim() !== ""
      ? String(description).trim()
      : null;
  const tarih =
    eventDate && String(eventDate).trim() !== ""
      ? String(eventDate).trim()
      : null;

  try {
    const result = await pool.query(
      `
      UPDATE cafe_events
      SET
        title = $1,
        description = $2,
        event_date = $3,
        is_active = $4,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $5
      RETURNING
        id,
        title,
        description,
        event_date,
        is_active,
        created_at,
        updated_at
      `,
      [String(title).trim(), aciklama, tarih, isActive, eventId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Etkinlik bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Etkinlik güncellendi.",
      event: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Etkinlik güncellenirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Yönetici: etkinlik siler.
app.delete("/api/cafe-events/:id", async (req, res) => {
  const eventId = Number.parseInt(req.params.id, 10);

  if (!Number.isInteger(eventId) || eventId <= 0) {
    return res.status(400).json({
      success: false,
      message: "Geçersiz etkinlik numarası.",
    });
  }

  try {
    const result = await pool.query(
      `
      DELETE FROM cafe_events
      WHERE id = $1
      RETURNING id
      `,
      [eventId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Etkinlik bulunamadı.",
      });
    }

    res.json({
      success: true,
      message: "Etkinlik silindi.",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Etkinlik silinirken hata oluştu.",
      error: error.message || String(error),
    });
  }
});

// Sunucuyu başlatıyoruz.
app.listen(PORT, () => {
  console.log(`Kafe Otomasyonu Backend API ${PORT} portunda çalışıyor.`);
});