# Varsayılan Veriler Yükleme Özelliği

## Genel Bakış
Uygulama ilk kez yüklendiğinde kullanıcıya kapsamlı örnek veriler sunulması için `DefaultDataService` oluşturuldu. Kullanıcılar uygulamanın tüm özelliklerini anlamak için hazır örneklerle başlayabilir.

## Dosyalar

### 1. `/lib/Service/default_data_service.dart`
Varsayılan verileri yükleyen ana servis dosyası.

**Özellikler:**
- İlk yükleme kontrolü (SharedPreferences kullanarak)
- Kategoriler, görevler, traits, store items, projeler ve notlar oluşturma
- Debug mesajları ile detaylı loglama
- Test amaçlı ilk yükleme bayrağını sıfırlama fonksiyonu

## Oluşturulan Varsayılan Veriler

### 📁 Kategoriler (4 adet)
1. **Work** (İş) - 🔵 Mavi - 💼 İş simgesi
2. **Personal** (Kişisel) - 🟢 Yeşil - 👤 Kişi simgesi
3. **Health** (Sağlık) - 🔴 Kırmızı - ❤️ Kalp simgesi
4. **Shopping** (Alışveriş) - 🟠 Turuncu - 🛒 Sepet simgesi

### ✅ Görevler (7 adet)
**Work Kategorisi:**
- "Check emails" - CHECKBOX, bugün 09:00
- "Prepare for meeting" - TIMER, bugün 14:00 (1 saat hedef)

**Personal Kategorisi:**
- "Read book" - COUNTER, bugün (30 sayfa hedef)
- "Call Micheal Scott" - CHECKBOX, yarın

**Health Kategorisi:**
- "Morning exercise" - TIMER, bugün 07:00 (30 dakika hedef)
- "Drink water" - COUNTER, bugün (8 bardak hedef)

**Shopping Kategorisi:**
- "Buy groceries" - CHECKBOX, yarın
  - 📋 **4 Subtask ile:** Milk, Bread, Eggs, Fruits

### 💪 Traits (6 adet)
**Attributes (Özellikler):**
- 🦉 Wisdom - Mavi
- 💪 Power - Kırmızı
- 🎨 Creativity - Mor

**Skills (Yetenekler):**
- 💻 Programming - Yeşil
- 💬 Communication - Mavi
- 🏋️ Fitness - Turuncu

### 🏪 Store Items (3 adet)
1. **1 Hour Gaming** - TIMER (1 saat) - 15 kredi
   - Kendini oyun oynayarak ödüllendir
2. **Snack** - CHECKBOX - 5 kredi
   - Favori atıştırmalığının tadını çıkar
3. **Movie** - CHECKBOX (2 saat) - 20 kredi
   - Film veya dizi bölümü izle

### 📋 Projeler (3 adet)
1. **Q4 Planning** - Work kategorisi
   - Quarterly planlama ve hedef belirleme
   - **3 Subtask:** Review results (✓), Set goals, Prepare presentation
   - **1 Not:** Key Objectives
   
2. **Learning Goals** - Personal kategorisi (sabitlenmiş)
   - Kişisel gelişim ve öğrenme hedefleri
   - **2 Subtask:** Complete Flutter course, Read 2 books per month
   - **1 Not:** Resources
   
3. **Fitness Journey** - Health kategorisi
   - Fitness gelişimini ve sağlık iyileştirmelerini takip et
   - **3 Subtask:** Exercise 3x/week (✓), Track water intake, Meal prep
   - **2 Not:** Progress Tracking, Meal Ideas

### 📝 Notlar (4 adet)
1. **Meeting Notes** - Work kategorisi
   - Toplantı notları ve önemli noktalar
   - *Bugün oluşturuldu*
   
2. **Reading List** - Personal kategorisi
   - Okunacak kitaplar listesi
   - *Farklı zamanda oluşturuldu*
   
3. **Ideas** - Kategorisiz
   - Rastgele fikirler ve düşünceler
   - *Farklı zamanda oluşturuldu*
   
4. **Workout Plan** - Health kategorisi
   - Haftalık antrenman programı
   - *Farklı zamanda oluşturuldu*

## Nasıl Çalışır?

1. Uygulama başlatıldığında `init_app.dart` içinde `DefaultDataService.checkAndLoadDefaultData()` çağrılır
2. SharedPreferences'ta `is_first_launch` anahtarı kontrol edilir
3. Eğer ilk yükleme ise:
   - Varsayılan kategoriler oluşturulur
   - Traits (attributes & skills) oluşturulur
   - Store items oluşturulur
   - Her kategori için örnek görevler eklenir
   - Örnek projeler oluşturulur
   - Örnek notlar eklenir
   - `is_first_launch` false olarak işaretlenir
4. Eğer ilk yükleme değilse, hiçbir şey yapılmaz

## Clean Code Prensipleri

✅ **Tek Sorumluluk Prensibi (SRP):** Her metot tek bir iş yapar  
✅ **Debug Mesajları:** Her önemli adımda detaylı log mesajları  
✅ **Hata Yönetimi:** Try-catch blokları ile hata yakalama ve loglama  
✅ **Anlamlı İsimler:** Değişken ve metot isimleri açık ve anlaşılır  
✅ **Dokümantasyon:** Her metot için açıklayıcı yorum satırları  
✅ **Dosya Boyutu:** 600 satırın altında tutuldu

## Test İçin

İlk yükleme durumunu test etmek için:

```dart
// İlk yükleme bayrağını sıfırla
await DefaultDataService.resetFirstLaunchFlag();

// Uygulamayı yeniden başlat
// Varsayılan veriler tekrar yüklenecektir
```

## Debug Mesajları

Servis çalışırken şu mesajlar loglanır:
- `🔍 DefaultDataService: İlk yükleme kontrolü`
- `🎉 DefaultDataService: İlk yükleme tespit edildi`
- `✅ DefaultDataService: X kategori oluşturuldu`
- `✅ DefaultDataService: X trait oluşturuldu`
- `✅ DefaultDataService: Store items oluşturuldu`
- `✅ DefaultDataService: [Özellik] oluşturuldu`
- `✅ DefaultDataService: Varsayılan veriler başarıyla yüklendi`
- `❌ DefaultDataService: [Hata mesajı]` (hata durumunda)

## Önemli Notlar

- Tüm renkler `AppColors` sınıfından çağrılıyor
- Her veri tipi için ayrı oluşturma metodu var
- Provider'lar üzerinden veri ekleme yapılıyor
- ServerManager ile backend entegrasyonu sağlanıyor
- Hata durumlarında detaylı log mesajları

## Gelecek Geliştirmeler

Potansiyel iyileştirmeler:
1. Çoklu dil desteği (Türkçe kategoriler ve görevler)
2. Özelleştirilebilir varsayılan veriler (kullanıcı seçebilir)
3. Farklı senaryolar için veri setleri (öğrenci, profesyonel, hobi vs.)
4. Varsayılan verileri JSON dosyasından okuma
5. Kullanıcı tercihine göre varsayılan veri yoğunluğu ayarı
