# ABAP Geliştirme Reposu 

Bu depo, SAP ABAP ortamında **Fiks Bilişim** bünyesinde (Şubat – Mayıs 2026) geliştirdiğim raporları, form tasarımlarını, interaktif ekran (dialog) programlamalarını ve veritabanı performans çalışmalarını içermektedir. Kodları, SAP sistemleri ile GitHub arasında versiyon kontrolü sağlamak amacıyla **abapGit** kullanarak aktardım.

---

## 📂 Proje Yapısı

Kodları standart abapGit dizin hiyerarşisine uygun olarak `src/` klasörü altında modüler olarak ayırdım:

| Klasör | İçerik |
|---|---|
| `zgz_dat/` | Veri tanımlamaları (Data definitions) ve global değişkenler |
| `zgz_inc/` | Include programları ve alt rutinler |
| `zgz_prg/` | Ana çalıştırılabilir (Executable) programlar ve modül havuzları |

---

## 💼 Geliştirilen Projeler ve Teknik Kazanımlar

### 1. Çıktı Yönetimi ve Form Tasarımı (Smart Forms & Adobe Forms)

Fatura, irsaliye ve belge dökümleri için uçtan uca çıktı yönetimi kurguladım.

- **Smart Forms Entegrasyonu (`zgz_sf_001`):** ALV üzerinden seçilen (Checkbox/SELKZ) belgelerin detaylarını dinamik olarak formlara aktardım (`SSF_FUNCTION_MODULE_NAME`). Forma logo, dinamik metinler ve adres bilgilerini (`FOR ALL ENTRIES` ile ADRC, TVKO, T005U, ADR2/6/12 tablolarından) bastım. Satış belgesi numarasına göre `LOOP AT ... GROUP BY` yapısıyla belge bazlı gruplama ve alt toplam hesaplamaları gerçekleştirdim.
- **Performanslı Yazdırma (Spooling):** `SSF_OPEN` ve `SSF_CLOSE` fonksiyonlarıyla seri yazdırma işlemlerini tek bir spool dosyasında birleştirerek yazıcı performansını optimize ettim.
- **Adobe Forms - IFbA (`zgz_adobe`):** `SFP` işlem kodu ve LiveCycle Designer kullanarak modern arayüz ve mizanpaj tasarımları yaptım, barkod/QR kod entegrasyonlarını kurguladım. PDF üretim hatalarını derinlemesine debug ederek, uyumsuz alanları saha kataloğunda `tech = 'X'` parametresiyle teknik alana çektim.
- **Finansal Fonksiyonlar:** Belge tutarlarını `SPELL_AMOUNT` fonksiyonu ile para birimine göre (TRY → KR, USD → cent) kuruş hassasiyetinde yazıya çevirdim.

### 2. Gelişmiş ALV Raporlama Uygulamaları

Standart ve interaktif liste görünümleri için operasyonel raporlar oluşturdum (`zgz_alv`, `zgz_ralv`, `zgz_ralv_002`):

- **İnteraktif ALV (REUSE & SALV):** Kullanıcı komutlarını (`USER_COMMAND`) yakalayarak raporları kaydetme veya çıktı alma işlemlerini yöneten araçlara dönüştürdüm (`&CKT`, `&IC1` özel PF-STATUS komutları). `SET_STATUS` formu ile özel toolbar kurgulayarak standart araç çubuğuna `&DEL` silme ikonu ve "Yazdır" gibi özel butonlar ekledim.
- **Görsel Optimizasyon:** Stok/belge durumuna göre dinamik satır ve hücre renklendirme (`LINE_COLOR`, `CELL_COLOR`), LED ikonlar, zebra dizilimi ve HOTSPOT (tıklanabilir alan) özelliklerini entegre ettim.
- **Varyant Yönetimi:** `LVC_VARIANT_DEFAULT_GET` ve `LVC_VARIANT_F4` fonksiyonlarıyla kullanıcıların kendi filtre ve sıralama düzenlerini kaydedip varsayılan olarak seçebildiği bir varyant altyapısı kurdum.
- **Editable ALV & Validation:** `handle_data_changed` event'i ile çalışan, anlık hata kontrolü (trafik ışığı ikonları) sunan düzenlenebilir ALV yapıları tasarladım. BAPI entegrasyonunu `BAPI_MATERIAL_SAVEDATA` ve `BAPI_PR_CREATE` ile tamamlayarak Commit/Rollback mekanizmasını işlettim.

