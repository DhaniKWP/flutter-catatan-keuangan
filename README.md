
# 💰 Flutter Catatan Keuangan

Aplikasi **Flutter Catatan Keuangan** adalah aplikasi pencatat pemasukan dan pengeluaran harian yang sederhana namun fungsional. Cocok digunakan untuk mengelola keuangan pribadi secara efisien dan modern langsung dari perangkat mobile.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)
![License](https://img.shields.io/github/license/DhaniKWP/flutter-catatan-keungan)

---

## ✨ Fitur Utama

- 📥 Tambah pemasukan
- 📤 Tambah pengeluaran
- 📊 Rekap ringkas bulanan
- 📅 Filter transaksi berdasarkan tanggal
- 🔎 Pencarian transaksi
- 🎨 UI sederhana dan mudah digunakan
- 📱 Support Android (dan iOS jika dikonfigurasi)

---

## 📸 Screenshot

| Home | Tambah Transaksi | Grafik Bulanan |
|------|------------------|----------------|
| ![home](assets/screenshots/home.jpg) | ![add](assets/screenshots/add.png) | ![chart](assets/screenshots/chart.png) |

> *Tambahkan screenshot kamu ke dalam folder `assets/screenshots/` untuk menampilkan preview aplikasi di atas.*

---

## 🚀 Instalasi & Menjalankan Aplikasi

1. **Clone repositori ini**
   ```bash
   git clone https://github.com/DhaniKWP/flutter-catatan-keungan.git
   cd flutter-catatan-keungan
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Jalankan di emulator atau device**
   ```bash
   flutter run
   ```

---

## 🛠️ Stack & Teknologi

- **Flutter** – UI toolkit dari Google
- **Dart** – Bahasa pemrograman utama
- **Shared Preferences / SQLite** *(tergantung implementasi)* – Untuk penyimpanan data lokal
- **Provider** *(opsional)* – Untuk state management
- **charts_flutter** – Untuk grafik keuangan

---

## 📦 Build APK

Untuk membuild aplikasi menjadi APK:
```bash
flutter build apk --release
```

---

## 🤝 Kontribusi

Kontribusi sangat terbuka! Jika kamu ingin membantu mengembangkan fitur atau memperbaiki bug:

1. Fork repo ini
2. Buat branch fitur (`git checkout -b fitur-baru`)
3. Commit perubahan (`git commit -m 'Tambah fitur'`)
4. Push ke branch (`git push origin fitur-baru`)
5. Buat pull request

---

## 📄 Lisensi

Project ini menggunakan lisensi [MIT](LICENSE).

---

## 🙋 Tentang Developer

Created with ❤️ by [DhaniKWP](https://github.com/DhaniKWP)
