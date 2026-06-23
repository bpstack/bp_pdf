# ROADMAP — Editor de PDF local (BP PDF)

> Documento vivo. Es la **fuente de verdad** del proyecto. Cualquier modelo o
> persona que trabaje aquí debe leerlo entero antes de tocar código y mantenerlo
> actualizado. Las decisiones marcadas como **FIJAS** no se reabren sin acuerdo
> explícito.
>
> Estado del documento: ✅ **COMPLETO** — listo para handoff a un modelo ejecutor.
> Secciones: 1. Visión (+alcance 1.7) · 2. Decisiones técnicas · 3. Arquitectura/árbol ·
> 4. Dependencias (+compatibilidad) · Fases 0–6 (checklist) · 7. Riesgos (R1–R13) ·
> 8. Reglas para el modelo · Apéndice (mapa funcionalidades→fase).
> Versiones verificadas en pub.dev y decisiones de alcance cerradas: 2026-06-03.

---

## 1. Visión y restricciones

### 1.1 Qué es

Aplicación de escritorio y móvil para **editar y anotar archivos PDF de forma
totalmente local**, pensada para uso personal. Una sola base de código en Flutter
que corre en varias plataformas.

### 1.2 Principios rectores (no negociables)

- **Local-first:** todo el trabajo ocurre en el dispositivo. Los PDF **nunca
  salen** de la máquina del usuario.
- **Privacidad por diseño:** sin telemetría, sin tracking, sin analítica remota.
- **Original intacto:** una edición nunca modifica el archivo original; siempre
  se guarda/exporta una **copia**.
- **Offline real:** la app es 100% funcional sin conexión a Internet.
- **Cero fricción:** sin cuentas, sin registro, sin login para usarla.

### 1.3 Restricciones duras (lo que el proyecto NO tendrá)

- ❌ Servidor / backend propio
- ❌ Base de datos remota
- ❌ Cuentas de usuario
- ❌ Sincronización en la nube
- ❌ Conexión obligatoria a Internet
- ❌ Publicidad
- ❌ Suscripciones / compras
- ❌ Telemetría o envío de datos a terceros

### 1.4 Plataformas objetivo

| Plataforma | ¿Soportada? | Notas |
|------------|-------------|-------|
| Android    | ✅ Sí       | Móvil principal |
| Windows    | ✅ Sí       | Escritorio |
| Linux      | ✅ Sí       | Escritorio (mayor riesgo en libs nativas) |
| iOS        | ❌ No       | Fuera del alcance. No se diseña para ello. |
| macOS      | ❌ No       | Fuera del alcance. |
| Web        | ❌ No       | Fuera: sistema de archivos limitado y libs PDF distintas. |

**Una sola base de código** para las 3 plataformas soportadas (Android, Windows,
Linux). **FIJO.** No se invierte esfuerzo en abstraer para Apple ni Web.

### 1.5 Modelo de uso y distribución  — **FIJO**

Se contempla una **posible publicación / distribución / monetización futura**.

Consecuencia directa (vinculante para la Sección 2):

- ✅ Solo se usarán librerías **open-source con licencia permisiva** (MIT, BSD,
  Apache-2.0).
- ❌ **Prohibidas** librerías de pago o con licencia comercial/community
  restringida (p. ej. **Syncfusion queda descartada**).
- Implicación técnica: el **export con anotaciones** (Fase 4) se resolverá de
  forma artesanal con paquetes libres (compositar sobre el PDF), no con SDKs
  comerciales. Se detalla en la Sección 2.

### 1.6 Nombre

- Nombre del repo: `bp_pdf`.
- Nombre visible de la app: **BP PDF**.

### 1.7 Alcance v1 y fuera de alcance — **FIJO**

**Dentro de v1:**
- Las 16 funcionalidades originales (ver Apéndice).
- **Guardar y reabrir sesiones de edición ("proyectos")** — el usuario puede
  cerrar y continuar después sin re-anotar (Fase 5).
- **Un solo documento abierto a la vez** (single-document). Estado y UI simples.
- **Idioma: solo español.** Sin internacionalización (i18n) en v1 — strings
  directos en español, sin `flutter_localizations`.

**Fuera de alcance (el modelo NO debe implementarlo ni inventarlo):**
- Editar el **texto original** del PDF (solo se cubre y anota encima).
- **Reordenar, borrar, rotar o añadir** páginas.
- Fusionar/dividir PDFs.
- Cualquier funcionalidad de la lista "Funciones futuras" (solo interfaces).
- Multi-idioma, multi-documento, multi-ventana.

---

## 2. Decisiones técnicas — **FIJAS**

> No se reabren sin acuerdo explícito. Justifican el resto del proyecto.

### 2.1 Renderizado de PDF → **pdfrx** (MIT)

- Motor **pdfium** vía FFI. Render rápido y fiel.
- Cubre Android + Windows + Linux. Aporta: multipágina, zoom, navegación,
  miniaturas, selección de texto y búsqueda (útil para funciones futuras).
