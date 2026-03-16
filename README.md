# ABAP Geliştirme Reposu 

Bu depo, SAP ABAP ortamında geliştirdiğim raporları, form tasarımlarını, interaktif ekran (dialog) programlamalarını ve veritabanı performans çalışmalarını içermektedir. Kodlar, SAP sistemleri ile GitHub arasında versiyon kontrolü sağlamak amacıyla **abapGit** kullanılarak aktarılmıştır.

Aşağıdaki projeler ve modüller, **Fiks Bilişim** bünyesindeki ürün geliştirme süreçlerinde (Şubat - Haziran 2026) edindiğim profesyonel iş senaryoları pratiğine dayanmaktadır.

## Proje Yapısı

Kodlar standart abapGit dizin hiyerarşisine uygun olarak `src/` klasörü altında modüler olarak ayrılmıştır:

* **`zgz_dat/`**: Veri tanımlamaları (Data definitions) ve global değişkenler
* **`zgz_inc/`**: Include programları ve alt rutinler
* **`zgz_prg/`**: Ana çalıştırılabilir (Executable) programlar ve modül havuzları

## Geliştirilen Projeler ve Teknik Kazanımlar

### 1. Çıktı Yönetimi ve Form Tasarımı (Smart Forms & Adobe Forms)
Fatura, irsaliye ve belge dökümleri için uçtan uca çıktı yönetimi kurgulanmıştır.
* **Smart Forms Entegrasyonu (`zgz_sf_001`):** ALV üzerinden seçilen (Checkbox/SELKZ) belgelerin detayları dinamik olarak formlara aktarılmıştır (`SSF_FUNCTION_MODULE_NAME`). Forma logo, dinamik metinler ve adres bilgileri (`FOR ALL ENTRIES` ile ADRC, TVKO tablolardan) basılmıştır.
* **Performanslı Yazdırma (Spooling):** `SSF_OPEN` ve `SSF_CLOSE` fonksiyonları ile seri yazdırma işlemleri tek bir spool dosyasında birleştirilerek yazıcı performansı optimize edilmiştir.
* **Adobe Forms - IFbA (`zgz_adobe`):** `SFP` işlem kodu ve LiveCycle Designer kullanılarak modern arayüz (interface) ve tasarımları yapılmış, barkod/QR kod entegrasyonları kurgulanmıştır.
* **Finansal Fonksiyonlar:** Belge tutarları `SPELL_AMOUNT` fonksiyonu ile kuruş (KR/Cent) hassasiyetinde dinamik olarak yazıya çevrilmiştir.

### 2. Gelişmiş ALV Raporlama Uygulamaları
Standart ve interaktif liste görünümleri için oluşturulan operasyonel raporlar (`zgz_alv`, `zgz_ralv`, `zgz_ralv_002`):
* **İnteraktif ALV (REUSE & SALV):** Kullanıcı komutları (`USER_COMMAND`) yakalanarak raporlar; veri gösteren bir ekrandan çıkarılıp kaydetme veya çıktı alma (`&CKT`, `&IC1` özel PF-STATUS komutları) işlemlerini yöneten araçlara dönüştürülmüştür.
* **Görsel Optimizasyon:** Stok durumuna göre dinamik satır/hücre renklendirme (kırmızı, sarı, yeşil), LED ikonlar, zebra dizilimi ve HOTSPOT (tıklanabilir alan) özellikleri rapora entegre edilmiştir.

### 3. Dinamik Ekran ve Dialog Programlama (Dynpro)
Kullanıcı etkileşimli ekran tasarımları ve PBO/PAI modül işlemleri (`zgz_screen`, `zgz_screen_001`):
* Seçim ekranlarında (Selection-screen) radio button seçimlerine bağlı olarak ekran alanlarının (`screen-group1`) `LOOP AT SCREEN` döngüleriyle dinamik olarak açılıp kapanması (aktif/pasif kontrolü) sağlanmıştır.

### 4. Modern ABAP ve Veritabanı Performans İşlemleri
* **İlişkisel Veritabanı Sorguları (`zgz_joins`):** Satış (VBAK, VBAP), Satınalma (EKKO, EKPO) ve Malzeme (MARD, MARA, MAKT) modüllerine ait standart SAP tabloları ile Z'li tablolar arasında `INNER JOIN` ve `LEFT JOIN` kullanılarak performanslı veri çekimi yapılmıştır.
* **Modern ABAP Syntax:** Geleneksel yaklaşımların ötesine geçilerek, `LOOP AT ... GROUP BY` yapısı ile satış belgeleri ve malzemeler kendi içlerinde gruplandırılmış, alt toplam ve stok hesaplamaları efektif şekilde gerçekleştirilmiştir.

##  Kurulum ve Kullanım (abapGit)

Bu depodaki kodları kendi SAP sisteminize çekmek için:

1. SAP sisteminizde `ZABAPGIT` programını (veya abapGit Eclipse eklentisini) çalıştırın.
2. **"New Online"** seçeneğine tıklayarak bu deponun URL'sini girin.
3. Bağlamak istediğiniz SAP Paketini (Package) seçin.
4. **"Pull"** işlemi ile tüm objeleri sisteminize aktarıp aktive edin (`Ctrl + F3`).

---
**Geliştirici:** Zeynep | GitHub: [@zeynepgltn](https://github.com/zeynepgltn)
