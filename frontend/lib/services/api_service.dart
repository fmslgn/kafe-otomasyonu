// JSON verilerini çevirmek için kullanıyoruz.
import 'dart:convert';

import 'package:flutter/foundation.dart';

// Dosya seçimi için kullanıyoruz (Flutter web uyumlu).
import 'package:file_picker/file_picker.dart';

// HTTP istekleri göndermek için kullanıyoruz.
import 'package:http/http.dart' as http;

// Multipart upload için doğru image content-type göndermek amacıyla kullanılır.
import 'package:http_parser/http_parser.dart';

// Aktif sipariş modelini kullanıyoruz.
// Hesap işlemleri ekranında açık hesapları listelemek için kullanılır.
import '../models/aktif_siparis_model.dart';

// Kullanıcı modelini kullanıyoruz.
import '../models/app_user_model.dart';

// Kapanan hesap modelini kullanıyoruz.
import '../models/closed_order_model.dart';

// Expense yani gider modelini kullanıyoruz.
import '../models/expense_model.dart';

// Birleşik gider kaydı modelini kullanıyoruz.
import '../models/expense_record_model.dart';

import '../models/commission_settings_model.dart';
import '../models/my_commission_report_model.dart';
import '../models/product_commission_rule_model.dart';
import '../models/waiter_commission_report_model.dart';
import '../models/courier_commission_report_model.dart';

// Finance summary yani gelir-gider özet modelini kullanıyoruz.
import '../models/finance_summary_model.dart';

// Garson satış raporu modelini kullanıyoruz.
import '../models/garson_satis_model.dart';

// Kategori modelini kullanıyoruz.
import '../models/kategori_model.dart';

// Masa modelini kullanıyoruz.
import '../models/masa_model.dart';

// Malzeme alım modelini kullanıyoruz.
import '../models/material_purchase_model.dart';

// Paket sipariş modelini kullanıyoruz.
import '../models/paket_siparis_model.dart';

// Rapor özet modelini kullanıyoruz.
import '../models/report_summary_model.dart';

// En çok satılan ürünler modelini kullanıyoruz.
import '../models/top_product_model.dart';

// Ürün modelini kullanıyoruz.
import '../models/urun_model.dart';
import '../models/customer_feedback_model.dart';
import '../models/cafe_event_model.dart';
import '../models/cafe_settings_model.dart';
import '../models/public_cafe_info_model.dart';

// Backend API ile haberleşecek servis sınıfıdır.
class ApiService {
  // Backend ana adresidir.
  static const String baseUrl = 'http://localhost:3000';

