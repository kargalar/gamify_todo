# Widget Test Senaryoları

## 🧪 Test Hazırlığı

### Gereksinimler
1. Android cihaz veya emulator
2. Debug APK yüklü olmalı
3. Home screen'de widget eklenmiş olmalı

### Test Verileri Hazırlama
Aşağıdaki task'ları oluşturun:

1. **Overdue Task (Checkbox)**
   - Başlık: "Overdue Task Test"
   - Tip: Checkbox
   - Tarih: Dün
   - Status: OVERDUE

2. **Pinned Task (Timer)**
   - Başlık: "Pinned Timer Test"
   - Tip: Timer
   - Hedef: 10 dakika
   - Pin: Aktif

3. **Normal Task (Counter)**
   - Başlık: "Normal Counter Test"
   - Tip: Counter
   - Hedef: 5
   - Tarih: Bugün

4. **Routine Task (Checkbox)**
   - Başlık: "Daily Routine Test"
   - Tip: Checkbox
   - Rutin: Her gün
   - Tarih: Bugün

## 📋 Test Senaryoları

### Test 1: Task Kategorileri Gösterimi

**Amaç:** Tüm task kategorilerinin doğru sırada ve emoji ile gösterildiğini doğrula.

**Adımlar:**
1. Widget'ı aç
2. Task listesini kontrol et

**Beklenen Sonuç:**
- ⚠️ Overdue Task Test (en üstte)
- 📌 Pinned Timer Test (ikinci)
- Normal Counter Test (üçüncü, emoji yok)
- 🔄 Daily Routine Test (en altta)

**Durum:** [ ] Başarılı / [ ] Başarısız

---

### Test 2: Tatil Modu - Rutinleri Gizle

**Amaç:** Tatil modu aktifken rutinlerin gizlendiğini doğrula.

**Adımlar:**
1. Uygulamayı aç
2. Ayarlar > Tatil Modu'nu aktif et
3. Home screen'e dön
4. Widget'ı kontrol et

**Beklenen Sonuç:**
- 🔄 Daily Routine Test gösterilmemeli
- Diğer task'lar normal gösterilmeli
- Task count 3 olmalı (4 değil)

**Durum:** [ ] Başarılı / [ ] Başarısız

---

### Test 3: Tatil Modu - Rutinleri Göster

**Amaç:** Tatil modu kapatıldığında rutinlerin tekrar gösterildiğini doğrula.

**Adımlar:**
1. Uygulamayı aç
2. Ayarlar > Tatil Modu'nu deaktif et
3. Home screen'e dön
4. Widget'ı kontrol et

**Beklenen Sonuç:**
- 🔄 Daily Routine Test tekrar gösterilmeli
- Task count 4 olmalı

**Durum:** [ ] Başarılı / [ ] Başarısız

---

### Test 4: Checkbox Task - İşaretle

**Amaç:** Widget'tan checkbox task'ı işaretleme.

**Adımlar:**
1. Widget'ta "Overdue Task Test"e bas
2. Widget'ın güncellenmesini bekle (1-2 saniye)
3. Uygulamayı aç ve task'ı kontrol et

**Beklenen Sonuç:**
- Task widget'tan kaybolmalı (tamamlandı)
- Uygulamada task DONE olarak işaretli olmalı
- Task count 1 azalmalı

**Durum:** [ ] Başarılı / [ ] Başarısız

---

### Test 5: Counter Task - Artır

**Amaç:** Widget'tan counter task'ı artırma.

**Adımlar:**
1. Widget'ta "Normal Counter Test"e bas
2. Widget'ın güncellenmesini bekle
3. Sayının arttığını kontrol et
4. 2-3 kez daha bas

**Beklenen Sonuç:**
- Her basışta sayı 1 artmalı (0/5 -> 1/5 -> 2/5)
- Progress bar ilerlemeli
- 5/5 olduğunda task tamamlanmalı ve widget'tan kaybolmalı

**Durum:** [ ] Başarılı / [ ] Başarısız

---

### Test 6: Timer Task - Başlat

**Amaç:** Widget'tan timer task'ı başlatma.

**Adımlar:**
1. Widget'ta "Pinned Timer Test"e bas
2. Icon'un değiştiğini kontrol et
3. "RUNNING" badge'inin göründüğünü kontrol et
4. 5-10 saniye bekle

