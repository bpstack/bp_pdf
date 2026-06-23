# BP PDF — Instrucciones de build

> Aplicación Flutter local-first para anotar PDFs.  
> Plataformas: **Windows** · **Android** · **Linux**

---

## Prerequisitos comunes

- **Flutter estable** ≥ 3.44 con **Dart** ≥ 3.12  
  Instalado en `C:\src\flutter` (sin espacios, sin admin). Añadir `C:\src\flutter\bin` al PATH de usuario.
- Verificar: `flutter doctor`

---

## Windows (escritorio)

### Requisitos adicionales
| Componente | Versión mínima | Notas |
|---|---|---|
| Visual Studio Build Tools 2022 | 17.x | Workload **"Desktop development with C++"** |
| Modo Desarrollador de Windows | — | Necesario para symlinks en el build (R3) |

Activar Modo Desarrollador: *Configuración → Sistema → Para desarrolladores → Activar*.

### Build debug (desarrollo)
```powershell
flutter run -d windows
```

### Build release
```powershell
flutter build windows --release
```
El instalable queda en `build\windows\x64\runner\Release\`.

---

## Android

### Requisitos adicionales
| Componente | Notas |
|---|---|
| Android Studio (o solo SDK) | Instalar desde https://developer.android.com/studio |
| Android SDK Build-Tools | `flutter doctor --android-licenses` para aceptar licencias |
| Dispositivo físico o emulador | API 21+ (Android 5.0) recomendado API 33+ |

> ⚠️ **R13 — Acceso a archivos en Android (SAF):** el flujo de apertura vía  
> Storage Access Framework está implementado y testeado en unitarios, pero  
> **no validado en dispositivo real** (pendiente Fase 6). Si el PDF no carga,  
> comprobar que `pdfrx.openData` funciona con la URI SAF.

### Build debug
```bash
flutter run -d <device-id>
```

### Build release (APK)
```bash
flutter build apk --release
# APK en build/app/outputs/flutter-apk/app-release.apk
```

### Build release (App Bundle para Play Store)
```bash
flutter build appbundle --release
# AAB en build/app/outputs/bundle/release/app-release.aab
```

---

## Linux

> ⚠️ **R2 — Native Assets + pdfium en Linux:** pdfrx usa Dart Native Assets  
> para empaquetar pdfium. Validar que `flutter run -d linux` compila antes de  
> distribuir. En algunos entornos puede requerir flag de experimento o Flutter  
> más reciente.

### Requisitos (Ubuntu / Debian)
```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```

> ⚠️ **Compilar sobre un sistema de archivos nativo Linux (ext4), NO sobre una
> partición NTFS montada** (p. ej. una unidad Windows en un equipo dual-boot). El
> build de pdfium (FFI) usa symlinks y permisos POSIX que fallan en NTFS. Si el
> proyecto está en una partición Windows, cópialo a `~/` (o cualquier ruta ext4)
> antes de compilar.

> ℹ️ **Portales del SO:** el selector de archivos (`file_selector`) usa los
> portales de escritorio. Si el diálogo de abrir/guardar no aparece, instala
> `xdg-desktop-portal` (y un backend, p. ej. `xdg-desktop-portal-gtk`).

En **WSL** (build desde Windows): instalar Flutter propio dentro de WSL con los paquetes anteriores.

### Build debug
```bash
flutter run -d linux
```

### Build release
```bash
flutter build linux --release
# Binario en build/linux/x64/release/bundle/
```

---

## Generar código (freezed / json_serializable)

Necesario tras modificar entidades de dominio (`annotation.dart`, `page_rect.dart`, `pdf_point.dart`):

```bash
dart run build_runner build
```

---

## Tests

```bash
flutter test          # todos los tests
flutter analyze       # análisis estático (debe dar 0 issues)
```
