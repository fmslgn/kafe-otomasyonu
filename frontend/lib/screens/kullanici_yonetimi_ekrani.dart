// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

// Kullanıcı modelini kullanıyoruz.
// Kullanıcı yönetimi ekranında garson, yönetici ve kurye kullanıcıları listelenir.
import '../models/app_user_model.dart';

// Backend API servis dosyasını kullanıyoruz.
import '../services/api_service.dart';

import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';

// Yönetici panelinden açılan kullanıcı yönetimi ekranıdır.
// Yönetici bu ekranda garson, yönetici ve kurye kullanıcılarını görüntüler,
// yeni kullanıcı ekler, kullanıcı rolünü değiştirir, şifre günceller
// ve kullanıcıyı aktif/pasif hale getirir.
class KullaniciYonetimiEkrani extends StatefulWidget {
  // Constructor yapısıdır.
  const KullaniciYonetimiEkrani({super.key});

  @override
  State<KullaniciYonetimiEkrani> createState() =>
      _KullaniciYonetimiEkraniState();
}

// Kullanıcı yönetimi ekranındaki değişen verileri yöneten State sınıfıdır.
class _KullaniciYonetimiEkraniState extends State<KullaniciYonetimiEkrani>
    with CafeThemeScreenMixin {
  late Future<List<AppUserModel>> kullanicilarFuture;
  // Hangi kullanıcının şifresi görünür durumda (id -> true).
  final Map<int, bool> sifreGosteriliyor = {};
  // Rol filtre chipleri bölümü.
  String seciliRolFiltre = 'all';
  String seciliAktifFiltre = 'all';
  final TextEditingController aramaController = TextEditingController();
  String aramaMetni = '';

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();

    // Sayfa açıldığında kullanıcılar yüklenir.
    verileriYukle();
    aramaController.addListener(() {
      setState(() => aramaMetni = aramaController.text.trim());
    });
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    aramaController.dispose();
    super.dispose();
  }

  // Kullanıcı listesini backend API'den yükler.
  void verileriYukle() {
    kullanicilarFuture = ApiService.getUsers();
  }

  // Ekranı yeniler.
  void ekraniYenile() {
    setState(() {
      verileriYukle();
    });
  }

  List<Widget> _ustAksiyonlar(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Yenile',
        onPressed: ekraniYenile,
      ),
      FilledButton.icon(
        style: themedElevatedButtonStyle(theme),
        onPressed: kullaniciEklePenceresiAc,
        icon: const Icon(Icons.person_add, size: 20),
        label: const Text('Kullanıcı Ekle'),
      ),
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Geri Dön'),
      ),
    ];
  }

  List<AppUserModel> _kullanicilariFiltrele(List<AppUserModel> liste) {
    var sonuc = liste;

    if (seciliRolFiltre != 'all') {
      sonuc = sonuc.where((k) => k.role == seciliRolFiltre).toList();
    }

    if (seciliAktifFiltre == 'aktif') {
      sonuc = sonuc.where((k) => k.isActive).toList();
    } else if (seciliAktifFiltre == 'pasif') {
      sonuc = sonuc.where((k) => !k.isActive).toList();
    }

    if (aramaMetni.isNotEmpty) {
      final q = aramaMetni.toLowerCase();
      sonuc = sonuc.where((k) {
        return k.username.toLowerCase().contains(q) ||
            k.fullName.toLowerCase().contains(q) ||
            rolYazisi(k.role).toLowerCase().contains(q);
      }).toList();
    }

    return sonuc;
  }

  Widget _aktifFiltreChip(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: StitchFiltreChip(
        etiket: etiket,
        secili: seciliAktifFiltre == deger,
        temaRengi: theme.primary,
        onTap: () => setState(() => seciliAktifFiltre = deger),
      ),
    );
  }

  // Rol değerini Türkçe olarak gösterir.
  String rolYazisi(String role) {
    if (role == 'yonetici') {
      return 'Yönetici';
    }

    if (role == 'kurye') {
      return 'Kurye';
    }

    return 'Garson';
  }

  // Rol için ikon döndürür.
  IconData rolIkonu(String role) {
    if (role == 'yonetici') {
      return Icons.admin_panel_settings;
    }

    if (role == 'kurye') {
      return Icons.delivery_dining;
    }

    return Icons.room_service;
  }

  // Rol için renk döndürür.
  Color rolRengi(String role) {
    if (role == 'yonetici') {
      return Colors.purple;
    }

    if (role == 'kurye') {
      return Colors.blue;
    }

    return theme.primary;
  }

  // Kullanıcının oluşturulma tarihini formatlar.
  String tarihFormatla(String tarih) {
    try {
      final dateTime = DateTime.parse(tarih).toLocal();

      final gun = dateTime.day.toString().padLeft(2, '0');
      final ay = dateTime.month.toString().padLeft(2, '0');
      final yil = dateTime.year.toString();

      return '$gun.$ay.$yil';
    } catch (_) {
      if (tarih.contains('T')) {
        return tarih.split('T').first;
      }

      return tarih;
    }
  }

  // Yeni kullanıcı ekleme penceresini açar.
  Future<void> kullaniciEklePenceresiAc() async {
    final TextEditingController adSoyadController = TextEditingController();
    final TextEditingController kullaniciAdiController =
        TextEditingController();
    final TextEditingController sifreController = TextEditingController();

    String seciliRol = 'garson';
    bool sifreGizliMi = true;

    try {
      final sonuc = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Yeni Kullanıcı Ekle'),
                content: SizedBox(
                  width: 430,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ad soyad alanı.
                        TextField(
                          controller: adSoyadController,
                          decoration: const InputDecoration(
                            labelText: 'Ad Soyad',
                            hintText: 'Örn: Ahmet Yılmaz',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Kullanıcı adı alanı.
                        TextField(
                          controller: kullaniciAdiController,
                          decoration: const InputDecoration(
                            labelText: 'Kullanıcı Adı',
                            hintText: 'Örn: ahmet',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Şifre alanı.
                        TextField(
                          controller: sifreController,
                          obscureText: sifreGizliMi,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                sifreGizliMi
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  sifreGizliMi = !sifreGizliMi;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Rol seçimi.
                        DropdownButtonFormField<String>(
                          value: seciliRol,
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.manage_accounts),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'garson',
                              child: Text('Garson'),
                            ),
                            DropdownMenuItem(
                              value: 'yonetici',
                              child: Text('Yönetici'),
                            ),
                            DropdownMenuItem(
                              value: 'kurye',
                              child: Text('Kurye'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              seciliRol = value;
                            });
                          },
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Kurye rolü, paket sipariş teslimat sürecinde kullanılır.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Vazgeç'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Kaydet'),
                    onPressed: () async {
                      final adSoyad = adSoyadController.text.trim();
                      final kullaniciAdi =
                          kullaniciAdiController.text.trim();
                      final sifre = sifreController.text.trim();

                      if (adSoyad.isEmpty) {
                        showAppPopup(
                          context,
                          message: 'Ad soyad boş bırakılamaz.',
                          type: AppPopupType.warning,
                        );
                        return;
                      }

                      if (kullaniciAdi.isEmpty) {
                        showAppPopup(
                          context,
                          message: 'Kullanıcı adı boş bırakılamaz.',
                          type: AppPopupType.warning,
                        );
                        return;
                      }

                      if (sifre.isEmpty) {
                        showAppPopup(
                          context,
                          message: 'Şifre boş bırakılamaz.',
                          type: AppPopupType.warning,
                        );
                        return;
                      }

                      try {
                        final response = await ApiService.addUser(
                          fullName: adSoyad,
                          username: kullaniciAdi,
                          password: sifre,
                          role: seciliRol,
                        );

                        if (!mounted) return;

                        showAppPopup(
                          context,
                          message: response['message']?.toString() ??
                              'Kullanıcı başarıyla eklendi.',
                          type: AppPopupType.success,
                        );

                        Navigator.pop(dialogContext, true);
                      } catch (error) {
                        if (!mounted) return;

                        showAppPopup(
                          context,
                          message:
                              'Kullanıcı eklenemedi: ${ApiService.kullaniciHataMesaji(error)}',
                          type: AppPopupType.error,
                        );
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      );

      if (sonuc == true) {
        ekraniYenile();
      }
    } finally {
      adSoyadController.dispose();
      kullaniciAdiController.dispose();
      sifreController.dispose();
    }
  }

  // Kullanıcının rolünü değiştirme penceresini açar.
  Future<void> rolDegistirPenceresiAc(AppUserModel kullanici) async {
    String seciliRol = kullanici.role;

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rol Değiştir'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            rolRengi(kullanici.role).withOpacity(0.12),
                        foregroundColor: rolRengi(kullanici.role),
                        child: Icon(rolIkonu(kullanici.role)),
                      ),
                      title: Text(
                        kullanici.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Mevcut rol: ${rolYazisi(kullanici.role)}',
                      ),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: seciliRol,
                      decoration: const InputDecoration(
                        labelText: 'Yeni Rol',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.manage_accounts),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'garson',
                          child: Text('Garson'),
                        ),
                        DropdownMenuItem(
                          value: 'yonetici',
                          child: Text('Yönetici'),
                        ),
                        DropdownMenuItem(
                          value: 'kurye',
                          child: Text('Kurye'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          seciliRol = value;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Kurye rolü verilen kullanıcı, Kurye Girişi üzerinden kendi paketlerini görüntüleyebilir.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Kaydet'),
                  onPressed: () async {
                    try {
                      final response = await ApiService.updateUserRole(
                        userId: kullanici.id,
                        role: seciliRol,
                      );

                      if (!mounted) return;

                      showAppPopup(
                        context,
                        message: response['message']?.toString() ??
                            'Kullanıcı rolü güncellendi.',
                        type: AppPopupType.success,
                      );

                      Navigator.pop(dialogContext, true);
                    } catch (error) {
                      if (!mounted) return;

                      showAppPopup(
                        context,
                        message:
                            'Rol güncellenemedi: ${ApiService.kullaniciHataMesaji(error)}',
                        type: AppPopupType.error,
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (sonuc == true) {
      ekraniYenile();
    }
  }

  // Kullanıcının şifresini değiştirme penceresini açar.
  Future<void> sifreDegistirPenceresiAc(AppUserModel kullanici) async {
    final TextEditingController sifreController = TextEditingController();
    bool sifreGizliMi = true;
    // Dialog dışındaki ekran bağlamı; popup ve API sonrası işlemler için kullanılır.
    final ekranBaglami = context;

    try {
      final sonuc = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          // Dialog içi kayıt durumu; StatefulBuilder ile güncellenir.
          bool kaydediliyor = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Şifre Değiştir'),
                content: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.lock),
                        ),
                        title: Text(
                          kullanici.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Kullanıcı adı: ${kullanici.username}',
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: sifreController,
                        obscureText: sifreGizliMi,
                        decoration: InputDecoration(
                          labelText: 'Yeni Şifre',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(
                              sifreGizliMi
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                sifreGizliMi = !sifreGizliMi;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Vazgeç'),
                  ),
                  ElevatedButton.icon(
                    icon: kaydediliyor
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(kaydediliyor ? 'Kaydediliyor...' : 'Kaydet'),
                    onPressed: kaydediliyor
                        ? null
                        : () async {
                            final yeniSifre = sifreController.text.trim();

                            if (yeniSifre.isEmpty) {
                              showAppPopup(
                                ekranBaglami,
                                message: 'Yeni şifre boş bırakılamaz.',
                                type: AppPopupType.warning,
                              );
                              return;
                            }

                            if (yeniSifre.length < 3) {
                              showAppPopup(
                                ekranBaglami,
                                message: 'Şifre en az 3 karakter olmalıdır.',
                                type: AppPopupType.warning,
                              );
                              return;
                            }

                            setDialogState(() {
                              kaydediliyor = true;
                            });

                            try {
                              final response =
                                  await ApiService.updateUserPassword(
                                userId: kullanici.id,
                                password: yeniSifre,
                              );

                              if (!ekranBaglami.mounted) return;

                              showAppPopup(
                                ekranBaglami,
                                message: response['message']?.toString() ??
                                    'Kullanıcı şifresi başarıyla güncellendi.',
                                type: AppPopupType.success,
                              );

                              Navigator.pop(dialogContext, true);
                            } catch (error) {
                              if (!ekranBaglami.mounted) return;

                              showAppPopup(
                                ekranBaglami,
                                message:
                                    'Şifre güncellenemedi: ${ApiService.kullaniciHataMesaji(error)}',
                                type: AppPopupType.error,
                              );

                              setDialogState(() {
                                kaydediliyor = false;
                              });
                            }
                          },
                  ),
                ],
              );
            },
          );
        },
      );

      if (sonuc == true) {
        ekraniYenile();
      }
    } finally {
      sifreController.dispose();
    }
  }

  // Kullanıcının aktif/pasif durumunu değiştirir.
  Future<void> durumDegistir(AppUserModel kullanici) async {
    try {
      final response = await ApiService.updateUserStatus(
        userId: kullanici.id,
        isActive: !kullanici.isActive,
      );

      if (!mounted) return;

      showAppPopup(
        context,
        message: response['message']?.toString() ??
            'Kullanıcı durumu güncellendi.',
        type: AppPopupType.success,
      );

      ekraniYenile();
    } catch (error) {
      if (!mounted) return;

      showAppPopup(
        context,
        message:
            'Kullanıcı durumu güncellenemedi: ${ApiService.kullaniciHataMesaji(error)}',
        type: AppPopupType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return themedRoot(
      Scaffold(
        backgroundColor: AppThemeHelper.sayfaZemin,
        body: SafeArea(
          child: FutureBuilder<List<AppUserModel>>(
            future: kullanicilarFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingView(
                  mesaj: 'Kullanıcılar yükleniyor...',
                );
              }

              if (snapshot.hasError) {
                return AppErrorView(
                  hataDetayi: snapshot.error.toString(),
                  tekrarDene: ekraniYenile,
                );
              }

              final tumKullanicilar = snapshot.data ?? [];
              final filtrelenmis =
                  _kullanicilariFiltrele(tumKullanicilar);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sayfa başlığı/header bölümü.
                        PanelBaslikAlani(
                          baslik: 'Kullanıcı Yönetimi',
                          altBaslik:
                              'Garson, yönetici ve kurye kullanıcılarını buradan yönetin.',
                          tema: theme,
                          logoUrl: cafeLogoUrl,
                          aksiyonlar: _ustAksiyonlar(context),
                        ),
                        const SizedBox(height: 20),
                        if (tumKullanicilar.isNotEmpty) ...[
                          OzetKartSatiri(
                            kartlar: [
                              OzetKart(
                                baslik: 'Toplam Kullanıcı',
                                deger: '${tumKullanicilar.length}',
                                ikon: Icons.people,
                                tema: theme,
                              ),
                              OzetKart(
                                baslik: 'Aktif Kullanıcı',
                                deger:
                                    '${tumKullanicilar.where((k) => k.isActive).length}',
                                ikon: Icons.person_outline,
                                tema: theme,
                              ),
                              OzetKart(
                                baslik: 'Garson Sayısı',
                                deger:
                                    '${tumKullanicilar.where((k) => k.role == 'garson').length}',
                                ikon: Icons.room_service,
                                tema: theme,
                              ),
                              OzetKart(
                                baslik: 'Kurye Sayısı',
                                deger:
                                    '${tumKullanicilar.where((k) => k.role == 'kurye').length}',
                                ikon: Icons.delivery_dining,
                                tema: theme,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          StitchKart(
                            kenarlikRengi: theme.primary,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: aramaController,
                                  decoration: stitchInputDekorasyonu(
                                    hintText:
                                        'Kullanıcı adı, ad soyad veya rol ara...',
                                    prefixIcon: Icons.search,
                                    temaRengi: theme.primary,
                                    suffixIcon: aramaMetni.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () =>
                                                aramaController.clear(),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Rol',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: StitchFiltreChip(
                                          etiket: 'Tümü',
                                          secili: seciliRolFiltre == 'all',
                                          temaRengi: theme.primary,
                                          onTap: () => setState(
                                            () => seciliRolFiltre = 'all',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: StitchFiltreChip(
                                          etiket: 'Garson',
                                          secili:
                                              seciliRolFiltre == 'garson',
                                          temaRengi: theme.primary,
                                          onTap: () => setState(
                                            () => seciliRolFiltre = 'garson',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: StitchFiltreChip(
                                          etiket: 'Yönetici',
                                          secili:
                                              seciliRolFiltre == 'yonetici',
                                          temaRengi: theme.primary,
                                          onTap: () => setState(
                                            () =>
                                                seciliRolFiltre = 'yonetici',
                                          ),
                                        ),
                                      ),
                                      StitchFiltreChip(
                                        etiket: 'Kurye',
                                        secili: seciliRolFiltre == 'kurye',
                                        temaRengi: theme.primary,
                                        onTap: () => setState(
                                          () => seciliRolFiltre = 'kurye',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Durum',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _aktifFiltreChip('Tümü', 'all'),
                                      _aktifFiltreChip('Aktif', 'aktif'),
                                      _aktifFiltreChip('Pasif', 'pasif'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (tumKullanicilar.isEmpty)
                          const AppEmptyView(
                            ikon: Icons.people_outline,
                            baslik: 'Kullanıcı kaydı bulunmuyor.',
                            aciklama:
                                'Üstteki Kullanıcı Ekle ile yeni hesap oluşturabilirsiniz.',
                          )
                        else if (filtrelenmis.isEmpty)
                          const AppEmptyView(
                            baslik: 'Filtreye uygun kullanıcı bulunamadı.',
                            aciklama:
                                'Arama veya filtreleri değiştirerek tekrar deneyin.',
                          )
                        else
                          ...filtrelenmis.map(_kullaniciKarti),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Kullanıcı kartları bölümü.
  Widget _kullaniciKarti(AppUserModel kullanici) {
    return StitchKart(
      margin: const EdgeInsets.only(bottom: 12),
      kenarlikRengi: theme.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final darEkran = constraints.maxWidth < 720;
          final butonlar = Column(
            crossAxisAlignment:
                darEkran ? CrossAxisAlignment.stretch : CrossAxisAlignment.end,
            children: [
              AppTooltip(
                message: 'Kullanıcı bilgilerini düzenle',
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Düzenle'),
                  onPressed: () => rolDegistirPenceresiAc(kullanici),
                ),
              ),
              const SizedBox(height: 8),
              AppTooltip(
                message: 'Kullanıcı şifresini değiştir',
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Şifre Değiştir'),
                  onPressed: () => sifreDegistirPenceresiAc(kullanici),
                ),
              ),
              const SizedBox(height: 8),
              AppTooltip(
                message: kullanici.isActive
                    ? 'Kullanıcıyı pasif yap'
                    : 'Kullanıcıyı aktif yap',
                child: OutlinedButton.icon(
                  icon: Icon(
                    kullanici.isActive
                        ? Icons.person_off
                        : Icons.person_add_alt,
                  ),
                  label: Text(
                    kullanici.isActive ? 'Pasif Yap' : 'Aktif Yap',
                  ),
                  onPressed: () => durumDegistir(kullanici),
                ),
              ),
            ],
          );

          final bilgi = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    rolRengi(kullanici.role).withValues(alpha: 0.12),
                foregroundColor: rolRengi(kullanici.role),
                child: Icon(rolIkonu(kullanici.role), size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kullanici.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Kullanıcı adı: ${kullanici.username}'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StitchEtiket(
                          metin: rolYazisi(kullanici.role),
                          renk: rolRengi(kullanici.role),
                        ),
                        StitchEtiket(
                          metin: kullanici.isActive ? 'Aktif' : 'Pasif',
                          renk: kullanici.isActive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Mevcut Şifre: '),
                        Text(
                          sifreGosteriliyor[kullanici.id] == true
                              ? (kullanici.password ?? '—')
                              : '••••••',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        AppTooltip(
                          message: sifreGosteriliyor[kullanici.id] == true
                              ? 'Şifreyi gizle'
                              : 'Şifreyi göster',
                          child: IconButton(
                            icon: Icon(
                              sifreGosteriliyor[kullanici.id] == true
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                sifreGosteriliyor[kullanici.id] =
                                    !(sifreGosteriliyor[kullanici.id] ??
                                        false);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Kayıt tarihi: ${tarihFormatla(kullanici.createdAt)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (darEkran) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [bilgi, const SizedBox(height: 12), butonlar],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: bilgi),
              const SizedBox(width: 12),
              butonlar,
            ],
          );
        },
      ),
    );
  }
}