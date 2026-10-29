# Football — Footy Career

Repo ini mempertahankan 38 screenshot referensi asli di root dan menambahkan game sepak bola **Footy Career** sebagai proyek Godot mandiri di [`FootyCareer/`](FootyCareer/README.md).

- [Buka Preview game yang dapat dimainkan](https://3000-iz9gc069pd639xl308kym-da59e914.sg2.manus.computer/)
- [Source dan panduan Footy Career](FootyCareer/README.md)
- [Lihat GitHub Releases / unduh APK terbaru](https://github.com/tohbobo51/football/releases/latest)

## Jalankan source

Buka `FootyCareer/project.godot` menggunakan Godot 4.7.2, lalu jalankan scene utama. Aset UI, avatar, emblem, formasi, serta ilustrasi latihan dan negosiasi transfer tersedia di dalam source project.

## APK Android

APK sideload pertama sudah tersedia sebagai release asset [`FootyCareer.apk` (v1.0.0)](https://github.com/tohbobo51/football/releases/download/v1.0.0/FootyCareer.apk). Paket ditandatangani dengan debug key sementara sehingga cocok untuk instalasi/uji coba Android; ini bukan build signing produksi Google Play.

Untuk build berikutnya, buka tab **Actions** → **Build Footy Career Android APK** → **Run workflow**, lalu masukkan tag release unik (misalnya `v1.0.1`). Workflow mengunduh Godot 4.7.2 serta toolchain Android yang diperlukan, memakai runner GitHub Actions, memeriksa package/signature/ABI APK, kemudian mengunggah release. Komponen SDK mengikuti lisensi upstream Android; workflow menerima prompt lisensinya pada runner agar pemasangan SDK bisa berlangsung.

Screenshot root dipertahankan apa adanya sebagai referensi desain. Artwork pemain, emblem, dan ilustrasi Footy Career adalah aset game orisinal.