- **Es solo VISOR/render**: NO escribe anotaciones de vuelta al PDF. Por eso la
  edición vive en una capa propia (2.2) y el export se compone aparte (2.4).
- **Split del paquete (importante para la arquitectura):** el widget visor
  `pdfrx` se usa en la capa **`presentation`** (es UI). El `pdfrx_engine`
  (render a imagen sin Flutter) se usa en la capa **`data`** para rasterizar al
  exportar. El `domain` no importa ninguno de los dos.

### 2.2 Arquitectura de capas (visor + anotación)

```
┌─────────────────────────────────────┐
│  Capa de anotación (Flutter canvas)  │  ← texto, dibujo, resaltado, "tipp-ex"
│  CustomPainter / Stack sobre la pág. │     Estado nuestro. Editable. Undo/redo.
├─────────────────────────────────────┤
│  Visor pdfrx (página renderizada)    │  ← solo lectura, debajo
└─────────────────────────────────────┘
```

- El usuario NO edita el texto original; **lo cubre y escribe encima**.
- "Tipp-ex" = rectángulo opaco (blanco u otro color) en la capa de anotación.
- Coordenadas de anotación guardadas **relativas a la página** (no a píxeles de
  pantalla) para que el zoom y el export sean fieles.

### 2.3 Gestión de estado → **Riverpod**

- Estado del documento = lista ordenada (z-order) de objetos de anotación
  inmutables. Tipos: `TextAnno`, `StrokeAnno` (dibujo), `HighlightAnno`,
  `RectAnno` (tipp-ex/ocultar).
- **Undo/redo** = pila de estados (o de comandos) sobre esa lista.
- Modelo serializable (JSON) → es la base de la **persistencia de proyectos**
  (Fase 5): guardar/reabrir la sesión de edición sin tocar el PDF original.

### 2.4 Export / guardado → **pdf** + **printing** (MIT / Apache-2.0)

- Estrategia v1 = **Opción A (rasterizar)** — **FIJA**:
  1. Renderizar cada página original a imagen con pdfrx (a DPI configurable).
  2. Crear PDF nuevo respetando el **tamaño y orientación reales de cada página**
     (pueden variar entre páginas): colocar la imagen al tamaño de página correcto.
  3. Dibujar encima las anotaciones (texto, trazos, resaltados, rects) con sus
     fuentes/tamaños/colores.
  4. Guardar como **archivo NUEVO**. El original **nunca** se modifica.
- Coste asumido: se pierde la capa de texto seleccionable del original. Aceptable
  porque el flujo es "tapar y anotar", no editar texto inline.
- **Opción B (overlay vectorial manteniendo texto)** = mejora futura; requeriría
  FFI a pdfium. Anotada, no planificada.

### 2.5 Fuentes para anotación de texto

- Set **curado** de tipografías TTF empaquetadas como assets. Set inicial
  (todas licencia **OFL / Apache-2.0**, embebibles y seguras para publicar):
  **Roboto, Open Sans, Lato, Merriweather, Source Code Pro**.
- Se embeben en el PDF al exportar (requisito del paquete `pdf`).
- El usuario elige **familia (del set), tamaño y color**. No se usan fuentes
  arbitrarias del sistema.
- **Regla:** cualquier fuente que se añada debe tener licencia que permita
  **embebido y redistribución** (verificar antes de incluir el TTF).

### 2.6 Licencias — control

- Toda dependencia debe ser **MIT / BSD / Apache-2.0**. Antes de añadir cualquier
  paquete nuevo se verifica su licencia y se anota en la Sección 4.
- Syncfusion y cualquier SDK comercial: **prohibidos** (ver 1.5).

---

## 3. Arquitectura y árbol de carpetas — **FIJA**

### 3.1 Estilo: Clean Architecture *feature-first* en 3 capas

Cada funcionalidad ("feature") se organiza en 3 capas con una **regla de
dependencia estricta** (las flechas indican "depende de"):

```
  presentation  ──►  domain  ◄──  data
   (UI + estado)    (núcleo)     (infra)
```

- **`domain`** es el centro y **no depende de nada** (ni de Flutter, ni de
  pdfrx, ni de paquetes externos). Define entidades + interfaces abstractas
  (contratos) + casos de uso.
- **`data`** implementa los contratos del domain usando paquetes concretos
  (pdfrx, pdf, printing, file pickers…). Es reemplazable.
- **`presentation`** consume el domain a través de providers Riverpod. No conoce
  los detalles de `data`.

Esto es **Dependency Inversion** (la "D" de SOLID): el núcleo no depende de la
infraestructura; la infraestructura depende del núcleo. Cambiar pdfrx por otra
lib en el futuro = tocar solo `data`, sin romper UI ni lógica.

### 3.2 Árbol de carpetas