### 3. Satıştan Siparişe: Teklif/Sipariş Yönetimi (`ZGZ_P_TEKLIF_SIPARIS`)

SD modülü için uçtan uca bir teklif-sipariş dönüşüm programı geliştirdim:

- **Container Splitter Mimarisi:** Ekranı `cl_gui_splitter_container` ile dinamik olarak bölerek üst kısımda VBAK üzerinden müşteri bazlı açık teklifleri listelerken, Hotspot özelliği ile seçilen teklife ait VBAP kalem detaylarını alt panelde anlık olarak yükledim.
- **Referans Miktar Hesaplamaları:** VBFA (satış akış tablosu) üzerinden açık miktar, kullanılan miktar ve birim fiyat gibi değerlerin runtime'da otomatik hesaplanmasını sağladım.
- **Çoklu Seçim Pop-up'ı:** `handle_data_changed` event'i ile çalışan, hedef miktarın açık miktarı aşmasını engelleyen gerçek zamanlı validasyon ekledim. SELKZ checkbox yönetimiyle satır bazlı seçim kontrolü ve `&CREATE` butonu ile toplu tekliften siparişe dönüşüm akışını oluşturdum.

### 4. Dinamik Ekran ve Dialog Programlama (Dynpro)

Kullanıcı etkileşimli ekran tasarımları ve PBO/PAI modül işlemlerini kurguladım (`zgz_screen`, `zgz_screen_001`, `ZGZ_SCREEN_002`):

- Seçim ekranlarında radio button seçimine bağlı olarak ekran alanlarının (`screen-group1`) `LOOP AT SCREEN` ile dinamik aktif/pasif kontrolünü sağladım.
- Kayıt ekleme, silme ve güncelleme işlemlerini tek ekran (0200) üzerinde mod flag'i (I/D/U) ile yöneten modüler bir dialog programı geliştirdim.
- **Enqueue/Dequeue** mekanizmasıyla kayıt kilitleme, F4 takvim desteği, ID Search Help ve şirket kodu filtreli arama yardımı entegrasyonlarını tamamladım.
- Maaş yönetimi için +50/-50 butonları ve güncelleme sonrası şirket tablosundaki maaş hacmini fark üzerinden güncelleyen bir kontrol mekanizması kurdum.
- ALV raporunu `CL_GUI_ALV_GRID` ile Docking Container kullanarak log tablosu üzerinden listeledim.

### 5. Ürün Ağacı (BOM) Kopyalama Motoru

- **Derin Bileşen Doğrulama (Deep Validation):** Kopyalanacak ürün ağacının tüm bileşenlerinin hedef üretim yerinde (MARC) tanımlı olup olmadığını `BINARY SEARCH` ile optimize edilmiş toplu SELECT sorguları ile kontrol ettim.
- `MAST` ve `STKO` tablolarından ana miktar (BMENG) verilerini çekip BICS yapılarına entegre ederek `CSAP_MAT_BOM_CREATE` BAPI'si ile kopyalama işlemini tamamladım.

### 6. Modern ABAP ve Performans Odaklı Veritabanı İşlemleri

- **İlişkisel Sorgular (`zgz_joins`):** Satış (VBAK, VBAP), Satınalma (EKKO, EKPO), Malzeme (MARD, MARA, MAKT) ve Finans (BKPF, BSEG, KNA1, LFA1) modüllerine ait tablolar arasında `INNER JOIN` ve `LEFT JOIN` yapıları kurguladım. Özellikle dil bağımlı metinlerin (`sy-langu`) ve fiyat koşullarının (ZF01) doğru filtrelenmesi için kompleks LEFT JOIN sorguları yazdım.
- **Modern ABAP Syntax:** `LOOP AT ... GROUP BY` yapısı ile belge bazlı gruplama ve alt toplam hesaplamalarını efektif şekilde gerçekleştirdim. Inline declaration ve diğer 7.40+ özelliklerini aktif olarak kullandım.
- **Güvenli Hata Yönetimi:** `TRY...CATCH` blokları ile `cx_sy_open_sql_db`, `cx_sy_resource_shortage`, `cx_bcs` gibi sistemsel hataları yakalayarak sistem stabilitesini artırdım.

### 7. Excel Tabanlı Satınalma Talebi Oluşturma (`ZGZ_P_SAT_EXCEL`)

MM modülü için Excel'den toplu Satınalma Talebi (SAT) oluşturan, uçtan uca OOP mimarisiyle yazılmış bir program geliştirdim.