  // Ürün görsel yolunu tam erişilebilir URL'ye çevirir.
  // Relative path (/uploads/...) veya tam http/https URL desteklenir.
  static String getProductImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return '';
    }

    final temizUrl = imageUrl.trim();

    if (temizUrl.startsWith('http://') || temizUrl.startsWith('https://')) {
      return temizUrl;
    }

    if (temizUrl.startsWith('/')) {
      return '$baseUrl$temizUrl';
    }

    return '$baseUrl/$temizUrl';
  }

  // Kullanıcı giriş işlemini backend API üzerinden yapan fonksiyondur.
  static Future<AppUserModel> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return AppUserModel.fromJson(jsonResponse['user']);
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Giriş yapılırken hata oluştu.',
      );
    }
  }

  // Ürünleri backend API'den çeken fonksiyondur.
  static Future<List<UrunModel>> getProducts() async {
    final url = Uri.parse('$baseUrl/api/products');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList.map((json) => UrunModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Ürünler getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Kategorileri backend API'den çeken fonksiyondur.
  static Future<List<KategoriModel>> getCategories() async {
    final url = Uri.parse('$baseUrl/api/categories');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList.map((json) => KategoriModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Kategoriler getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Yeni kategori ekleyen fonksiyondur.
  static Future<Map<String, dynamic>> addCategory({
    required String name,
  }) async {
    final url = Uri.parse('$baseUrl/api/categories');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Kategori eklenirken hata oluştu.',
      );
    }
  }

  // Müşteri QR menüsü için giriş gerektirmeyen ürün listesini çeker.
  static Future<List<UrunModel>> getPublicMenuProducts() async {
    final url = Uri.parse('$baseUrl/api/public-menu');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList.map((json) => UrunModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Public menü getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Yeni ürün ekleyen fonksiyondur.
  // description, imageUrl ve isVisible opsiyoneldir; eski çağrılar bozulmaz.
  static Future<Map<String, dynamic>> addProduct({
    required String name,
    required double price,
    required int categoryId,
    String? description,
    String? imageUrl,
    bool isVisible = true,
  }) async {
    final url = Uri.parse('$baseUrl/api/products');

    final Map<String, dynamic> body = {
      'name': name,
      'price': price,
      'categoryId': categoryId,
    };

    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      body['imageUrl'] = imageUrl.trim();
    }

    body['isVisible'] = isVisible;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Ürün eklenirken hata oluştu.',
      );
    }
  }

  // Yönetici ürün güncelleme fonksiyonudur.
  // imageUrl gönderilmez; mevcut görsel upload endpoint ile yönetilir.
  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String name,
    required double price,
    required int categoryId,
    String? description,
    bool isVisible = true,
    bool isActive = true,
  }) async {
    final url = Uri.parse('$baseUrl/api/products/$productId');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'price': price,
        'categoryId': categoryId,
        'description': description?.trim() ?? '',
        'isVisible': isVisible,
        'isActive': isActive,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Ürün güncellenirken hata oluştu.',
      );
    }
  }

  // Dosya adına göre multipart için doğru image MediaType üretir.
  static MediaType gorselMediaTypeAl(String fileName) {
    final noktaIndex = fileName.lastIndexOf('.');

    if (noktaIndex == -1 || noktaIndex >= fileName.length - 1) {
      throw Exception('Sadece JPEG, PNG veya WEBP görselleri yüklenebilir.');
    }

    final uzanti = fileName.substring(noktaIndex + 1).toLowerCase();

    if (uzanti == 'jpg' || uzanti == 'jpeg') {
      return MediaType('image', 'jpeg');
    }

    if (uzanti == 'png') {
      return MediaType('image', 'png');
    }

    if (uzanti == 'webp') {
      return MediaType('image', 'webp');
    }

    throw Exception('Sadece JPEG, PNG veya WEBP görselleri yüklenebilir.');
  }

  // Exception veya backend hata metnini kullanıcıya gösterilebilir hale getirir.
  static String kullaniciHataMesaji(Object error) {
    final mesaj = error.toString();

    if (mesaj.startsWith('Exception: ')) {
      return mesaj.substring('Exception: '.length);
    }

    return mesaj;
  }

  // Ürün görseli yükler (multipart/form-data, field: image).
  // Flutter Web için file.bytes zorunludur; withData: true ile seçilmelidir.
  static Future<Map<String, dynamic>> uploadProductImage({
    required int productId,
    required PlatformFile file,
  }) async {
    if (file.bytes == null) {
      throw Exception('Dosya okunamadı.');
    }

    final dosyaAdi =
        file.name.isNotEmpty ? file.name : 'urun_gorsel.png';
    final contentType = gorselMediaTypeAl(dosyaAdi);

    final url = Uri.parse('$baseUrl/api/products/$productId/image');
    final request = http.MultipartRequest('POST', url);

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        file.bytes!,
        filename: dosyaAdi,
        contentType: contentType,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ??
            jsonResponse['error'] ??
            'Görsel yüklenemedi.',
      );
    }
  }

  // Ürün görselini kaldırır.
  static Future<Map<String, dynamic>> deleteProductImage({
    required int productId,
  }) async {
    final url = Uri.parse('$baseUrl/api/products/$productId/image');

    final response = await http.delete(url);
    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Ürün görseli kaldırılamadı.',
      );
    }
  }

  // Masaları backend API'den çeken fonksiyondur.
  static Future<List<MasaModel>> getTables() async {
    final url = Uri.parse('$baseUrl/api/tables');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList.map((json) => MasaModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Masalar getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Yeni masa ekleyen fonksiyondur.
  static Future<Map<String, dynamic>> addTable({
    required int tableNo,
    required String section,
  }) async {
    final url = Uri.parse('$baseUrl/api/tables');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tableNo': tableNo,
        'section': section,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Masa eklenirken hata oluştu.',
      );
    }
  }

  // Masayı silen fonksiyondur.
  static Future<Map<String, dynamic>> deleteTable({
    required int tableId,
  }) async {
    final url = Uri.parse('$baseUrl/api/tables/$tableId');

    final response = await http.delete(url);

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Masa silinirken hata oluştu.',
      );
    }
  }

  // Masanın bölümünü/kategorisini güncelleyen fonksiyondur.
  static Future<Map<String, dynamic>> updateTableSection({
    required int tableId,
    required String section,
  }) async {
    final url = Uri.parse('$baseUrl/api/tables/$tableId/section');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'section': section,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Masa bölümü güncellenemedi.',
      );
    }
  }

  // Seçilen masanın aktif siparişini backend API'den çeker.
  // Bu veri içinde masa sipariş notu da döner.
  static Future<Map<String, dynamic>?> getActiveOrder(int tableNo) async {
    final url = Uri.parse('$baseUrl/api/orders/active/$tableNo');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

      return jsonResponse['order'];
    } else {
      throw Exception(
        'Aktif sipariş getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Aktif siparişleri backend API'den çeken fonksiyondur.
  static Future<List<AktifSiparisModel>> getActiveOrders() async {
    final url = Uri.parse('$baseUrl/api/orders/active');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList.map((json) => AktifSiparisModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Aktif siparişler getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Masa siparişi oluşturma veya aktif siparişi güncelleme fonksiyonudur.
  // note alanı masa sipariş notunu backend'e gönderir.
  static Future<Map<String, dynamic>> createOrder({
    required int tableNo,
    required int userId,
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    final url = Uri.parse('$baseUrl/api/orders');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tableNo': tableNo,
        'userId': userId,
        'items': items,
        'note': note,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Sipariş kaydedilirken hata oluştu.',
      );
    }
  }

  // Hesap kapatma fonksiyonudur.
  static Future<Map<String, dynamic>> closeOrder(int orderId) async {
    final url = Uri.parse('$baseUrl/api/orders/$orderId/close');

    final response = await http.put(url);

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Hesap kapatılırken hata oluştu.',
      );
    }
  }

  // Aktif kurye kullanıcılarını backend API'den çeker.
  static Future<List<AppUserModel>> getCouriers() async {
    final url = Uri.parse('$baseUrl/api/couriers');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList.map((json) => AppUserModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Kuryeler getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Aktif paket siparişleri backend API'den çeker.
  static Future<List<PaketSiparisModel>> getActivePackageOrders() async {
    final url = Uri.parse('$baseUrl/api/package-orders/active');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList
          .map((json) => PaketSiparisModel.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Aktif paket siparişler getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Paket siparişleri backend API'den çeker.
  // status: all, aktif, kapandi, iptal değerlerini alabilir.
  static Future<List<PaketSiparisModel>> getPackageOrders({
    String status = 'all',
  }) async {
    final url = Uri.parse('$baseUrl/api/package-orders?status=$status');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList
          .map((json) => PaketSiparisModel.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Paket siparişler getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Giriş yapan kuryeye atanmış aktif paket siparişleri getirir.
  static Future<List<PaketSiparisModel>> getCourierPackageOrders({
    required int courierId,
  }) async {
    final url = Uri.parse('$baseUrl/api/couriers/$courierId/package-orders');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final dynamic decoded = jsonDecode(decodedBody);

      if (decoded is! List) {
        throw Exception(
          'Kurye paketleri beklenmeyen formatta geldi.',
        );
      }

      final List<PaketSiparisModel> paketler = [];

      for (final ham in decoded) {
        if (ham is! Map) continue;
        try {
          paketler.add(
            PaketSiparisModel.fromJson(Map<String, dynamic>.from(ham)),
          );
        } catch (e) {
          // Tek kayıt bozuksa tüm listeyi düşürme; geçersiz kaydı atla.
          debugPrint('Kurye paketi parse atlandı: $e');
          continue;
        }
      }

      return paketler;
    } else {
      throw Exception(
        'Kurye paketleri getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Yeni paket sipariş oluşturur.
  static Future<Map<String, dynamic>> createPackageOrder({
    required int userId,
    required List<Map<String, dynamic>> items,
    String? customerName,
    String? customerPhone,
    String? address,
    String? note,
  }) async {
    final url = Uri.parse('$baseUrl/api/package-orders');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'address': address,
        'note': note,
        'items': items,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Paket sipariş kaydedilirken hata oluştu.',
      );
    }
  }

  // Paket siparişe kurye atar.
  static Future<Map<String, dynamic>> assignCourierToPackageOrder({
    required int packageOrderId,
    required int courierId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/package-orders/$packageOrderId/assign-courier',
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'courierId': courierId,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Kurye ataması yapılırken hata oluştu.',
      );
    }
  }

  // Paket sipariş teslimat durumunu günceller.
  // deliveryStatus: bekliyor, kuryeye_atandi, yolda, teslim_edildi, iptal.
  static Future<Map<String, dynamic>> updatePackageDeliveryStatus({
    required int packageOrderId,
    required String deliveryStatus,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/package-orders/$packageOrderId/delivery-status',
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'deliveryStatus': deliveryStatus,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ??
            'Paket teslimat durumu güncellenirken hata oluştu.',
      );
    }
  }

  // Paket siparişi tamamlar.
  static Future<Map<String, dynamic>> closePackageOrder({
    required int packageOrderId,
  }) async {
    final url = Uri.parse('$baseUrl/api/package-orders/$packageOrderId/close');

    final response = await http.put(url);

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Paket sipariş tamamlanırken hata oluştu.',
      );
    }
  }

  // Paket siparişi iptal eder.
  static Future<Map<String, dynamic>> cancelPackageOrder({
    required int packageOrderId,
  }) async {
    final url = Uri.parse('$baseUrl/api/package-orders/$packageOrderId/cancel');

    final response = await http.put(url);

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Paket sipariş iptal edilirken hata oluştu.',
      );
    }
  }

  // Gelir-gider özetini backend API'den çeken fonksiyondur.
  static Future<FinanceSummaryModel> getFinanceSummary({
    String period = 'all',
  }) async {
    final url = Uri.parse('$baseUrl/api/finance/summary?period=$period');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

      return FinanceSummaryModel.fromJson(jsonResponse);
    } else {
      throw Exception(
        'Gelir-gider özeti getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Genel giderler + malzeme alımlarını birleşik listeler (Gelir-Gider ekranı).
  static Future<List<ExpenseRecordModel>> getFinanceExpenseRecords({
    String period = 'all',
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/finance/expense-records?period=$period',
    );

    final response = await http.get(url);
    final String decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(decodedBody);
      return jsonList
          .map((json) => ExpenseRecordModel.fromJson(json))
          .toList();
    }

    final Map<String, dynamic>? jsonResponse =
        decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;

    throw Exception(
      jsonResponse?['message'] ??
          'Gider kayıtları getirilemedi. Hata kodu: ${response.statusCode}',
    );
  }

  // Giderleri backend API'den çeken fonksiyondur.
  static Future<List<ExpenseModel>> getExpenses({
    String period = 'all',
  }) async {
    final url = Uri.parse('$baseUrl/api/expenses?period=$period');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList.map((json) => ExpenseModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Giderler getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Yeni gider ekleyen fonksiyondur.
  static Future<Map<String, dynamic>> addExpense({
    required String title,
    required double amount,
    String? description,
  }) async {
    final url = Uri.parse('$baseUrl/api/expenses');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'amount': amount,
        'description': description,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Gider eklenirken hata oluştu.',
      );
    }
  }

  // Malzeme alım kayıtlarını listeler.
  static Future<List<MaterialPurchaseModel>> getMaterialPurchases({
    String period = 'all',
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/material-purchases?period=$period',
    );

    final response = await http.get(url);
    final String decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(decodedBody);
      return jsonList
          .map((json) => MaterialPurchaseModel.fromJson(json))
          .toList();
    }

    final Map<String, dynamic>? jsonResponse =
        decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;

    throw Exception(
      jsonResponse?['message'] ??
          'Malzeme alım kayıtları getirilemedi. Hata kodu: ${response.statusCode}',
    );
  }

  // Yeni malzeme alım kaydı ekler.
  static Future<Map<String, dynamic>> addMaterialPurchase({
    required String itemName,
    required double quantity,
    required String unit,
    required double unitPrice,
    String? description,
    String? purchaseDate,
  }) async {
    final url = Uri.parse('$baseUrl/api/material-purchases');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'itemName': itemName,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'description': description,
        'purchaseDate': purchaseDate,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonResponse;
    }

    throw Exception(
      jsonResponse['message'] ?? 'Malzeme alım kaydı eklenirken hata oluştu.',
    );
  }

  // Malzeme alım kaydını siler.
  static Future<Map<String, dynamic>> deleteMaterialPurchase({
    required int id,
  }) async {
    final url = Uri.parse('$baseUrl/api/material-purchases/$id');

    final response = await http.delete(url);
    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    }

    throw Exception(
      jsonResponse['message'] ?? 'Malzeme alım kaydı silinirken hata oluştu.',
    );
  }

  // Rapor özetini backend API'den çeken fonksiyondur.
  static Future<ReportSummaryModel> getReportSummary({
    String period = 'all',
  }) async {
    final url = Uri.parse('$baseUrl/api/reports/summary?period=$period');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

      return ReportSummaryModel.fromJson(jsonResponse);
    } else {
      throw Exception(
        'Rapor özeti getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // En çok satılan ürünleri backend API'den çeken fonksiyondur.
  static Future<List<TopProductModel>> getTopProducts({
    String period = 'all',
  }) async {
    final url = Uri.parse('$baseUrl/api/reports/top-products?period=$period');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList.map((json) => TopProductModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'En çok satılan ürünler getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Kapanan hesapları backend API'den çeken fonksiyondur.
  static Future<List<ClosedOrderModel>> getClosedOrders({
    String period = 'all',
  }) async {
    final url = Uri.parse('$baseUrl/api/reports/closed-orders?period=$period');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList.map((json) => ClosedOrderModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Kapanan hesaplar getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Kullanıcıları backend API'den çeken fonksiyondur.
  static Future<List<AppUserModel>> getUsers() async {
    final url = Uri.parse('$baseUrl/api/users');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList.map((json) => AppUserModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Kullanıcılar getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Yeni kullanıcı ekleyen fonksiyondur.
  // role alanı garson, yonetici veya kurye olabilir.
  static Future<Map<String, dynamic>> addUser({
    required String fullName,
    required String username,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/api/users');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fullName': fullName,
        'username': username,
        'password': password,
        'role': role,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Kullanıcı eklenirken hata oluştu.',
      );
    }
  }

  // Kullanıcının aktif/pasif durumunu değiştiren fonksiyondur.
  static Future<Map<String, dynamic>> updateUserStatus({
    required int userId,
    required bool isActive,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/status');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'isActive': isActive,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Kullanıcı durumu güncellenemedi.',
      );
    }
  }

  // Kullanıcının rolünü güncelleyen fonksiyondur.
  // role alanı garson, yonetici veya kurye olabilir.
  static Future<Map<String, dynamic>> updateUserRole({
    required int userId,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/role');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'role': role,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Kullanıcı rolü güncellenemedi.',
      );
    }
  }

  // Kullanıcının kendi şifresini değiştiren fonksiyondur.
  static Future<Map<String, dynamic>> changeOwnPassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/change-own-password');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse;
    }

    throw Exception(
      jsonResponse['message']?.toString() ?? 'Şifre güncellenemedi.',
    );
  }

  // Yönetici: kullanıcı şifresini değiştiren fonksiyondur.
  static Future<Map<String, dynamic>> updateUserPassword({
    required int userId,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$userId/password');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'password': password,
      }),
    );

    final String decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['message']?.toString() ?? 'Şifre güncellenemedi.',
      );
    }
  }

  // Garsonların/yöneticilerin/kuryelerin satış raporunu backend API'den çeker.
  static Future<List<GarsonSatisModel>> getUserSalesReport({
    String period = 'all',
  }) async {
    final url = Uri.parse('$baseUrl/api/users/sales-report?period=$period');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final List<dynamic> jsonList = jsonDecode(decodedBody);

      return jsonList
          .map((json) => GarsonSatisModel.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Kullanıcı satış raporu getirilemedi. Hata kodu: ${response.statusCode}',
      );
    }
  }

  // Prim sistemi ayarlarını getirir.
  static Future<CommissionSettingsModel> getCommissionSettings() async {
    final url = Uri.parse('$baseUrl/api/commission/settings');
    final response = await http.get(url);
    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return CommissionSettingsModel.fromJson(jsonDecode(decodedBody));
    }

    final jsonResponse =
        decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;
    throw Exception(
      jsonResponse?['message'] ?? 'Prim ayarları getirilemedi.',
    );
  }

  // Prim sistemi ayarlarını günceller.
  static Future<CommissionSettingsModel> updateCommissionSettings({
    required bool isEnabled,
    required double defaultRate,
    required double employeeOfMonthBonus,
    required bool courierCommissionEnabled,
    required double courierDefaultRate,
    required double courierDeliveryBonus,
  }) async {
    final url = Uri.parse('$baseUrl/api/commission/settings');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'isEnabled': isEnabled,
        'defaultRate': defaultRate,
        'employeeOfMonthBonus': employeeOfMonthBonus,
        'courierCommissionEnabled': courierCommissionEnabled,
        'courierDefaultRate': courierDefaultRate,
        'courierDeliveryBonus': courierDeliveryBonus,
      }),
    );

    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return CommissionSettingsModel.fromJson(jsonResponse);
    }

    throw Exception(jsonResponse['message'] ?? 'Prim ayarları güncellenemedi.');
  }

  // Ürün prim kurallarını listeler.
  static Future<List<ProductCommissionRuleModel>> getProductCommissionRules() async {
    final url = Uri.parse('$baseUrl/api/commission/product-rules');
    final response = await http.get(url);
    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final liste = jsonDecode(decodedBody) as List<dynamic>;
      return liste.map((e) => ProductCommissionRuleModel.fromJson(e)).toList();
    }

    final jsonResponse =
        decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;
    throw Exception(
      jsonResponse?['message'] ?? 'Ürün prim kuralları getirilemedi.',
    );
  }

  static Future<Map<String, dynamic>> addProductCommissionRule({
    required int productId,
    required double targetQuantity,
    required double bonusAmount,
    required bool isActive,
  }) async {
    final url = Uri.parse('$baseUrl/api/commission/product-rules');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'productId': productId,
        'targetQuantity': targetQuantity,
        'bonusAmount': bonusAmount,
        'isActive': isActive,
      }),
    );

    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonResponse;
    }

    throw Exception(jsonResponse['message'] ?? 'Kural eklenemedi.');
  }

  static Future<Map<String, dynamic>> updateProductCommissionRule({
    required int ruleId,
    required int productId,
    required double targetQuantity,
    required double bonusAmount,
    required bool isActive,
  }) async {
    final url = Uri.parse('$baseUrl/api/commission/product-rules/$ruleId');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'productId': productId,
        'targetQuantity': targetQuantity,
        'bonusAmount': bonusAmount,
        'isActive': isActive,
      }),
    );

    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    }

    throw Exception(jsonResponse['message'] ?? 'Kural güncellenemedi.');
  }

  static Future<Map<String, dynamic>> deleteProductCommissionRule({
    required int ruleId,
  }) async {
    final url = Uri.parse('$baseUrl/api/commission/product-rules/$ruleId');
    final response = await http.delete(url);
    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    }

    throw Exception(jsonResponse['message'] ?? 'Kural silinemedi.');
  }

  // Yönetici garson prim raporu.
  static Future<WaiterCommissionReportResponse> getWaiterCommissionReport({
    String period = 'monthly',
  }) async {
    final url =
        Uri.parse('$baseUrl/api/commission/waiter-report?period=$period');
    final response = await http.get(url);
    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return WaiterCommissionReportResponse.fromJson(jsonDecode(decodedBody));
    }

    final jsonResponse =
        decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;
    throw Exception(
      jsonResponse?['message'] ?? 'Garson prim raporu getirilemedi.',
    );
  }

  // Garsonun kendi prim raporu (ayın elemanı primi dönmez).
  static Future<MyCommissionReportModel> getMyCommissionReport({
    required int userId,
    String period = 'monthly',
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/commission/my-report/$userId?period=$period',
    );
    final response = await http.get(url);
    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return MyCommissionReportModel.fromJson(jsonDecode(decodedBody));
    }

    final jsonResponse =
        decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;
    throw Exception(
      jsonResponse?['message'] ?? 'Prim raporunuz getirilemedi.',
    );
  }

  // Yönetici kurye prim raporu.
  static Future<CourierCommissionReportResponse> getCourierCommissionReport({
    String period = 'monthly',
  }) async {
    final url =
        Uri.parse('$baseUrl/api/commission/courier-report?period=$period');
    final response = await http.get(url);
    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return CourierCommissionReportResponse.fromJson(jsonDecode(decodedBody));
    }

    final jsonResponse =
        decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;
    throw Exception(
      jsonResponse?['message'] ?? 'Kurye prim raporu getirilemedi.',
    );
  }

  // Kuryenin kendi prim raporu.
  static Future<MyCourierCommissionReportModel> getMyCourierCommissionReport({
    required int userId,
    String period = 'monthly',
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/commission/my-courier-report/$userId?period=$period',
    );
    final response = await http.get(url);
    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return MyCourierCommissionReportModel.fromJson(jsonDecode(decodedBody));
    }

    final jsonResponse =
        decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;
    throw Exception(
      jsonResponse?['message'] ?? 'Kurye prim raporunuz getirilemedi.',
    );
  }

  // Müşteri QR menüden geri bildirim gönderir (giriş gerekmez).
  static Future<Map<String, dynamic>> submitCustomerFeedback({
    required String feedbackType,
    String? customerName,
    String? customerPhone,
    int? tableNumber,
    required String message,
  }) async {
    final url = Uri.parse('$baseUrl/api/customer-feedback');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'feedbackType': feedbackType,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'tableNumber': tableNumber,
        'message': message,
      }),
    );

    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonResponse;
    }

    throw Exception(
      jsonResponse['message']?.toString() ?? 'Mesaj gönderilemedi.',
    );
  }

  // Yönetici: müşteri geri bildirimlerini listeler.
  static Future<List<CustomerFeedbackModel>> getCustomerFeedback({
    String status = 'all',
    String type = 'all',
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/customer-feedback?status=$status&type=$type',
    );
    final response = await http.get(url);
    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final liste = jsonDecode(decodedBody) as List<dynamic>;
      return liste
          .map((e) => CustomerFeedbackModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final jsonResponse =
        decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;
    throw Exception(
      jsonResponse?['message']?.toString() ??
          'Geri bildirimler getirilemedi.',
    );
  }

  // Yönetici: geri bildirim durumunu günceller.
  static Future<Map<String, dynamic>> updateCustomerFeedback({
    required int id,
    required String status,
    String? managerNote,
  }) async {
    final url = Uri.parse('$baseUrl/api/customer-feedback/$id');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'status': status,
        'managerNote': managerNote,
      }),
    );

    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    }

    throw Exception(
      jsonResponse['message']?.toString() ?? 'Geri bildirim güncellenemedi.',
    );
  }

  // Yönetici: geri bildirimi siler.
  static Future<Map<String, dynamic>> deleteCustomerFeedback({
    required int id,
  }) async {
    final url = Uri.parse('$baseUrl/api/customer-feedback/$id');
    final response = await http.delete(url);
    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    }

    throw Exception(
      jsonResponse['message']?.toString() ?? 'Geri bildirim silinemedi.',
    );
  }

  // QR menü: public kafe bilgisi ve aktif etkinlikler.
  static Future<PublicCafeInfoModel> getPublicCafeInfo() async {
    final url = Uri.parse('$baseUrl/api/public-cafe-info');
    final response = await http.get(url);
    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return PublicCafeInfoModel.fromJson(jsonDecode(decodedBody));
    }

    final jsonResponse =
        decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;
    throw Exception(
      jsonResponse?['message']?.toString() ?? 'Kafe bilgileri getirilemedi.',
    );
  }

  static Future<CafeSettingsModel> getCafeSettings() async {
    final url = Uri.parse('$baseUrl/api/cafe-settings');
    final response = await http.get(url);
    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return CafeSettingsModel.fromJson(jsonDecode(decodedBody));
    }

    final jsonResponse =
        decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;
    throw Exception(
      jsonResponse?['message']?.toString() ?? 'Kafe ayarları getirilemedi.',
    );
  }

  static Future<CafeSettingsModel> updateCafeSettings({
    required String cafeName,
    String? openingHours,
    String? address,
    String? phone,
    String? mapUrl,
    String? instagramUrl,
    required bool isOpen,
    required String themeKey,
    required String primaryColor,
    required String menuLayout,
  }) async {
    final url = Uri.parse('$baseUrl/api/cafe-settings');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'cafeName': cafeName,
        'openingHours': openingHours,
        'address': address,
        'phone': phone,
        'mapUrl': mapUrl,
        'instagramUrl': instagramUrl,
        'isOpen': isOpen,
        'themeKey': themeKey,
        'primaryColor': primaryColor,
        'menuLayout': menuLayout,
      }),
    );

    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return CafeSettingsModel.fromJson(
        jsonResponse['settings'] as Map<String, dynamic>,
      );
    }

    throw Exception(
      jsonResponse['message']?.toString() ?? 'Kafe ayarları güncellenemedi.',
    );
  }

  static Future<List<CafeEventModel>> getCafeEvents() async {
    final url = Uri.parse('$baseUrl/api/cafe-events');
    final response = await http.get(url);
    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final liste = jsonDecode(decodedBody) as List<dynamic>;
      return liste
          .map((e) => CafeEventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final jsonResponse =
        decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;
    throw Exception(
      jsonResponse?['message']?.toString() ?? 'Etkinlikler getirilemedi.',
    );
  }

  static Future<Map<String, dynamic>> addCafeEvent({
    required String title,
    String? description,
    String? eventDate,
    required bool isActive,
  }) async {
    final url = Uri.parse('$baseUrl/api/cafe-events');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'eventDate': eventDate,
        'isActive': isActive,
      }),
    );

    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonResponse;
    }

    throw Exception(
      jsonResponse['message']?.toString() ?? 'Etkinlik eklenemedi.',
    );
  }

  static Future<Map<String, dynamic>> updateCafeEvent({
    required int id,
    required String title,
    String? description,
    String? eventDate,
    required bool isActive,
  }) async {
    final url = Uri.parse('$baseUrl/api/cafe-events/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'eventDate': eventDate,
        'isActive': isActive,
      }),
    );

    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    }

    throw Exception(
      jsonResponse['message']?.toString() ?? 'Etkinlik güncellenemedi.',
    );
  }

  static Future<Map<String, dynamic>> deleteCafeEvent({
    required int id,
  }) async {
    final url = Uri.parse('$baseUrl/api/cafe-events/$id');
    final response = await http.delete(url);
    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    }

    throw Exception(
      jsonResponse['message']?.toString() ?? 'Etkinlik silinemedi.',
    );
  }

  // Kafe logosu tam URL (ürün görseli ile aynı mantık).
  static String getCafeLogoUrl(String? logoUrl) => getProductImageUrl(logoUrl);

  // Kafe logosu yükler (multipart/form-data, field: logo).
  static Future<Map<String, dynamic>> uploadCafeLogo({
    required PlatformFile file,
  }) async {
    if (file.bytes == null) {
      throw Exception('Dosya okunamadı.');
    }

    final dosyaAdi = file.name.isNotEmpty ? file.name : 'cafe_logo.png';
    final contentType = gorselMediaTypeAl(dosyaAdi);

    final url = Uri.parse('$baseUrl/api/cafe-settings/logo');
    final request = http.MultipartRequest('POST', url);

    request.files.add(
      http.MultipartFile.fromBytes(
        'logo',
        file.bytes!,
        filename: dosyaAdi,
        contentType: contentType,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    }

    throw Exception(
      jsonResponse['message']?.toString() ?? 'Logo yüklenemedi.',
    );
  }

  // Kafe logosunu kaldırır.
  static Future<Map<String, dynamic>> deleteCafeLogo() async {
    final url = Uri.parse('$baseUrl/api/cafe-settings/logo');
    final response = await http.delete(url);
    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);

    if (response.statusCode == 200) {
      return jsonResponse;
    }

    throw Exception(
      jsonResponse['message']?.toString() ?? 'Logo kaldırılamadı.',
    );
  }
}