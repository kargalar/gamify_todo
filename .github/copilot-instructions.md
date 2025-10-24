---
applyTo: '*
---
Provide project context and coding guidelines that AI should follow when generating code, answering questions, or reviewing changes.
- Her zaman clean code prensiplerine göre kod yaz:
- Hiçbir dosya 600 satırı geçmesin.
- Her dosya tek sorumluluk taşısın (SRP).
- Componentleri küçük tut, UI ve business logic’i ayır.
- Feature-based klasör yapısı uygula.
- UI parçalarını atomic design (atoms, molecules, organisms, pages) mantığına göre ayır.
- Tekrarlayan kodları custom hook veya utils içine taşı.
- uygulamda hatalar gerçekleşiyor ama çoğu zaman göremiyor. bundan sonra yazdığım kodlar için debug panelde mesajı için kodlar da ekle. hata veya başarılı olma durumlarında.
Eğer Color kullanman gerekiyors AppColors Sınıfından çağır.

hiçbir zaman build alma veya uygulamaıy başlatma
*'
---
