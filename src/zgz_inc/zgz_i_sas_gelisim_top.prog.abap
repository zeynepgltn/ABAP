*&---------------------------------------------------------------------*
*& Include          ZGZ_I_SAS_GELISIM_TOP
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* TABLO TANIMLARI
*----------------------------------------------------------------------*
TABLES: eban, ekko, ekpo.

*----------------------------------------------------------------------*
* YARDIMCI TABLOLAR
*----------------------------------------------------------------------*
DATA: gs_t024  TYPE t024,
      gs_t023  TYPE t023,
      gs_t161u TYPE t161u.

FIELD-SYMBOLS: <gfs_fc> TYPE lvc_s_fcat.

DATA: go_cont TYPE REF TO cl_gui_docking_container,
      go_alv  TYPE REF TO cl_gui_alv_grid.

CLASS cl_controller DEFINITION.
  PUBLIC SECTION.
*----------------------------------------------------------------------*
* TYPE TANIMLARI
*----------------------------------------------------------------------*
    TYPES: BEGIN OF ty_output,
             banfn        TYPE eban-banfn,    "SAT No
             bnfpo        TYPE eban-bnfpo,    "Kalem
             bsart        TYPE eban-bsart,    "Belge Türü
             knttp        TYPE eban-knttp,    "Hesap Tayin Tipi
             ekgrp        TYPE eban-ekgrp,    "Satın Alma Grubu
             eknam        TYPE t024-eknam,    "Satın Alma Grubu Tanımı
             matnr        TYPE eban-matnr,    "Malzeme
             txz01        TYPE eban-txz01,    "Malzeme Tanımı
             menge        TYPE eban-menge,    "Miktar
             meins        TYPE eban-meins,    "Ölçü Birimi
             matkl        TYPE eban-matkl,    "Mal Grubu
             wgbez        TYPE t023t-wgbez,    "Mal Grubu Tanımı
             badat        TYPE eban-badat,    "Talep Tarihi
             afnam        TYPE eban-afnam,    "Yaratan
             frgkz        TYPE eban-frgkz,    "Onay Göstergesi
             fkztx        TYPE t161u-fkztx,   "Onay Göstergesi Tanımı
             frgzu        TYPE eban-frgzu,    "Onay Durumu
             banpr        TYPE eban-banpr,      " İşlem Durumu
             onayci1      TYPE t16fw-objid,     " SAT 1. Onaycı
             onay_t1      TYPE cdhdr-udate,     " SAT 1. Onay Tarihi
             onayci2      TYPE t16fw-objid,     " SAT 2. Onaycı
             onay_t2      TYPE cdhdr-udate,     " SAT 2. Onay Tarihi
             onayci3      TYPE t16fw-objid,     " SAT 3. Onaycı
             onay_t3      TYPE cdhdr-udate,     " SAT 3. Onay Tarihi
             onayci4      TYPE t16fw-objid,     " SAT 4. Onaycı
             onay_t4      TYPE cdhdr-udate,     " SAT 4. Onay Tarihi
             bedat        TYPE eban-bedat,      " SAS'a Çevrilme Tarihi
             sas_bsart    TYPE ekko-bsart,     " SAS Belge Türü
             sas_bedat    TYPE ekko-bedat,     " Belge Tarihi
             aedat        TYPE ekko-aedat,      " Yaratma Tarihi
             ernam        TYPE ekko-ernam,      " SAS Yaratan
             ebeln        TYPE eban-ebeln,      " SAS No
             ebelp        TYPE eban-ebelp,      " SAS Kalem No
             lifnr        TYPE ekko-lifnr,      " Tedarikçi
             name1        TYPE lfa1-name1,      " Tedarikçi Tanımı
             bsmng        TYPE eban-bsmng,      " SAS Miktarı
             netpr        TYPE ekpo-netpr,      " SAS Net Fiyat (EKPO'dan)
             rlwrt        TYPE eban-rlwrt,      " SAS Net Değer
             bpueb        TYPE eban-bpueb,      " SAS Net Fiyat (EBAN'dan)
             submi        TYPE ekko-submi,      " TT Grup No
             konnr        TYPE ekpo-konnr,      " Sözleşme No
             ktpnr        TYPE ekpo-ktpnr,      " Sözleşme Kalem
             sas_frgke    TYPE ekko-frgke,     " SAS Onay Göstergesi
             sas_fkztx    TYPE t161u-fkztx,   " SAS Onay Göstergesi Tanım
             sas_frgzu    TYPE ekko-frgzu,    " SAS Onay Durumu
             procstat     TYPE ekko-procstat,  " İşleme Durumu
             sas_onayci1  TYPE t16fw-objid,    " SAS 1. Onaycı
             sas_onay_t1  TYPE cdhdr-udate,    " 1. Onay Tarihi
             sas_onayci2  TYPE t16fw-objid,    " SAS 2. Onaycı
             sas_onay_t2  TYPE cdhdr-udate,    " 2. Onay Tarihi
             sas_onayci3  TYPE t16fw-objid,    " SAS 3. Onaycı
             sas_onay_t3  TYPE cdhdr-udate,    " 3. Onay Tarihi
             netwr        TYPE ekpo-netwr,     " SAS Toplam Tutar
             sas_ekgrp    TYPE ekko-ekgrp,     " Satın Alma Grubu
             sas_eknam    TYPE t024-eknam,      " Satın Alma Grubu Tanımı (EKKO'dan)
             lgort        TYPE ekpo-lgort,      " Depo Yeri
             lgobe        TYPE t001l-lgobe,     " Depo Yeri Tanım
             mg_ernam     TYPE ekbe-ernam,      " Malzeme Girişi Yapan Kişi
             mg_cpudt     TYPE ekbe-cpudt,      " Malzeme Girişi Yapılan Tarih
             mg_belnr     TYPE ekbe-belnr,      " Malzeme Belgesi
             irsaliye     TYPE ekbe-xblnr,      " İrsaliye / Fatura No
             mgo_ernam    TYPE ekbe-ernam,      " Malzeme Girişi Onaycısı 1
             mgo_cpudt    TYPE ekbe-cpudt,      " Malzeme Girişi Onaycısı 1 - Tarih
             fatura_no    TYPE ekbe-xblnr,     " Fatura No
             sas_no_fat   TYPE ekbe-ebeln,     " Fatura Üzerinde Yazan SAS No
             sap_belge    TYPE ekbe-belnr,     " SAP Belge No
             fat_ernam    TYPE ekbe-ernam,     " Fatura Giren Kişi
             fat_bldat    TYPE ekbe-bldat,     " Fatura Tarihi
             fat_cpudt    TYPE ekbe-cpudt,     " Fatura Giriş Tarihi - İşlem Tarihi
             fat_wrbtr    TYPE ekbe-wrbtr,     " Fatura KDV Hariç Toplam
             kdv_goster   TYPE ekbe-mwskz,     " KDV Göstergesi
             dk_hesabi    TYPE ekpo-sakto,      " DK Hesabı (EKPO-KNTTP='' ise)
             ekkn_sakto   TYPE ekkn-sakto,      " DK Hesabı (EKPO-KNTTP=K,P,A ise)
             pyp          TYPE ekkn-ps_psp_pnr, " PYP
             masraf_yeri  TYPE ekkn-kostl,      " Masraf Yeri (EKKN'den)
             kar_merkezi  TYPE ekpo-ko_prctr,   " Kar Merkezi (EKPO-KNTTP='' ise)
             ekkn_prctr   TYPE ekkn-prctr,      " Kar Merkezi (EKPO-KNTTP=K,P,A ise)
             duran_varlik TYPE bseg-anln1,      " Duran Varlık
           END OF ty_output.


