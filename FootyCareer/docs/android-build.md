# Build APK Android

Project menggunakan Godot 4.7.2. Preset `Android` menghasilkan `dist/FootyCareer.apk` untuk package `com.tohbobo51.footycareer`, portrait, ARMv7/ARM64, minimum SDK API 23, dan target SDK API 35.

## GitHub Actions

Workflow berada di `.github/workflows/footy-career-android.yml` pada root repo `football`. Jalankan secara manual melalui **Actions → Build Footy Career Android APK → Run workflow**, lalu masukkan tag release yang belum pernah dipakai. Setelah ekspor lolos pemeriksaan isi ZIP, signature, package ID, dan ABI, workflow mengunggah artifact lalu membuat GitHub Release dengan asset `FootyCareer.apk`.

Runner memakai OpenJDK 17, Android Platform 35, Build Tools 35.0.1, NDK r28b (`28.1.13356709`), CMake `3.10.2.4988404`, dan Godot beserta export templates 4.7.2. Android SDK Manager menerima lisensi upstream pada runner agar paket SDK bisa dipasang. Build debug-signed cocok untuk sideloading dan pengujian; jangan gunakan debug key untuk rilis Google Play.

## Ekspor lokal

Sediakan Godot 4.7.2 dengan export templates versi yang sama, JDK 17, serta Android SDK packages sesuai panduan resmi. Dari folder ini:

```sh
mkdir -p dist
godot --headless --path . --export-debug Android dist/FootyCareer.apk
```

## Referensi teknis

- [Godot — Exporting for Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
- [Godot — Android export properties](https://docs.godotengine.org/en/stable/classes/class_editorexportplatformandroid.html)
- [Android Developers — Export Godot projects](https://developer.android.com/games/engines/godot/godot-export)
- [android-actions/setup-android](https://github.com/android-actions/setup-android)
- [firebelley/godot-export](https://github.com/firebelley/godot-export)