Programın akışı seçim ekranıyla başlıyor: kullanıcı `AT SELECTION-SCREEN ON VALUE-REQUEST` ile tetiklenen F4 arama yardımı sayesinde masaüstünden bir `.xlsx` dosyası seçiyor, ardından seçim ekranına eklediğim `SABLOND` fonksiyon tuşuyla aynı yapıyı boş şablon olarak bilgisayarına indirebiliyor. Yükleme tarafında `cl_fdt_xl_spreadsheet` sınıfının hücreleri tipli okuması sayesinden `DESCRIBE FIELD` gereksinimleri ortadan kalktı; tarih alanlarında önce `CONVERT_DATE_TO_INTERNAL` fonksiyon modülü deneniyor, başarısız olursa nokta/tire/bölü işaretleri temizlenerek 8 karakterli formata manuel dönüşüm yapılıyor. Kolon kaymalarını önlemek için `ASSIGN COMPONENT` döngüsünde +2 ofset algoritması kurgulandı; `LIGHT` ve `SELKZ` alanları atlanarak veriler doğru sütunlara yerleşiyor.

Veriler yüklendikten sonra program `CALL SCREEN 0100` ile ALV ekranına geçiyor. Ekran `cl_gui_docking_container` ile alt kısma yerleştirilmiş bir `cl_gui_alv_grid` barındırıyor; `LVC_FIELDCATALOG_MERGE` ile `ZGZ_S_SAT_ALV` yapısından otomatik oluşturulan saha kataloğunda `LIGHT` sütunu tıklanabilir (hotspot) sarı bir trafik ışığı ikonu olarak, `SELKZ` ise düzenlenebilir bir onay kutusu olarak yapılandırıldı. Toolbar'a eklenen `&SC` "SAT Oluştur" butonu `BAPI_PR_CREATE` çağrısını tetikliyor: başlık tipi, kalem bilgileri (malzeme, miktar, teslim tarihi, üretim yeri, satınalma grubu), hesap atama kategorisine göre dallanarak doldurulan `PRACCOUNT` yapıları (masraf yeri K, duran varlık A, proje P) ve başlık/kalem metinleri tek bir BAPI çağrısıyla sisteme iletiliyor. İşlem sonucunda `lt_return` tablosunda hata tipi (`E`/`A`) varsa `BAPI_TRANSACTION_ROLLBACK`, yoksa `BAPI_TRANSACTION_COMMIT WAIT` tetikleniyor; ilgili satırlardaki trafik ışığı ikonu yeşile ya da kırmızıya dönüyor, başarılı satırlara SAP'nin ürettiği SAT belgesi numarası yazılıyor. Işık ikonuna tıklandığında `C14ALD_BAPIRET2_SHOW` fonksiyonu o satıra ait BAPI dönüş mesajlarını pop-up olarak sunuyor. İndirme tarafında `cl_salv_ex_util` ve `cl_salv_bs_tt_util` sınıfları aracılığıyla `LIGHT` ve `SELKZ` kolonları fieldcat'ten çıkarılarak temiz bir XLSX şablonu `GUI_DOWNLOAD` ile kullanıcıya iletiliyor.

### 8. Dinamik Programlama, Excel I/O ve Mail Entegrasyonu

Jenerik ve tekrar kullanılabilir (reusable) metotlar tasarladım:

- **Dinamik Veri İşleme:** `TYPE REF TO data` ve `FIELD-SYMBOLS` kullanarak, farklı tablo yapılarını (Satış, Satınalma vb.) tek bir metot üzerinden işleyebilen esnek bir mimari kurdum.
- **Gelişmiş Excel İndirme (abap2xlsx):** `cl_fdt_xl_spreadsheet` sınıfı ve XSTRING dönüşümleriyle kolonları dinamik olarak okuyan tipli Excel Upload/Download mekanizmaları geliştirdim. Logo (MIME Repository), hücre birleştirme, dinamik stil tanımlamaları (renk, font, sayı formatı) ve sütun genişlikleri içeren profesyonel Excel çıktıları ürettim. `GUI_DOWNLOAD` için Türkçe karakter uyumluluğu adına codepage `4110` parametresini kullandım.
- **BCS Mail Gönderimi:** ALV raporlarını Excel eki olarak `cl_bcs` / `cl_document_bcs` sınıflarıyla gönderdim. Alıcıları statik yazmak yerine `zgz_mail_list` bakım tablosundan okuyarak TO/CC ayrımını dinamik olarak yönettim. `POPUP_TO_GET_VALUE` ile anlık manuel alıcı girişi ve HTML gövdeli (`build_html_table`) renkli tablo içerikli mail gönderimi de kurguladım.