*----------------------------------------------------------------------*
* İÇ TABLO VE WORKAREA
*----------------------------------------------------------------------*
    DATA: mt_alv       TYPE TABLE OF ty_output,
          ms_layout    TYPE lvc_s_layo,
          mt_fcat      TYPE lvc_t_fcat,
          mo_alv       TYPE REF TO cl_gui_alv_grid,
          mo_container TYPE REF TO cl_gui_docking_container.
    CLASS-METHODS:
      create_instance RETURNING VALUE(r_obj) TYPE REF TO cl_controller.

    METHODS:
      run,
      read_data EXCEPTIONS no_data_found,
      pbo IMPORTING VALUE(iv_dynnr) TYPE syst_dynnr,
      pai,
      set_fieldcat. "IMPORTING iv_struct TYPE tabname.

  PRIVATE SECTION.
    CLASS-DATA: mo_instance TYPE REF TO cl_controller.
ENDCLASS.


DATA go_obj TYPE REF TO cl_controller.


*----------------------------------------------------------------------*
* SELECTION SCREEN
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  " EBAN Alanları
  SELECT-OPTIONS: s_banfn  FOR eban-banfn,               " SAT no
                  s_bsart  FOR eban-bsart.               " SAT Belge Türü (EBAN-BSART)

  " EKKO Alanları
  SELECT-OPTIONS: s_ekgrp  FOR ekko-ekgrp,               " Satın alma Grubu
                  s_ebsart FOR ekko-bsart,               " SAS Belge Türü
                  s_aedat  FOR ekko-aedat,               " SAS Yaratma Tarihi
                  s_ebeln  FOR ekko-ebeln,               " Satınalma Siparişi
                  s_ernam  FOR ekko-ernam,               " SAS Yaratan
                  s_procst FOR ekko-procstat.           " SAS Onay Durumu

  " EKPO Alanları
  SELECT-OPTIONS: s_knttp  FOR ekpo-knttp,               " Hesap Tayin Tipi
                  s_matnr  FOR ekpo-matnr,               " Malzeme
                  s_lifnr  FOR ekpo-infnr,               " Satıcı (EKPO-LIFNR / LFA1-LIFNR)
                  s_lgort  FOR ekpo-lgort,               " Depo Yeri
                  s_matkl  FOR ekpo-matkl.               " Mal Grubu

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.

  " Checkbox Alanı
  PARAMETERS: p_loekz AS CHECKBOX DEFAULT 'X'.           " Silme İşareti Olanları Gizle

SELECTION-SCREEN END OF BLOCK b2.
