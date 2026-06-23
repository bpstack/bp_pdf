# Roadmap técnico — Limitaciones conocidas y trabajo futuro

Estado honesto del proyecto: qué está pendiente y por qué. No hay bugs activos
conocidos a fecha de hoy.

---

## Limitaciones conocidas

- **Firma de distribución:** los binarios se distribuyen sin certificado de pago.
  - Windows: el `.exe` mostrará el aviso de SmartScreen ("editor desconocido").
  - Android: el APK usa la clave de depuración de Flutter. Para subir a Google
    Play hay que crear un keystore propio y configurar la firma en
    `android/app/build.gradle.kts`.

---

## Trabajo futuro

- **Más cobertura de tests:** las carpetas `test/app/`, `test/core/` y
  `test/services/` están vacías. Añadir tests de integración y de widgets para
  las features principales a medida que el proyecto crezca.

- **Empaquetado Linux más robusto:** ofrecer un AppImage o `.deb`/Flatpak
  (incluyen dependencias) en lugar de solo un tar.gz portable.

---

## Automatización futura (GitHub Actions)

> **Cuándo vale la pena:** cuando haya más de un colaborador, o cuando publiques
> versiones con frecuencia (más de una al mes). Con un solo desarrollador y
> releases ocasionales, hacerlo a mano es perfectamente válido.

- **CI en cada push** — ejecutar `flutter analyze` + `flutter test` automáticamente.
  Corre en Linux (rápido, gratis). Evita subir código roto sin darte cuenta.

- **Release automático al crear un tag** — compilar APK + ZIP Windows y subirlos
  a GitHub Releases solos. Útil cuando los releases sean frecuentes.

  > El build de Windows tarda ~15-20 min en los servidores de GitHub. Dispararlo
  > solo en tags, no en cada push.
