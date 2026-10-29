# Footy Career

Career manager sepak bola 2D berbahasa Indonesia, dirancang untuk layar ponsel portrait. Game memadukan avatar, emblem klub, visual lapangan/formasi, ilustrasi latihan dan negosiasi transfer, kalender pertandingan, serta navigasi tab—bukan pengalaman yang hanya berupa teks.

## Siklus permainan

1. Buat pemain dan pilih posisi.
2. Pilih program latihan untuk meningkatkan atribut, overall, dan pengalaman dengan memakai energi.
3. Atur formasi/kapten dan mainkan pertandingan pekan ini.
4. Tinjau skor, rating, kontribusi pemain, klasemen, dan reward.
5. Majukan pekan untuk memulihkan energi dan memperbarui jadwal, gaji, serta musim.
6. Ambil keputusan transfer atau kontrak saat tersedia dan terus kembangkan karier.

Progres—profil, atribut, energi, formasi, hasil laga, jadwal, kontrak, serta reputasi—tersimpan lokal di perangkat.

## Jalankan project

- Engine: Godot 4.7.2, renderer GL Compatibility.
- Buka `project.godot` di Godot, lalu jalankan scene utama `scenes/main.tscn`.
- Layar dasar 480×960 portrait dan menyesuaikan ukuran jendela ponsel.
- Bahasa game: Indonesia.

## Android APK

Preset ekspor `Android` membuat APK `dist/FootyCareer.apk`, package `com.tohbobo51.footycareer`, ABI ARM64/ARMv7, minimum SDK 23, dan target SDK 35. Workflow GitHub Actions manual tersedia di [`../.github/workflows/footy-career-android.yml`](../.github/workflows/footy-career-android.yml). Lihat [panduan build Android](docs/android-build.md).

APK release ditandatangani dengan debug key sementara untuk sideloading dan pengujian. APK tersebut bukan signing produksi Google Play.

## Source layout

- `scripts/main.gd` — tab, layar, dan interaksi.
- `scripts/ui/pitch_view.gd` — lapangan serta pengaturan formasi/kapten.
- `scripts/ui/game_fonts.gd`, `autoload/footy_font_theme.gd` — font dan theme UI.
- `autoload/career_state.gd` — aturan karier dan simpan-muat lokal.
- `assets/football/` — artwork pemain, emblem klub, serta ilustrasi latihan dan transfer/kontrak.
- `assets/template/fonts/` — font beserta lisensi upstream.
