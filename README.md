<div align="center">

# ☕ Modern Kafe Otomasyonu

**Flutter + Node.js + PostgreSQL ile geliştirilmiş; garson, yönetici, kurye ve müşteri QR menü süreçlerini tek panelde yöneten modern kafe otomasyonu uygulaması.**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-Frontend-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-Backend-339933?style=for-the-badge&logo=node.js&logoColor=white)
![Express](https://img.shields.io/badge/Express.js-API-000000?style=for-the-badge&logo=express&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)

<br>

<img src="docs/images/kafe-otomasyonu-afis.png" alt="Kafe Otomasyonu Afiş" width="100%" />

</div>

---

## 📌 Proje Hakkında

**Modern Kafe Otomasyonu**, kafe ve restoran işletmelerinde sipariş alma, masa yönetimi, paket sipariş takibi, kurye atama, QR menü, gelir-gider takibi, raporlama ve personel prim süreçlerini dijital ortama taşımak için geliştirilmiş kapsamlı bir otomasyon sistemidir.

Proje üç ana bölümden oluşur:

| Bölüm | Açıklama |
|---|---|
| **Frontend** | Flutter ile geliştirilen kullanıcı arayüzü |
| **Backend** | Node.js ve Express.js ile geliştirilen REST API |
| **Database** | PostgreSQL tablo yapısı ve başlangıç verileri |

---

## 🧭 İçindekiler

- [Öne Çıkan Özellikler](#-öne-çıkan-özellikler)
- [Kullanıcı Rolleri](#-kullanıcı-rolleri)
- [Ekran Görüntüleri](#-ekran-görüntüleri)
- [Kullanılan Teknolojiler](#-kullanılan-teknolojiler)
- [Proje Yapısı](#-proje-yapısı)
- [Kurulum](#-kurulum)
- [Veritabanı Kurulumu](#-veritabanı-kurulumu)
- [API Modülleri](#-api-modülleri)
- [Geliştirme Notları](#-geliştirme-notları)

---

## 🚀 Öne Çıkan Özellikler

### 👤 Rol Bazlı Giriş Sistemi

- Yönetici, garson ve kurye rolleri için ayrı kullanım senaryoları
- Kullanıcı adı ve şifre ile giriş
- Kullanıcı aktif/pasif durum kontrolü
- Şifre değiştirme işlemleri

### 🪑 Masa ve Sipariş Yönetimi

- Masa listeleme
- Masa bölümü/kategorisi yönetimi
- Masaya ürün ekleme
- Aktif sipariş görüntüleme
- Sipariş notu ekleme
- Hesap kapatma

### 🛵 Paket Sipariş ve Kurye Süreci

- Paket sipariş oluşturma
- Müşteri adı, telefon, adres ve sipariş notu kaydı
- Aktif paket sipariş listesi
- Kuryeye sipariş atama
- Teslimat durumu güncelleme
- Paket siparişi tamamlama veya iptal etme

### 📱 QR Menü

- Müşterilerin giriş yapmadan menüye erişebilmesi
- Dikey ve yatay menü görünümü
- Ürün görselleri, açıklamaları ve fiyatları
- Kafe bilgileri ve aktif etkinliklerin gösterimi
- Müşteri geri bildirim formu

### 🧾 Ürün ve Menü Yönetimi

- Ürün ekleme, güncelleme ve pasifleştirme
- Kategori yönetimi
- Ürün görseli yükleme
- Ürün görünürlük durumu
- QR menüde gösterilecek ürünlerin kontrolü

### 💰 Gelir-Gider ve Malzeme Takibi

- Gelir-gider özeti
- Genel gider kayıtları
- Malzeme alım kayıtları
- Günlük, haftalık, aylık ve tüm zaman filtreleri

### 📊 Raporlama

- Satış raporları
- Kapanan hesaplar
- En çok satılan ürünler
- Kullanıcı bazlı satış raporu
- Garson ve kurye prim raporları

### 🎯 Personel Prim Sistemi

- Garson prim ayarları
- Kurye prim ayarları
- Ürün bazlı prim kuralı oluşturma
- Ayın elemanı primi
- Garsonun kendi prim raporu
- Kuryenin kendi prim raporu

### 🏪 Kafe Bilgi Yönetimi

- Kafe adı, adres, telefon ve çalışma saatleri
- Instagram ve harita bağlantısı
- Açık/kapalı durumu
- Tema rengi ve QR menü görünüm seçimi
- Kafe etkinlikleri yönetimi

---

## 👥 Kullanıcı Rolleri

| Rol | Yetkiler |
|---|---|
| **Yönetici** | Menü, masa, kullanıcı, rapor, gelir-gider, prim, QR menü ve kafe bilgilerini yönetir. |
| **Garson** | Masa seçer, sipariş oluşturur, hesap kapatır ve kendi prim bilgisini görüntüler. |
| **Kurye** | Kendisine atanan paket siparişleri görüntüler, teslimat durumunu günceller ve kendi primini takip eder. |
| **Müşteri** | QR menü üzerinden ürünleri görüntüler ve geri bildirim gönderir. |

---

## 🖼️ Ekran Görüntüleri

> Görseller `docs/ui-design/stitch/` klasöründe bulunan UI/UX tasarım referanslarından alınmıştır.

### 🔐 Giriş ve Rol Panelleri

<table>
  <tr>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/01-ana-giris.png" alt="Ana Giriş Ekranı" width="100%" />
      <br><strong>Ana Giriş</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/02-garson-paneli.png" alt="Garson Paneli" width="100%" />
      <br><strong>Garson Paneli</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/03-yonetici-paneli.png" alt="Yönetici Paneli" width="100%" />
      <br><strong>Yönetici Paneli</strong>
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/04-kurye-paneli.png" alt="Kurye Paneli" width="100%" />
      <br><strong>Kurye Paneli</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/18-sifremi-degistir-modal.png" alt="Şifre Değiştirme Modalı" width="100%" />
      <br><strong>Şifre Değiştirme</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/08-kullanici-yonetimi.png" alt="Kullanıcı Yönetimi" width="100%" />
      <br><strong>Kullanıcı Yönetimi</strong>
    </td>
  </tr>
</table>

---

### 🪑 Masa, Sipariş ve Paket Sipariş Süreçleri

<table>
  <tr>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/21-masa-secimi.png" alt="Masa Seçimi" width="100%" />
      <br><strong>Masa Seçimi</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/22-siparis-ekrani.png" alt="Sipariş Ekranı" width="100%" />
      <br><strong>Sipariş Ekranı</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/23-paket-siparis-olusturma.png" alt="Paket Sipariş Oluşturma" width="100%" />
      <br><strong>Paket Sipariş Oluşturma</strong>
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/19-paket-siparis-listesi.png" alt="Paket Sipariş Listesi" width="100%" />
      <br><strong>Paket Sipariş Listesi</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/20-kurye-teslimat-kartlari.png" alt="Kurye Teslimat Kartları" width="100%" />
      <br><strong>Kurye Teslimat Kartları</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/16-garson-kendi-primlerim.png" alt="Garson Primleri" width="100%" />
      <br><strong>Garson Primleri</strong>
    </td>
  </tr>
</table>

---

### 📱 QR Menü ve Menü Yönetimi

<table>
  <tr>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/05-qr-menu-dikey.png" alt="QR Menü Dikey Görünüm" width="100%" />
      <br><strong>QR Menü Dikey</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/06-qr-menu-yatay.png" alt="QR Menü Yatay Görünüm" width="100%" />
      <br><strong>QR Menü Yatay</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/07-menu-yonetimi.png" alt="Menü Yönetimi" width="100%" />
      <br><strong>Menü Yönetimi</strong>
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/15-qr-menu-yonetimi.png" alt="QR Menü Yönetimi" width="100%" />
      <br><strong>QR Menü Yönetimi</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/10-musteri-geri-bildirimleri.png" alt="Müşteri Geri Bildirimleri" width="100%" />
      <br><strong>Müşteri Geri Bildirimleri</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/11-kafe-bilgi-yonetimi.png" alt="Kafe Bilgi Yönetimi" width="100%" />
      <br><strong>Kafe Bilgi Yönetimi</strong>
    </td>
  </tr>
</table>

---

### 📊 Yönetim, Finans ve Raporlama

<table>
  <tr>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/12-gelir-gider.png" alt="Gelir Gider Yönetimi" width="100%" />
      <br><strong>Gelir-Gider</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/13-malzeme-alim.png" alt="Malzeme Alım Yönetimi" width="100%" />
      <br><strong>Malzeme Alım</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/14-raporlama.png" alt="Raporlama" width="100%" />
      <br><strong>Raporlama</strong>
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/09-personel-prim-yonetimi.png" alt="Personel Prim Yönetimi" width="100%" />
      <br><strong>Personel Prim Yönetimi</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/17-kurye-kendi-primlerim.png" alt="Kurye Primleri" width="100%" />
      <br><strong>Kurye Primleri</strong>
    </td>
    <td align="center" width="33%">
      <img src="docs/ui-design/stitch/04-kurye-paneli.png" alt="Kurye Paneli" width="100%" />
      <br><strong>Kurye Operasyonları</strong>
    </td>
  </tr>
</table>

---

## 🛠️ Kullanılan Teknolojiler

### Frontend

| Teknoloji / Paket | Kullanım Amacı |
|---|---|
| **Flutter** | Web ve mobil arayüz geliştirme |
| **Dart** | Flutter uygulama dili |
| **http** | Backend API ile haberleşme |
| **file_picker** | Görsel/dosya seçimi |
| **http_parser** | Multipart görsel yükleme içerik tipi yönetimi |
| **qr_flutter** | QR menü bağlantıları için QR üretimi |
| **file_saver** | Dosya dışa aktarma işlemleri |
| **url_launcher** | Harici bağlantı açma |

### Backend

| Teknoloji / Paket | Kullanım Amacı |
|---|---|
| **Node.js** | Backend çalışma ortamı |
| **Express.js** | REST API geliştirme |
| **PostgreSQL / pg** | Veritabanı bağlantısı ve sorgular |
| **dotenv** | Ortam değişkenleri yönetimi |
| **cors** | Frontend-backend istek izinleri |
| **multer** | Ürün ve kafe görseli yükleme |

---

## 📁 Proje Yapısı

```text
kafe-otomasyonu/
│
├── backend/
│   ├── server.js
│   ├── package.json
│   └── uploads/
│       ├── products/
│       └── cafe/
│
├── database/
│   └── database.sql
│
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── screens/
│   │   └── services/
│   │       └── api_service.dart
│   ├── pubspec.yaml
│   └── test/
│
├── docs/
│   ├── images/
│   │   └── kafe-otomasyonu-afis.png
│   └── ui-design/
│       └── stitch/
│           ├── 01-ana-giris.png
│           ├── 02-garson-paneli.png
│           └── ...
│
└── README.md
```

---

## ⚙️ Kurulum

### 1. Repoyu Klonla

```bash
git clone https://github.com/fmslgn/kafe-otomasyonu.git
cd kafe-otomasyonu
```

---

## 🗄️ Veritabanı Kurulumu

PostgreSQL üzerinde proje için veritabanı oluştur:

```sql
CREATE DATABASE kafe_otomasyonu_db;
```

Ardından proje içindeki SQL dosyasını çalıştır:

```bash
psql -U postgres -d kafe_otomasyonu_db -f database/database.sql
```

Bu dosya aşağıdaki yapıları oluşturur:

- Kullanıcılar
- Kategoriler ve ürünler
- Masalar
- Masa siparişleri
- Paket siparişleri
- Gelir-gider kayıtları
- Malzeme alımları
- Prim ayarları
- Ürün bazlı prim kuralları
- Müşteri geri bildirimleri
- Kafe bilgileri
- Kafe etkinlikleri

Varsayılan giriş bilgileri:

| Rol | Kullanıcı Adı | Şifre |
|---|---|---|
| Yönetici | `admin` | `1234` |
| Garson | `garson` | `1234` |
| Kurye | `kurye` | `1234` |

---

### 2. Backend Kurulumu

```bash
cd backend
npm install
```

Backend klasörü içinde `.env` dosyası oluştur:

```env
PORT=3000
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=kafe_otomasyonu_db
DB_USER=postgres
DB_PASSWORD=postgres
```

Backend sunucusunu başlat:

```bash
npm start
```

Backend çalıştığında aşağıdaki adreslerden kontrol edilebilir:

```text
http://localhost:3000
http://localhost:3000/api/test-db
```

---

### 3. Frontend Kurulumu

Yeni terminal açıp proje kök dizininden frontend klasörüne gir:

```bash
cd frontend
flutter pub get
```

Flutter web olarak çalıştırmak için:

```bash
flutter run -d chrome
```

Mobil cihaz veya emülatör üzerinde çalıştırmak için:

```bash
flutter run
```

---

## 🌐 API Modülleri

Frontend, backend ile `ApiService` üzerinden haberleşir. Varsayılan backend adresi:

```dart
static const String baseUrl = 'http://localhost:3000';
```

Farklı bir sunucu kullanmak istersen `frontend/lib/services/api_service.dart` içindeki `baseUrl` değeri güncellenmelidir.

| Modül | Örnek Endpointler | Açıklama |
|---|---|---|
| Auth | `/api/login` | Kullanıcı giriş işlemleri |
| Ürünler | `/api/products` | Ürün listeleme, ekleme, güncelleme |
| Kategoriler | `/api/categories` | Menü kategori yönetimi |
| Masalar | `/api/tables` | Masa listeleme ve masa yönetimi |
| Siparişler | `/api/orders` | Masa siparişi oluşturma ve hesap kapatma |
| Paket Sipariş | `/api/package-orders` | Paket sipariş ve kurye süreci |
| Kuryeler | `/api/couriers` | Aktif kurye listesi ve kurye siparişleri |
| Finans | `/api/finance/summary` | Gelir-gider özetleri |
| Giderler | `/api/expenses` | Genel gider kayıtları |
| Malzeme Alım | `/api/material-purchases` | Malzeme alım işlemleri |
| Raporlama | `/api/reports/summary` | Satış ve kapanan hesap raporları |
| Kullanıcılar | `/api/users` | Kullanıcı yönetimi |
| Prim | `/api/commission/settings` | Garson ve kurye prim yönetimi |
| QR Menü | `/api/public-menu` | Müşteri QR menü ürünleri |
| Geri Bildirim | `/api/customer-feedback` | Müşteri geri bildirim işlemleri |
| Kafe Bilgileri | `/api/cafe-settings` | Kafe bilgisi, tema ve görünüm ayarları |
| Etkinlikler | `/api/cafe-events` | Kafe etkinlik yönetimi |

---

## 🧪 Test ve Kontrol

Backend veritabanı bağlantısını kontrol et:

```bash
curl http://localhost:3000/api/test-db
```

Flutter bağımlılıklarını ve analizini kontrol et:

```bash
cd frontend
flutter pub get
flutter analyze
```

---

## 🖼️ Görsel Yükleme Notları

Backend tarafında ürün ve kafe görselleri `uploads` klasörü altında saklanır:

```text
backend/uploads/products/
backend/uploads/cafe/
```

Desteklenen görsel türleri:

- `.jpg`
- `.jpeg`
- `.png`
- `.webp`

Güvenlik amacıyla çalıştırılabilir veya riskli uzantılar kabul edilmez.

---

## 📱 QR Menü Kullanımı

QR menü sayfası aşağıdaki rotalarla açılabilir:

```text
/menu
/qr-menu
```

Örnek masa parametresi ile kullanım:

```text
http://localhost:3000/#/menu?table=4
```

QR menü üzerinden müşteri:

- Ürünleri görüntüleyebilir
- Kafe bilgilerini görebilir
- Etkinlikleri takip edebilir
- Geri bildirim gönderebilir

---

## 🧩 Geliştirme Notları

- Frontend yalnızca `ApiService` üzerinden backend API kullanacak şekilde kurgulanmıştır.
- Arayüz metinleri Türkçedir.
- QR menü dikey/yatay görünüm ayarları korunmalıdır.
- Yönetici tarafından seçilen tema rengi QR menü ve ilgili ekranlarda kullanılmalıdır.
- Prim sistemi kapalıysa ilgili prim kartları kullanıcıya gösterilmemelidir.
- `.env`, `node_modules`, `build` ve geçici dosyalar GitHub'a yüklenmemelidir.

---

## 👨‍💻 Geliştirici

**Furkan Mehmet Salgın**

- GitHub: [@fmslgn](https://github.com/fmslgn)
- Repository: [kafe-otomasyonu](https://github.com/fmslgn/kafe-otomasyonu)

---

<div align="center">

### ⭐ Projeyi beğendiysen repoya yıldız verebilirsin.

</div>