### 9. Nesne Yönelimli (OOP) ABAP Mimarisi

Tüm eski tip FORM/PERFORM yapılarını `lcl_controller` sınıfına taşıyarak modern OOP tasarımına geçtim:

- `cl_event_receiver` sınıfı altında `handle_toolbar`, `handle_user_command`, `handle_hotspot_click`, `handle_double_click`, `handle_data_changed`, `handle_onf4`, `handle_top_of_page` gibi kapsamlı event handler metotları kodladım.
- Singleton tasarım kalıbıyla `cl_controller` sınıfını yönettim; `EXPORTING`, `IMPORTING`, `CHANGING`, `RETURNING` parametreleriyle metotlar arası veri alışverişini modüler hale getirdim.
- `cl_gui_splitter_container` ile Master-Detail ALV yapısı, `mc_style_disabled` ile hücre seviyesinde dinamik kilitleme ve `drdn_hndl` / `LVC_T_DROP` ile koşullu dropdown listeleri oluşturdum.

### 10. Yapay Zeka (AI) ve LLM Destekli Kod Modernizasyonu

- **LLM Fine-Tuning:** Eski tip ABAP kodlarını 7.40+ modern syntax'a çevirmek için LangChain ve HuggingFace kullanarak StarCoder2 modelini ABAP özelinde `BitsAndBytes (4-bit quantization)` ve `LoRA` teknikleriyle `SFTTrainer` üzerinde eğittim. `abap_generate_clean` metoduyla model çıktılarını temiz formata kavuşturdum.
- **RAG ve Vektör Veritabanı:** ABAP kod parçacıklarını `RecursiveCharacterTextSplitter` (METHOD/CLASS ayraçlı) ile bölerek FAISS vektör veritabanına indeksleyip bağlam farkındalıklı kod taşıma ve mimari özetleme Agent'ları uyguladım.
- **VS Code ABAP Agent Ekosistemi:** `#tasi` (kod modernizasyonu) ve `#taslak_olustur` (mimari plan) komutları ile `@Musteri_A` (7.40+ Modern) / `@Musteri_B` (legacy syntax) gibi müşteri profili etiketlerinden oluşan bir kural seti ekosistemi tasarladım.


11. SD Programı
ZGZ_P_TEKLIF_SIPARIS programı geliştirdim.
SD Cockpit Arayüzü: Container Splitter ile bölünmüş dinamik ekranda Hotspot izleme mekanizması kurarak seçilen teklife ait VBAP kalem detaylarının anlık görüntülenmesini sağladım.
Validasyon ve İş Mantığı: FOR ALL ENTRIES ve REDUCE operatörleriyle derin doğrulama katmanı entegre ettim. SD belge akışı (VBFA) üzerinden "Açık Miktar" ve birim fiyat hesaplamalarını otomatikleştirdim.
Süreç Otomasyonu ve BAPI: BAPI_SALESORDER_CREATEFROMDAT2 ve BAPI_SALESORDER_CHANGE entegrasyonuyla Oluştur/Güncelle operasyon modlarını hayata geçirdim. Dinamik koşul eşlemesiyle (ZLST) NETWR hesaplamalarındaki hassasiyet hatalarını giderdim. Programı özel işlem kodu ZSDT1'e bağladım.
Uzun Metin ve Bildirimler: READ_TEXT / SAVE_TEXT modülleri aracılığıyla tekliften siparişe başlık metni replikasyonunu otomatikleştirdim. ADR6-SMTP_ADDR üzerinden dinamik e-posta bildirimi için Z bakım tablosu oluşturdum.

---

## ⚙️ Kurulum ve Kullanım (abapGit)

Bu depodaki kodları kendi SAP sisteminize çekmek için:

1. SAP sisteminizde `ZABAPGIT` programını (veya abapGit Eclipse eklentisini) çalıştırın.
2. **"New Online"** seçeneğine tıklayarak bu deponun URL'sini girin.
3. Bağlamak istediğiniz SAP Paketini (Package) seçin.
4. **"Pull"** işlemi ile tüm objeleri sisteminize aktarıp aktive edin (`Ctrl + F3`).

---

**Geliştirici:** Zeynep Gülten | GitHub: [@zeynepgltn](https://github.com/zeynepgltn)