```
bp_pdf/
├─ lib/
│  ├─ main.dart                  # punto de entrada. Solo arranca runApp.
│  │
│  ├─ app/                       # composición de la app (no lógica de negocio)
│  │  ├─ app.dart                # MaterialApp, ProviderScope, router
│  │  ├─ theme/                  # tema claro/oscuro, colores, tipografías UI
│  │  └─ router/                 # definición de rutas/navegación
│  │
│  ├─ core/                      # transversal, sin depender de ninguna feature
│  │  ├─ errors/                 # Failure, excepciones tipadas
│  │  ├─ result/                 # tipo Result<T> (éxito/fallo) para casos de uso
│  │  ├─ extensions/             # extensiones Dart/Flutter reutilizables
│  │  ├─ constants/              # constantes globales (límites, claves)
│  │  └─ utils/                  # helpers puros (geometría, conversión coords)
│  │
│  ├─ shared/                    # UI reutilizable entre features
│  │  └─ widgets/                # botones, diálogos, toolbars genéricas
│  │
│  ├─ features/
│  │  ├─ pdf_viewer/             # FASE 1 — abrir y visualizar
│  │  │  ├─ domain/
│  │  │  │  ├─ entities/         # PdfDocumentRef, PdfPageInfo
│  │  │  │  ├─ repositories/     # PdfRepository (abstracto)
│  │  │  │  └─ usecases/         # OpenPdf, GetPageCount...
│  │  │  ├─ data/
│  │  │  │  ├─ repositories/     # PdfRepositoryImpl (usa pdfrx)
│  │  │  │  └─ datasources/      # PdfrxDataSource (wrapper directo de pdfrx)
│  │  │  └─ presentation/
│  │  │     ├─ providers/        # estado del visor (página actual, zoom)
│  │  │     ├─ screens/          # ViewerScreen
│  │  │     └─ widgets/          # PageView, ThumbnailRail, ZoomControls
│  │  │
│  │  ├─ annotation/             # FASES 2-3 — capa de edición
│  │  │  ├─ domain/
│  │  │  │  ├─ entities/         # Annotation (sealed): Text/Stroke/Highlight/Rect
│  │  │  │  ├─ repositories/     # AnnotationStore (abstracto)
│  │  │  │  └─ usecases/         # AddAnnotation, MoveAnnotation, Undo, Redo
│  │  │  ├─ data/
│  │  │  │  └─ repositories/     # AnnotationStoreImpl (pila undo/redo, JSON)
│  │  │  └─ presentation/
│  │  │     ├─ providers/        # estado anotaciones + herramienta activa
│  │  │     ├─ painters/         # CustomPainter por tipo de anotación
│  │  │     └─ widgets/          # AnnotationLayer, ToolPanel, FontPicker
│  │  │
│  │  ├─ export/                 # FASE 4 — guardar/exportar
│  │  │  ├─ domain/
│  │  │  │  ├─ repositories/     # PdfExporter (abstracto)
│  │  │  │  └─ usecases/         # ExportToNewPdf
│  │  │  ├─ data/
│  │  │  │  └─ repositories/     # RasterPdfExporter (Opción A: pdf+printing)
│  │  │  └─ presentation/
│  │  │     └─ providers/        # estado del proceso de export
│  │  │
│  │  └─ project/                # FASE 5 — guardar/reabrir sesión de edición
│  │     ├─ domain/
│  │     │  ├─ entities/         # EditProject (ref. al PDF copiado + anotaciones)
│  │     │  ├─ repositories/     # ProjectRepository (abstracto)
│  │     │  └─ usecases/         # SaveProject, OpenProject, ListProjects
│  │     ├─ data/
│  │     │  └─ repositories/     # ProjectRepositoryImpl (JSON + copia de PDF)
│  │     └─ presentation/
│  │        ├─ providers/        # estado de proyectos
│  │        └─ screens/          # lista/gestión de proyectos
│  │
│  ├─ services/                  # infraestructura compartida entre features
│  │  ├─ file_service/           # abrir/guardar/picker (abstracción + impl)
│  │  ├─ storage_service/        # rutas locales, persistir "proyectos" (JSON)
│  │  └─ font_registry/          # catálogo de fuentes TTF embebibles
│  │
│  └─ features_future/           # ⚠️ solo INTERFACES preparadas, sin implementar
│     ├─ signature/              # firma manuscrita
│     ├─ stamps/                 # sellos
│     ├─ search/                 # búsqueda de texto
│     ├─ notes/                  # comentarios / notas adhesivas
│     ├─ ocr/                    # OCR local
│     ├─ encryption/             # cifrado / contraseña
│     └─ reading_mode/           # modo lectura
│
├─ assets/
│  └─ fonts/                     # TTF curados que se embeben al exportar
│
├─ test/                         # espejo de lib/ (unit + widget tests)
│  ├─ features/
│  └─ services/
│
└─ ROADMAP.md                    # este documento
```

### 3.3 Rol de cada carpeta (resumen)

