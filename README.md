# Modern Kafe Otomasyonu

Bu proje; Flutter frontend, Node.js backend ve PostgreSQL veritabanı kullanılarak geliştirilen modern bir kafe otomasyonu uygulamasıdır.

## Özellikler

- Rol bazlı giriş sistemi
- Garson paneli
- Yönetici paneli
- Kurye paneli
- Masa siparişi oluşturma
- Paket sipariş oluşturma
- Kurye teslimat takibi
- QR menü
- Müşteri geri bildirimleri
- Gelir-gider takibi
- Malzeme alım işlemleri
- Raporlama
- Personel prim yönetimi

## Kullanılan Teknolojiler

- Flutter
- Node.js
- PostgreSQL

## Kurulum

Backend için:

```bash
cd backend
npm install
```

Frontend için:

```bash
cd frontend
flutter pub get
```

Veritabanı için PostgreSQL kurulmalı ve proje veritabanı oluşturulmalıdır.

`.env.example` dosyası örnek alınarak backend içinde `.env` dosyası oluşturulmalıdır.

## Not

`.env`, `node_modules`, `build` ve geçici dosyalar GitHub'a yüklenmemelidir.
