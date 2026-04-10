# ABAP Geliştirme Reposu 🚀

Bu depo, SAP ABAP ortamında geliştirdiğim raporları, form tasarımlarını, interaktif ekran (dialog) programlamalarını ve veritabanı performans çalışmalarını içermektedir. Kodları, SAP sistemleri ile GitHub arasında versiyon kontrolü sağlamak amacıyla **abapGit** kullanarak aktardım.

Aşağıdaki projeler ve modüller, **Fiks Bilişim** bünyesindeki ürün geliştirme süreçlerinde (Şubat - Haziran 2026) edindiğim profesyonel iş senaryoları pratiğine dayanmaktadır.

## 📂 Proje Yapısı

Kodları standart abapGit dizin hiyerarşisine uygun olarak `src/` klasörü altında modüler olarak ayırdım:

* **`zgz_dat/`**: Veri tanımlamaları (Data definitions) ve global değişkenler
* **`zgz_inc/`**: Include programları ve alt rutinler
* **`zgz_prg/`**: Ana çalıştırılabilir (Executable) programlar ve modül havuzları

## 💼 Geliştirilen Projeler ve Teknik Kazanımlar

### 1. Çıktı Yönetimi ve Form Tasarımı (Smart Forms & Adobe Forms)
Fatura, irsaliye ve belge dökümleri için uçtan uca çıktı yönetimi kurguladım.
* **Smart Forms Entegrasyonu (`zgz_sf_001`):** ALV üzerinden seçilen (Checkbox/SELKZ) belgelerin detaylarını dinamik olarak formlara aktardım (`SSF_FUNCTION_MODULE_NAME`). Forma logo, dinamik metinler ve adres bilgilerini (`FOR ALL ENTRIES` ile ADRC, TVKO tablolardan) bastım.
* **Performanslı Yazdırma (Spooling):** `SSF_OPEN` ve `SSF_CLOSE` fonksiyonlarıyla seri yazdırma işlemlerini tek bir spool dosyasında birleştirerek yazıcı performansını optimize ettim.
* **Adobe Forms - IFbA (`zgz_adobe`):** `SFP` işlem kodu ve LiveCycle Designer kullanarak modern arayüz (interface) ve mizanpaj tasarımları yaptım, barkod/QR kod entegrasyonlarını kurguladım.
* **Finansal Fonksiyonlar:** Belge tutarlarını `SPELL_AMOUNT` fonksiyonu ile kuruş (KR/Cent) hassasiyetinde dinamik olarak yazıya çevirdim.

### 2. Gelişmiş ALV Raporlama Uygulamaları
Standart ve interaktif liste görünümleri için operasyonel raporlar oluşturdum (`zgz_alv`, `zgz_ralv`, `zgz_ralv_002`):
* **İnteraktif ALV (REUSE & SALV):** Kullanıcı komutlarını (`USER_COMMAND`) yakalayarak raporları sadece veri gösteren bir ekrandan çıkarıp; kaydetme veya çıktı alma (`&CKT`, `&IC1` özel PF-STATUS komutları) işlemlerini yöneten araçlara dönüştürdüm.
* **Görsel Optimizasyon:** Stok durumuna göre dinamik satır/hücre renklendirme, LED ikonlar, zebra dizilimi ve HOTSPOT (tıklanabilir alan) özelliklerini rapora entegre ettim.

### 3. Dinamik Ekran ve Dialog Programlama (Dynpro)
Kullanıcı etkileşimli ekran tasarımları ve PBO/PAI modül işlemlerini kurguladım (`zgz_screen`, `zgz_screen_001`):
* Seçim ekranlarında (Selection-screen) radio button seçimlerine bağlı olarak ekran alanlarının (`screen-group1`) `LOOP AT SCREEN` döngüleriyle dinamik olarak açılıp kapanmasını (aktif/pasif kontrolü) sağladım.

### 4. Modern ABAP ve Performans Odaklı Veritabanı İşlemleri
* **İlişkisel Veritabanı Sorguları (`zgz_joins`):** Satış (VBAK, VBAP), Satınalma (EKKO, EKPO) ve Malzeme (MARD, MARA, MAKT) modüllerine ait standart SAP tabloları ile Z'li tablolar arasında `INNER JOIN` ve `LEFT JOIN` kullanarak performanslı veri çekimi yaptım.
* **Modern ABAP Syntax:** Geleneksel yaklaşımların ötesine geçerek, `LOOP AT ... GROUP BY` yapısı ile verileri kendi içlerinde gruplandırdım; alt toplam ve stok hesaplamalarını efektif şekilde gerçekleştirdim.
* **Güvenli Hata Yönetimi (Exception Handling):** Olası SQL hataları ve zaman aşımlarını engellemek için kod bloklarımı modern `TRY...CATCH` yapılarıyla sarmalayarak sistem stabilitesini artırdım.

### 5. Dinamik Programlama, Excel I/O ve Mail Entegrasyonu
Spagetti koddan arındırılmış, jenerik ve tekrar kullanılabilir (reusable) metotlar tasarladım:
* **Dinamik Veri İşleme:** `TYPE REF TO data` ve `FIELD-SYMBOLS` (Pointer) kullanarak, farklı tablo yapılarını (Satış, Satınalma vb.) tek bir metot üzerinden işleyebilen esnek bir mimari kurdum.
* **Gelişmiş Excel Yükleme/İndirme:** `cl_fdt_xl_spreadsheet` sınıfı ve XSTRING dönüşümleriyle, kolonları dinamik olarak okuyan tipli (typed) Excel Upload/Download mekanizmaları geliştirdim.
* **BCS Mail Gönderimi:** ALV raporlarını tek tuşla arka planda Excel eki haline getirip e-posta (`cl_bcs`) olarak gönderebilme altyapısını kurdum.

### 6. Yapay Zeka (AI) ve LLM Destekli Kod Modernizasyonu
Gelişen teknolojilerin ABAP ekosistemine entegrasyonunu sağladım:
* **LLM Fine-Tuning:** Eski tip (Legacy) ABAP kodlarını 7.40+ modern syntax'a (Inline declaration vb.) çevirmek için LangChain kullanarak lokal bir modeli (StarCoder2) ABAP özelinde eğittim.
* **RAG ve Vektör Veritabanı:** ABAP kod parçacıklarını FAISS vektör veritabanına indeksledim ve yapay zekanın bağlam farkındalığıyla (Context-Aware) otomatik kod taşıma/mimari özetleme işlevlerini (Agent) başarıyla uyguladım.

## ⚙️ Kurulum ve Kullanım (abapGit)

Bu depodaki kodları kendi SAP sisteminize çekmek için:

1. SAP sisteminizde `ZABAPGIT` programını (veya abapGit Eclipse eklentisini) çalıştırın.
2. **"New Online"** seçeneğine tıklayarak bu deponun URL'sini girin.
3. Bağlamak istediğiniz SAP Paketini (Package) seçin.
4. **"Pull"** işlemi ile tüm objeleri sisteminize aktarıp aktive edin (`Ctrl + F3`).

---
**Geliştirici:** Zeynep | GitHub: [@zeynepgltn](https://github.com/zeynepgltn)