| Carpeta | Rol | Regla |
|---------|-----|-------|
| `app/` | Ensambla la app (tema, router, ProviderScope) | Sin lógica de negocio |
| `core/` | Utilidades transversales puras | No importa features |
| `shared/` | Widgets UI reutilizables | Sin estado de negocio |
| `features/*/domain` | Entidades + contratos + casos de uso | **No importa Flutter ni libs** |
| `features/*/data` | Implementa contratos con libs reales | Reemplazable |
| `features/*/presentation` | UI + providers Riverpod | Consume domain, no data |
| `services/` | Infra compartida (archivos, fuentes, storage) | Expone interfaces |
| `features_future/` | Solo interfaces/stubs preparados | **No implementar aún** |

### 3.4 Cómo encajan SOLID

- **S (Responsabilidad única):** cada capa y cada usecase hace una cosa.
- **O (Abierto/cerrado):** nuevos tipos de anotación = nueva subclase de la
  entidad `Annotation` + su painter, sin tocar las existentes.
- **L (Sustitución):** las impl de `data` son intercambiables tras su interfaz.
- **I (Segregación):** interfaces pequeñas (`PdfRepository`, `PdfExporter`,
  `AnnotationStore`) en vez de una "God interface".
- **D (Inversión):** ya descrito en 3.1 — el domain manda, la infra obedece.

### 3.5 Puntos de extensión para el futuro (sin implementar ahora)

- **Nuevas anotaciones** (firma, sello, nota) → nueva subclase de `Annotation`
  (sealed) + painter + entrada en el panel de herramientas. El resto no cambia.
- **Búsqueda / OCR / modo lectura** → nuevas features con su tripleta
  domain/data/presentation; reutilizan `PdfRepository`.
- **Cifrado / contraseña** → se inserta como paso en el pipeline de export y en
  la apertura (decorador sobre `PdfRepository` / `PdfExporter`).
- Carpeta `features_future/` deja los huecos visibles para que nadie improvise
  la ubicación.

---

## 4. Dependencias — **FIJA** (la lista; las versiones se resuelven al instalar)

> ✅ **Versiones verificadas en pub.dev el 2026-06-03.** Se anota la última
> estable de ese día como referencia. Al instalar se usa `flutter pub add`
> (resuelve la última compatible). **Reconfirmar en pub.dev antes de empezar** si
> ha pasado tiempo. **Antes de añadir cualquier paquete NUEVO: verificar licencia
> (MIT/BSD/Apache-2.0) y anotarlo aquí.**

### 4.1 Dependencias de runtime

| Paquete | Última estable (2026-06-03) | Para qué | Licencia |
|---------|------|----------|----------|
| `pdfrx` | **2.4.3** | Render del PDF (motor pdfium). Visor multipágina, zoom, miniaturas, búsqueda. | MIT |
| `pdf` | **3.12.0** | **Generar** el PDF de salida (export Opción A). Dibuja imágenes/texto/formas. | Apache-2.0 |
| `printing` | **5.14.3** | Compañero de `pdf`: rasterizar páginas y diálogo de impresión/compartir. | Apache-2.0 |
| `flutter_riverpod` | **3.3.1** | Gestión de estado. ⚠️ **Major 3.x** (ver 4.5). | MIT |
| `riverpod_annotation` | **4.0.2** | Anotaciones para generar providers (code-gen). *Opcional.* Empareja con Riverpod 3. | MIT |
| `file_selector` | **1.1.0** | Abrir y elegir destino de guardado. **Oficial (flutter.dev)**, Android+Windows+Linux. | BSD-3 |
| `path_provider` | **2.1.5** | Directorios estándar de la app. Oficial. | BSD-3 |
| `path` | ^1.9 | Manipular rutas de forma portable. Oficial. | BSD-3 |
| `freezed_annotation` | **3.1.0** | Anotaciones para clases inmutables/`sealed`. Empareja con freezed 3. **Usado desde Fase 2.** | MIT |
| `json_annotation` | **4.12.0** | Anotaciones para (de)serializar anotaciones a JSON. **Usado desde Fase 2.** | BSD-3 |
| `uuid` | **4.5.3** | IDs únicos por anotación. **Usado desde Fase 2.** | MIT |
| `flutter_colorpicker` | **1.1.0** | Selector de color. *UI, sustituible.* | MIT |

#### Fuentes TTF del set curado (Fase 2)

