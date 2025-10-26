# 🧪 Timer Shimmer Animasyonu - Test Kılavuzu

## ⚡ Hızlı Başlangıç

### 1️⃣ Uygulamayı Çalıştırın
```bash
flutter run
```

### 2️⃣ Timer Task'ı Oluşturun
- **Home Page** → `+` düğmesine basın
- Task türü olarak **"Timer"** seçin
- Başlık girin (ör: "10 Dakika Egzersiz")
- Süresi ayarlayın (ör: 10 minutes)
- Kaydedin

### 3️⃣ Timer'ı Başlatın
- Task itemde **Play (▶️)** düğmesine basın
- ✨ **SHIMMER EFEKTİ BAŞLAYACAK!**
- Container'da yumuşak bir parlama animasyonu göreceksiniz

### 4️⃣ Debug Mesajlarını İzleyin
Logcat/Console'da göreceksiniz:
```
✨ [SHIMMER] Timer aktif - Animasyon başladı: "10 Dakika Egzersiz"
🌟 [SHIMMER] Stil: TaskItemStyle.card - Parlama döngüsü: 2500ms
```

### 5️⃣ Timer'ı Durdurun
- **Pause (⏸️)** düğmesine basın
- Shimmer efekti anında kaybolur
- Logcat'te görünür:
```
⏹️ [SHIMMER] Timer durdu - Animasyon sona erdi: "10 Dakika Egzersiz"
```

---

## 🎨 Stil Testleri

Farklı task styles'da shimmer'ı test edin:

### Settings → Appearance → Task Style

#### 1. **Card Style** (Default) ✅
- En çok shimmer görülür
- Renk: Panel background
- Etkisi: Güçlü ve belirgin

#### 2. **Minimal Style** ✅
- Hafif ve zarif
- Renk: Background
- Etkisi: Subtle parlama

#### 3. **Flat Style** ✅
- Sınırla ayırılmış
- Renk: Background
- Etkisi: Çizginin parlattığını gözlemleyin

#### 4. **Glass Style** ✅
- Şeffaf görünümle
- Renk: Background
- Etkisi: Cam etkilisi ile parlama

#### 5. **Modern Style** ✅
- Minimalist tasarımda
- Renk: Background
- Etkisi: Contemporary ve modern

---

## 📊 Test Senaryoları

### Senaryo 1: Müşteri Deneyimi
```
1. App'ı aç
2. Timer task oluştur
3. Timer başlat
4. Ekranda dolaş (diğer sayfalar)
5. Geri dön - shimmer hala aktif mi? ✅
6. Timer bitene kadar bekle
7. Otomatik olarak sona mi erdi? ✅
```

### Senaryo 2: Çoklu Timerler
```
1. 3 farklı Timer task oluştur
2. Hepsini başlat
3. Tüm task'lar shimmer gösteriyor mu? ✅
4. Performance sorun var mı? (Check FPS)
5. Birini durdur - sadece o sona erdi mi? ✅
```

### Senaryo 3: Animasyon Performansı
```
1. Timer başlat - FPS 60 mı?
2. Ekran kaydır - smooth animasyon mı?
3. Hızlı kaydırma - lag var mı?
4. Arka plana git (minimize) - pause edildi mi?
5. Tekrar aç - animasyon devam ediyor mu?
```

---

## 🔍 Debug Mesajlarında Neler Aranacak?

✅ **Başarılı Başlangıç:**
```
✨ [SHIMMER] Timer aktif - Animasyon başladı: "Task Name"
🌟 [SHIMMER] Stil: TaskItemStyle.card - Parlama döngüsü: 2500ms
```

✅ **Başarılı Durma:**
```
⏹️ [SHIMMER] Timer durdu - Animasyon sona erdi: "Task Name"
```

❌ **Sorun İşaretleri:**
- Mesajlar görünmüyor → Timer state değişimi algılanmadı
- Mesaj tekrar ediyor → Memory leak olabilir
- FPS düşüyor → Performance problemi

---

## 🎯 Test Kontrol Listesi

- [ ] Shimmer efekti timer başladığında başlıyor
- [ ] Shimmer efekti timer durduğunda biliyor
- [ ] 2500ms döngü smooth ve düzgün
- [ ] Tüm stiller'de shimmer gösteriliyor
- [ ] Debug mesajları doğru zamanda gözüküyor
- [ ] Birden fazla timer aynı anda çalışabiliyor
- [ ] App minimize olurken sorun yok
- [ ] FPS 60 kalıyor
- [ ] Bellek sızıntısı yok
- [ ] Completion/Fail animasyonları etkilenmiyor

---

## 🚀 Optimizasyon İpuçları

Eğer performance sorun yaşıyorsanız:

1. **Animasyon Hızını Düşür:**
   ```dart
   period: const Duration(milliseconds: 3500), // 2500'den artır
   ```

2. **Opacity Azalt:**
   - Highlight color'ın alpha değerini düşür
   - `0.5` yerine `0.3` dene

3. **GPU Hızlandırma:**
   - DevTools Performance tab'ını açın
   - GPU rendering'i enable et

4. **Profiler Çalıştır:**
   ```bash
   flutter run --profile
   ```

---

## 📱 Cihazlar Arası Test

| Cihaz | Min FPS | Test Durumu |
|-------|---------|-------------|
| iPhone 13+ | 120fps | ✅ Smooth |
| Android High-End | 120fps | ✅ Smooth |
| Android Mid-Range | 60fps | ⚠️ Test et |
| Android Low-End | 30fps | ⚠️ Optimize et |

---

## 💡 İleri Testler

### A/B Testing
- Shimmer öncesi vs sonrası timer fark etme
- User engagement metriğini ölç

### Accessibility
- Screen reader ile test et
- Kontrast yeterli mi?
- Dark mode'da ne görünüyor?

### Internationalization (i18n)
- Farklı dillerde debug mesajları
- RTL (sağdan sola) yazılı diller

---

## 📝 Not Almak

Test sırasında bulduğunuz şeyler:

```
Tarih: 26.10.2025
Stil: Card
Cihaz: iPhone 13
FPS: 60
Bulgu: ✨ Parlama efekti mükemmel görünüyor
Öneri: Hız biraz daha yavaş olabilir (3000ms)
```

---

**Başarılı testler! Geri bildirim için [TIMBER_SHIMMER_FEATURE.md](./TIMER_SHIMMER_FEATURE.md) dosyasını kontrol et.**