**Beklenen Sonuç:**
- Icon play'den pause'a dönmeli
- "RUNNING" badge gösterilmeli
- Süre her saniye artmalı (00:00:01, 00:00:02, ...)
- Progress bar ilerlemeli

**Durum:** [ ] Başarılı / [ ] Başarısız

---

### Test 7: Timer Task - Durdur

**Amaç:** Widget'tan çalışan timer'ı durdurma.

**Adımlar:**
1. Çalışan timer'a tekrar bas
2. Icon'un değiştiğini kontrol et
3. "RUNNING" badge'inin kaybolduğunu kontrol et

**Beklenen Sonuç:**
- Icon pause'dan play'e dönmeli
- "RUNNING" badge kaybolmalı
- Süre durmalı (artmayı durdurmalı)

**Durum:** [ ] Başarılı / [ ] Başarısız

---

### Test 8: Timer Canlı Güncelleme

**Amaç:** Timer çalışırken widget'ın canlı güncellenmesi.

**Adımlar:**
1. Timer'ı başlat
2. Widget'ı 30 saniye izle
3. Sürenin düzenli güncellendiğini kontrol et

**Beklenen Sonuç:**
- Süre her saniye güncellenmeli
- Widget donmamalı
- Progress bar düzgün ilerlemeli

**Durum:** [ ] Başarılı / [ ] Başarısız

---

### Test 9: Hide Completed Toggle

**Amaç:** Tamamlanmış task'ları gizleme/gösterme.

**Adımlar:**
1. Bir task'ı tamamla (checkbox işaretle)
2. Widget'ta "Hide completed tasks" toggle'ına bas
3. Tamamlanmış task'ın kaybolduğunu kontrol et
4. Toggle'a tekrar bas
5. Tamamlanmış task'ın göründüğünü kontrol et

**Beklenen Sonuç:**
- Toggle aktifken tamamlanmış task'lar gizlenmeli
- Toggle pasifken tamamlanmış task'lar gösterilmeli
- Aktif timer'lar her zaman gösterilmeli

**Durum:** [ ] Başarılı / [ ] Başarısız

---

### Test 10: Multiple Timer

**Amaç:** Birden fazla timer'ın aynı anda çalışması.

**Adımlar:**
1. İki timer task oluştur
2. İkisini de widget'tan başlat
3. Her ikisinin de çalıştığını kontrol et

**Beklenen Sonuç:**
- Her iki timer da "RUNNING" badge göstermeli
- Her iki timer da pause icon göstermeli
- Her iki timer'ın süresi de artmalı

**Durum:** [ ] Başarılı / [ ] Başarısız

---

### Test 11: Widget Görünüm

**Amaç:** Widget'ın görsel iyileştirmelerini kontrol et.

**Kontrol Listesi:**
- [ ] Header tasarımı düzgün (task count büyük ve mavi)
- [ ] Task item'lar okunabilir (büyük font, kalın başlık)
- [ ] Icon'lar belirgin (36dp container, 20dp icon)
- [ ] Progress bar görünür (8dp yükseklik)
- [ ] Padding ve margin değerleri uygun
- [ ] Renkler uyumlu (mavi tonlar)
- [ ] Empty state düzgün gösteriliyor

**Durum:** [ ] Başarılı / [ ] Başarısız

---

### Test 12: Uygulama ile Senkronizasyon

**Amaç:** Widget'tan yapılan değişikliklerin uygulamaya yansıması.

**Adımlar:**
1. Widget'tan bir task'ı tamamla
2. Uygulamayı aç
3. Task'ın durumunu kontrol et

**Beklenen Sonuç:**
- Widget'tan yapılan değişiklik uygulamada görünmeli
- Task log'u oluşturulmalı
- XP kazanılmalı (eğer varsa)

**Durum:** [ ] Başarılı / [ ] Başarısız

---

## 📊 Test Sonuçları

### Özet
- Toplam Test: 12
- Başarılı: __
- Başarısız: __
- Başarı Oranı: __%

### Bulunan Hatalar
1. 
2. 
3. 

### Notlar
- 
- 
- 

## 🐛 Hata Raporlama

Eğer bir hata bulursanız, lütfen aşağıdaki bilgileri kaydedin:

1. **Test Adı:** 
2. **Beklenen Sonuç:** 
3. **Gerçekleşen Sonuç:** 
4. **Adımlar:** 
5. **Ekran Görüntüsü:** (varsa)
6. **Log Çıktısı:** (varsa)