| Familia | TTF | Licencia | Origen |
|---|---|---|---|
| **Roboto** | `assets/fonts/Roboto-Regular.ttf` | Apache-2.0 | [googlefonts/roboto](https://github.com/googlefonts/roboto) |
| **Open Sans** | `assets/fonts/OpenSans-Regular.ttf` | OFL-1.1 | [googlefonts/opensans](https://github.com/googlefonts/opensans) |
| **Lato** | `assets/fonts/Lato-Regular.ttf` | OFL-1.1 | [google/fonts `ofl/lato`](https://github.com/google/fonts/tree/main/ofl/lato) |
| **Merriweather** | `assets/fonts/Merriweather-Regular.ttf` | OFL-1.1 | [SorkinType/Merriweather](https://github.com/SorkinType/Merriweather) |
| **Source Code Pro** | `assets/fonts/SourceCodePro-Regular.ttf` | OFL-1.1 | [adobe-fonts/source-code-pro](https://github.com/adobe-fonts/source-code-pro) |

> Todas las fuentes permiten **embebido y redistribución** (requisito ROADMAP §2.5).
> Solo se incluye Regular en Fase 2; las Bold/Italic se añadirán si la UI lo requiere.

### 4.2 Dependencias de desarrollo (dev_dependencies)

| Paquete | Última estable (2026-06-03) | Para qué | Licencia |
|---------|------|----------|----------|
| `build_runner` | **2.15.0** | Ejecuta la generación de código (freezed/json/riverpod). | BSD-3 |
| `freezed` | **3.2.5** | Genera clases inmutables/`sealed`. ⚠️ **Major 3.x** (ver 4.5). | MIT |
| `json_serializable` | **6.14.0** | Genera (de)serialización JSON. | BSD-3 |
| `riverpod_generator` | **4.0.3** | Genera providers. *Si se usa code-gen.* Empareja con Riverpod 3. | MIT |
| `custom_lint` + `riverpod_lint` | última | Reglas de lint de Riverpod. *Opcional.* | MIT |
| `flutter_lints` | **6.0.0** | Reglas de análisis estático recomendadas. Oficial. | BSD-3 |

### 4.3 Justificación de las decisiones de paquete

- **`file_selector` en vez de `file_picker`:** es el paquete **oficial** de
  flutter.dev, licencia BSD limpia y buen soporte de **escritorio Linux/Windows**
  (incluye `getSaveLocation` para "guardar como"). `file_picker` tiene más
  features pero menos garantías de mantenimiento multiplataforma. Si en el futuro
  falta algo (p. ej. filtros avanzados), se reevalúa.
- **`freezed` para las anotaciones:** el modelo de anotaciones es un **tipo
  unión** (`sealed`: Text/Stroke/Highlight/Rect). freezed da inmutabilidad,
  `copyWith` e igualdad por valor → ideal para la **pila de undo/redo** (cada
  estado es inmutable) y para serializar a JSON.
- **`pdf` + `printing` juntos:** `printing` aporta el rasterizado de páginas
  (Opción A) y los diálogos del SO; `pdf` construye el documento final. Misma
  familia de autor, encajan sin fricción.
- **Code-gen (riverpod_generator) es opcional:** se puede empezar con Riverpod
  "a mano" en Fase 0-1 y adoptar code-gen cuando el número de providers crezca.
  No bloquea nada.

### 4.4 Sin dependencias para…

- **Dibujo a mano alzada / resaltado / rect:** se hace con `CustomPainter` nativo
  de Flutter. **No** se añade paquete de dibujo.
- **Temas claro/oscuro:** `ThemeData`/`ColorScheme` nativos. Sin paquete.

### 4.5 Compatibilidad y avisos — **LEER ANTES DE CODIFICAR**

Verificado contra la documentación de pub.dev (2026-06-03):

**SDK requerido**
- Usar **Flutter estable reciente** (Dart **3.7+**). Lo exigen freezed 3 (algunas
  features) y el ecosistema Riverpod 3. Fijar `environment: sdk: '>=3.7.0'` en
  `pubspec.yaml` (ajustar al Dart de tu Flutter instalado).

**pdfrx 2.x — lo más sensible (afecta Fase 0 y Fase 5)**
- Plataformas oficiales: Android, iOS, Windows, macOS, Linux, Web → cubre las 3
  nuestras de sobra.
- Usa **Dart Native Assets** para empaquetar PDFium → **no** requiere cmake,
  descargas manuales ni red en tiempo de build. Pero Native Assets es una
  característica de Flutter relativamente nueva: **requiere Flutter reciente** y,
  según versión, puede pedir flag de experimento. **Validar en Fase 0** que
  `flutter run` en Linux y Windows compila pdfrx antes de avanzar.
- **Windows:** hay que **activar el "Modo de desarrollador"** (usa symlinks en el
  build). Documentar en instrucciones de build (Fase 5).
- Arquitectura partida: **`pdfrx`** (widgets Flutter) + **`pdfrx_engine`**
  (parseo/render SIN dependencia de Flutter). Útil para nuestra capa `data`:
  el `domain` permanece puro y la implementación puede apoyarse en `pdfrx_engine`.

**Riverpod 3.x — MAJOR (cambios de API vs 2.x)**
- ⚠️ **Trampa para el modelo ejecutor:** la mayoría de tutoriales/respuestas de
  internet son de **Riverpod 2.x** y NO aplican igual. Seguir **solo la doc
  oficial de Riverpod 3.x**. `riverpod_annotation` 4.x / `riverpod_generator` 4.x
  son los que emparejan con `flutter_riverpod` 3.x (ojo al desfase de números).

**freezed 3.x — MAJOR (cambio de sintaxis vs 2.x)**
- En freezed 3 las clases deben declararse **`sealed`** o **`abstract`** (ya no
  `class` a secas). Las entidades `Annotation` (unión) van como `sealed class`.
- `freezed_annotation` 3.x empareja con `freezed` 3.x.

**Regla de versionado**
- Pinear por **major** en `pubspec.yaml` (`^`) para no saltar a un major nuevo
  sin querer. Cualquier subida de major se evalúa a mano (puede romper API).

---

## Entorno de desarrollo (prerequisitos) — **FIJA**

> ⚠️ **El modelo NO escribe código sin tener esto.** Si `flutter --version` falla,
> el entorno no está listo: resolver antes de cualquier fase. Esta sección evita
> el bloqueo de entorno (ocurrió en el primer arranque de Fase 0).

### Versiones validadas (2026-06-03)
- **Flutter 3.44.1** (canal stable) · **Dart 3.12.1**. (Cualquier Flutter stable
  con Dart ≥ 3.7 sirve; reconfirmar con `flutter doctor`.)

### SDK de Flutter — método estándar de este proyecto
- Instalado por **git clone** del canal stable en **`C:\src\flutter`**
  (ruta SIN espacios y SIN privilegios admin).
- **PATH:** `C:\src\flutter\bin` añadido al **PATH de usuario** (persistente).
- *(scoop se valoró pero no se usa: el clone ya funciona; migrar sería redundante.)*
- Verificación: `flutter --version` y `flutter doctor` deben responder OK.

### Toolchains por plataforma
| Plataforma | Requisito | ¿Cuándo? | Estado |
|------------|-----------|----------|--------|
| **Windows** (desktop) | **Visual Studio Build Tools 2022** + workload **"Desktop development with C++"** (lo exige pdfrx / Native Assets) | Fase 0 | ✅ Presente (VS BT 2022 17.14) |
| **Android** | Android SDK / Android Studio + aceptar licencias (`flutter doctor --android-licenses`) | Fase 1 | ✅ Validado en dispositivo real (R13 cerrado) |
| **Linux** (desktop) | **Ubuntu**: Flutter propio + `clang cmake ninja-build pkg-config libgtk-3-dev` | Fase 6 | ✅ Validado en Ubuntu 2026-06-21 (R2 cerrado) |

### Regla de sesión
- Al empezar CUALQUIER sesión nueva: ejecutar `flutter doctor`. Si `flutter` no se
  encuentra → revisar PATH (`C:\src\flutter\bin`). No improvisar otra instalación.

---

## Fases del proyecto (checklist de progreso)

> Regla: **una fase no se cierra hasta que el proyecto COMPILA y corre** en las 3
> plataformas (o al menos en desktop durante desarrollo). El modelo marca las
> casillas `[x]` al completar y NO avanza de fase sin que la anterior esté ✅.

### Fase 0 — Bootstrap del proyecto
- [x] `flutter create` con soporte Android, Windows, Linux
- [x] Estructura de carpetas profesional (Sección 3)
- [x] Riverpod integrado y app arrancando vacía
- [x] Tema claro/oscuro base
- [x] Compila y corre en desktop
- **DoD:** app vacía con navegación y tema, compilando en las 3 plataformas.

### Fase 1 — Visor PDF
- [x] Abrir PDF desde el sistema de archivos (file_selector)
- [x] Acceso a archivos en Android — SAF → bytes, unit-tested y **validado en
      dispositivo real** (M2101K6G, Android 13); ver R13
- [x] Render multipágina con pdfrx
- [x] Navegación entre páginas
- [x] Zoom in / out
- [x] Barra lateral opcional de miniaturas
- **DoD:** abrir un PDF real y navegarlo con zoom en desktop y Android.

### Fase 2 — Capa de anotación: texto y "tipp-ex" ✅
- [x] Modelo de anotaciones (TextAnno, RectAnno) serializable
- [x] Añadir texto libre sobre una página
- [x] Elegir familia, tamaño y color de fuente
- [x] Mover textos ya añadidos
- [x] Eliminar textos
- [x] Rectángulo opaco ("tipp-ex") para ocultar/escribir encima
- [x] Coordenadas relativas a la página (fieles al zoom)
- [x] Entrada de texto por diálogo modal (fiable, sin conflicto de foco con pdfrx)
- Nota: rediseño visual del toolbar aplazado a Fase 6 (spec en §Fase 6)
- **DoD:** tapar texto del PDF y escribir encima con fuente configurable.

### Fase 3 — Anotación avanzada + historial ✅
- [x] Dibujo a mano alzada (StrokeAnno)
- [x] Resaltado de zonas (HighlightAnno)
- [x] Undo / redo sobre toda la pila de anotaciones
- **DoD:** dibujar, resaltar y deshacer/rehacer sin perder estado.

### Fase 4 — Guardado y export ✅
- [x] Export Opción A: rasterizar página + dibujar anotaciones (pdf+printing)
- [x] Respetar tamaño y orientación reales de cada página (ver R5) — pueden variar
- [x] DPI de rasterizado configurable (defecto sugerido 200) — ver R6
- [x] Embeber fuentes elegidas en el PDF de salida
- [x] Guardar SIEMPRE como archivo nuevo (original intacto)
- [x] Verificar fidelidad de coordenadas/colores/tamaños en el PDF final
- **DoD:** exportar un PDF nuevo con todas las anotaciones, original sin tocar.

### Fase 5 — Persistencia de proyectos (guardar / reabrir sesión) ✅
- [x] Al guardar proyecto: **copiar el PDF original** dentro del almacenamiento
      de la app + guardar anotaciones en JSON (ver R12). El original del usuario
      no se toca.
- [x] Reabrir un proyecto: cargar copia + anotaciones y restaurar la sesión
- [x] Listado / gestión de proyectos guardados (abrir, borrar)
- **DoD:** cerrar la app, reabrir un proyecto y seguir editando donde se dejó.

### Fase 6 — Builds, rendimiento y pulido ✅
- [x] Instrucciones de build Android / Windows / Linux → `BUILD.md`
- [~] Rendimiento con PDFs grandes: pdfrx ya hace lazy render por página;
      `annotationsForPageProvider` es por página con `undoRedoProvider` reactivo.
      Optimización profunda de caché se pospone hasta que haya PDFs reales grandes.
- [x] **Rediseño del toolbar y panel de propiedades** (estandarizado):
      - [x] Toolbar vertical de iconos compacto y agrupado (izquierda)
      - [x] Panel de propiedades contextual a la DERECHA (fuente/tamaño/color
            para texto; color/opacidad para rect/resaltado; color/grosor para trazo;
            edición en vivo de la anotación seleccionada)
      - [x] Layout responsive: panel lateral en ≥ 700 dp; bottom sheet en < 700 dp
- [x] Fix reactivo: `undoRedoProvider` — botones undo/redo se habilitan correctamente
- **DoD:** binarios funcionando en las 3 plataformas, fluido con PDFs grandes,
  UI con toolbar + panel de propiedades estandarizados. ✅

### Funciones futuras (NO implementar — solo dejar interfaces preparadas)
- [ ] Firma manuscrita
- [ ] Sellos personalizados
- [ ] Búsqueda de texto dentro del PDF
- [ ] Comentarios / notas adhesivas
- [ ] OCR local
- [ ] Cifrado de documentos / protección por contraseña
- [ ] Modo lectura

---

## 7. Riesgos conocidos y mitigación — **FIJA**

| # | Riesgo | Impacto | Mitigación |
|---|--------|---------|-----------|
| R1 | **Export sin texto seleccionable** (Opción A rasteriza) | Medio | Asumido (1.5 / 2.4). El flujo es "tapar y anotar", no editar texto. Opción B vectorial queda como mejora futura. |
| R2 | **Build Linux con pdfrx + Native Assets** falla o pide flag/Flutter muy nuevo | **Alto** | ✅ **CERRADO.** Validado en Ubuntu (2026-06-21): `flutter build linux --release` compila pdfium vía FFI y pdfrx renderiza; flujo completo OK. Versión de Flutter fijada (`.tool-versions`). |
| R3 | **Windows requiere Modo Desarrollador** (symlinks) | Bajo | Documentar en instrucciones de build (Fase 5) y en el README. Activarlo en la máquina de desarrollo. |
| R4 | **Riverpod 3 / freezed 3 son majors**; ejemplos online en su mayoría 2.x | Medio | Seguir SOLO doc oficial 3.x (ver 4.5 y regla en Sección 8). Code-gen con las versiones 4.x emparejadas. |
| R5 | **Fidelidad de coordenadas** anotación → PDF exportado (pantalla vs página, DPI) | **Alto** | Guardar coords **relativas a la página** (0..1 o en puntos PDF), nunca en píxeles de pantalla. Test de fidelidad obligatorio en Fase 4 (comparar posiciones). |
| R6 | **Calidad de rasterizado** baja → texto/imagen borrosos en el export | Medio | Rasterizar a **DPI alto configurable** (p. ej. 150–300). Equilibrio calidad/tamaño. |
| R7 | **Tamaño del PDF de salida** crece (páginas como imagen) | Medio | DPI ajustable + compresión de imagen. Aceptado como coste de Opción A. |
| R8 | **Fuentes no embebidas** → la fuente elegida no se ve en otros lectores | Medio | Embeber SIEMPRE el TTF elegido al exportar (2.5). Solo fuentes del set curado. |
| R9 | **Rendimiento con PDFs grandes** (memoria al cargar/rasterizar muchas páginas) | Medio | Render perezoso bajo demanda (pdfrx ya lo hace), caché limitada de páginas, rasterizar solo la página al exportar, liberar bitmaps. Tarea explícita en Fase 5. |
| R10 | **file_selector en Linux** puede depender de portales del SO (xdg-desktop-portal / zenity) | Bajo | Documentar requisito del sistema en instrucciones Linux. Probar en Fase 1. |
| R11 | **Deriva del modelo ejecutor** (improvisa, salta fases, mete deps no permitidas) | Medio | Sección 8 (reglas) + checklist de fases + decisiones FIJAS. |
| R12 | **Proyecto guardado referencia un original que el usuario mueve/borra** → se rompe al reabrir | Medio | Al guardar proyecto se **copia el PDF original** al almacenamiento de la app y se trabaja sobre esa copia. El original del usuario nunca se toca. Coste: duplica el archivo. **Decisión FIJA** (Fase 5). |
| R13 | **Acceso a archivos en Android** (scoped storage / permisos / SAF) | Medio | ✅ **CERRADO.** SAF vía `file_selector` → ruta vacía → `openPdfFromBytes`. Implementado, unit-tested y **validado en dispositivo real** (M2101K6G, Android 13): abrir-SAF → anotar → guardar → reabrir. Incluye el fix del bug de guardar proyecto abierto por SAF. |

---

## 8. Reglas para el modelo que ejecute este roadmap — **FIJA**

> Eres un agente de código trabajando en este repo. Estas reglas son
> **obligatorias**. Léelas y cumple todas.

### 8.1 Flujo de trabajo

1. **Lee este ROADMAP entero** antes de escribir o modificar código.
2. **No saltes de fase.** Trabaja en la fase activa más baja sin completar.
3. Una fase **solo se cierra** cuando: (a) cumple su *Definition of Done*, y
   (b) el proyecto **compila y arranca** (al menos en desktop durante desarrollo).
4. Al completar una tarea, **marca su casilla** `[x]` en la sección de Fases.
5. **Commits pequeños** por tarea o subtarea, con mensaje claro de qué se hizo.
6. Si una decisión de diseño **no está cubierta** aquí, **pregunta**; no improvises
   ni añadas alcance por tu cuenta.

### 8.2 Decisiones que NO puedes cambiar

7. No reabras nada marcado **FIJA / FIJO** (Secciones 1, 2, 3, 4, 7) sin permiso
   explícito del responsable.
8. No introduzcas **servidor, backend, red, nube, cuentas, telemetría, anuncios
   ni suscripciones** (restricciones 1.3). La app es 100% local y offline.
9. El **PDF original NUNCA se modifica**. Guardar/exportar = **archivo nuevo**.

### 8.3 Dependencias y compatibilidad

10. **No añadas dependencias** que no estén en la Sección 4 sin: verificar que su
    licencia es **MIT / BSD / Apache-2.0**, justificarla y **anotarla en la
    Sección 4**. Prohibido cualquier SDK comercial (Syncfusion, etc.).
11. Sigue **solo la documentación oficial de Riverpod 3.x y freezed 3.x**. Ignora
    ejemplos de 2.x (rompen). Usa las versiones emparejadas (ver 4.5).
12. Pinea por major (`^`) en `pubspec.yaml`. No subas de major sin evaluarlo.

### 8.4 Arquitectura y código

13. Respeta la **regla de dependencia de capas** (3.1): `domain` no importa Flutter
    ni paquetes externos; `presentation` no importa `data`.
14. Coordenadas de anotación **siempre relativas a la página** (nunca píxeles de
    pantalla) — ver R5.
15. Tras tocar entidades/modelos con anotaciones de code-gen, ejecuta
    `dart run build_runner build --delete-conflicting-outputs`.
16. **Tests mínimos por fase:** al menos los *usecases* del `domain` de la fase.
17. **Idioma:** identificadores y código en **inglés**; textos visibles de la UI en
    **español**. Comentarios, los justos y útiles.

### 8.5 Validación crítica temprana

18. En **Fase 0**, antes de avanzar, **verifica que pdfrx compila y corre en Linux
    y Windows** (riesgo R2). Si no compila, es **bloqueante**: resuélvelo o
    repórtalo antes de tocar nada más.

---

## Apéndice — Mapa funcionalidades pedidas → fase

| Funcionalidad original | Fase |
|------------------------|------|
| Abrir PDF desde sistema de archivos | 1 |
| Visualizar PDF multipágina | 1 |
| Navegar entre páginas | 1 |
| Zoom in / out | 1 |
| Barra lateral de miniaturas | 1 |
| Añadir texto libre | 2 |
| Tamaño / color / tipo de fuente | 2 |
| Mover textos | 2 |
| Eliminar textos | 2 |
| Rectángulo opaco ("tipp-ex") | 2 |
| Dibujo a mano alzada | 3 |
| Resaltar zonas | 3 |
| Deshacer / rehacer | 3 |
| Guardar copia modificada | 4 |
| Mantener original intacto | 4 |
| Exportar nuevo PDF | 4 |
| Guardar / reabrir sesión de edición (proyecto) | 5 |
| Build Android / Windows / Linux | 6 |
| Rendimiento PDFs grandes | 6 |
| Interfaz limpia, responsive, tema claro/oscuro | 0 (base) + 6 (pulido) |
| Firma, sellos, búsqueda, notas, OCR, cifrado, modo lectura | Futuras (interfaces en Fase 0) |
