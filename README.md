# NAWI

## Descripción Breve

**NAWI** es una aplicación móvil de transporte que conecta pasajeros con taxistas en tiempo real. Permite solicitar viajes, realizar seguimiento en vivo del conductor y gestionar el historial de viajes, todo desde una interfaz intuitiva y moderna.

---

## Descripción Completa

**NAWI** es una aplicación móvil de transporte desarrollada en Flutter que facilita la conexión entre pasajeros y taxistas en tiempo real. La aplicación ofrece una solución completa para la gestión de viajes en taxi, con funcionalidades avanzadas de geolocalización, seguimiento en tiempo real y comunicación entre usuarios.

### Características Principales

#### Para Pasajeros
- **Solicitud de viajes**: Selección de origen y destino mediante mapas interactivos de Google Maps
- **Selección de taxista**: Opción de elegir un conductor específico o asignación automática
- **Seguimiento en tiempo real**: Visualización de la ubicación del taxista durante el viaje
- **Historial de viajes**: Consulta de todos los viajes realizados anteriormente
- **Sistema de calificaciones**: Posibilidad de calificar y comentar sobre los viajes completados
- **Geocodificación inteligente**: Conversión automática entre direcciones y coordenadas geográficas

#### Para Taxistas
- **Gestión de disponibilidad**: Conectarse o desconectarse del sistema para recibir solicitudes
- **Viajes pendientes**: Visualización y gestión de solicitudes de viaje en tiempo real
- **Actualización de ubicación**: Sincronización automática de la posición para facilitar la asignación
- **Gestión completa de viajes**: Aceptar, rechazar y completar viajes con facilidad
- **Historial profesional**: Consulta de todos los viajes realizados

### Tecnologías Utilizadas

- **Frontend**: Flutter (Dart) - Desarrollo multiplataforma
- **Backend API**: REST API en `https://nawi.click/api`
- **Base de datos en tiempo real**: Firebase Realtime Database
- **Autenticación**: Sistema JWT con tokens Bearer
- **Mapas y geolocalización**: Google Maps API
- **Publicidad**: Google Mobile Ads (banners publicitarios)
- **Almacenamiento local**: SharedPreferences para persistencia de datos

### Funcionalidades Técnicas

- Autenticación segura con tokens JWT
- Sincronización en tiempo real mediante Firebase
- Integración completa con Google Maps para navegación y geocodificación
- Manejo robusto de permisos de ubicación
- Validación exhaustiva de datos de entrada
- Manejo avanzado de errores y estados de conexión

### Diseño y Experiencia de Usuario

La aplicación cuenta con un diseño moderno con tema oscuro, utilizando una paleta de colores que incluye tonos oscuros y amarillos/dorados como colores primarios. La interfaz se adapta dinámicamente según el tipo de usuario (pasajero o taxista), ofreciendo una experiencia personalizada y optimizada para cada rol.

**Tagline**: "Raíces que se mueven contigo."

### Flujo de Trabajo

1. **Autenticación**: El usuario inicia sesión como pasajero o taxista
2. **Solicitud de viaje** (Pasajero): Selecciona origen y destino en el mapa
3. **Notificación** (Taxista): Recibe la solicitud y puede aceptar o rechazar
4. **Viaje en curso**: Seguimiento en tiempo real de la ubicación del taxista
5. **Finalización**: Calificación del servicio y registro en el historial

### Alcance Geográfico

La aplicación está especialmente diseñada para la región de Ocosingo, Chiapas, México, con soporte optimizado para ubicaciones específicas como la Universidad Tecnológica de la Selva (UTS), facilitando el transporte de estudiantes y residentes de la zona.

---

## Getting Started

This project is a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Implementación del Banner Fijo de Anuncios

Esta sección documenta los pasos seguidos para implementar el banner publicitario fijo en la parte inferior de la aplicación usando Google Mobile Ads (AdMob).

### Pasos de Implementación

#### 1. Agregar la Dependencia de Google Mobile Ads

En el archivo `pubspec.yaml`, se agregó la dependencia:

```yaml
dependencies:
  google_mobile_ads: ^5.3.1
```

Luego se ejecutó:
```bash
flutter pub get
```

#### 2. Inicializar Google Mobile Ads en la Aplicación

En el archivo `lib/main.dart`, se agregó la inicialización de MobileAds en la función `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... inicialización de Firebase ...

  // Inicializar Google Mobile Ads
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    print('Error inicializando MobileAds: $e');
  }

  runApp(MyApp());
}
```

#### 3. Configurar AdMob Application ID en Android

En el archivo `android/app/src/main/AndroidManifest.xml`, se agregó el meta-data con el Application ID de AdMob dentro de la etiqueta `<application>`:

```xml
<!-- AdMob Application ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-1838002939487298~5835495235"/>
```

**Nota**: Este ID es específico de la aplicación y debe obtenerse desde la consola de AdMob.

#### 4. Crear el Widget del Banner

Se creó el archivo `lib/widgets/banner_ad_widget.dart` con la siguiente implementación:

- **Widget Stateful**: `MyBannerAdWidget` que extiende `StatefulWidget`
- **IDs de Anuncios**: 
  - En modo debug: IDs de prueba de AdMob
  - En modo release: IDs de producción específicos para Android e iOS
- **Ciclo de Vida del Anuncio**:
  - Carga del anuncio en `initState()`
  - Disposición del anuncio en `dispose()`
  - Listeners para eventos: `onAdLoaded`, `onAdFailedToLoad`, `onAdOpened`, `onAdClosed`
- **Tamaño del Banner**: Por defecto usa `AdSize.banner` (320x50)

#### 5. Integrar el Banner en la Página Principal

En el archivo `lib/views/home_page.dart`:

1. Se importó el widget:
```dart
import 'package:nawii/widgets/banner_ad_widget.dart';
```

2. Se agregó el banner como `bottomNavigationBar` del `Scaffold`:
```dart
Scaffold(
  // ... otros widgets ...
  bottomNavigationBar: MyBannerAdWidget(),
)
```

### Configuración de IDs de Anuncios

El widget `MyBannerAdWidget` maneja automáticamente los IDs según el modo:

- **Modo Debug**:
  - Android: `ca-app-pub-3940256099942544/6300978111` (ID de prueba)
  - iOS: `ca-app-pub-3940256099942544/2934735716` (ID de prueba)

- **Modo Release**:
  - Android: `ca-app-pub-1838002939487298/1490385105` (ID de producción)
  - iOS: `ca-app-pub-1838002939487298/5731553456` (ID de producción)

### Características del Banner

- **Posición**: Fijo en la parte inferior de la pantalla principal (`HomePage`)
- **Tamaño**: Banner estándar (320x50 píxeles)
- **Visibilidad**: Siempre visible cuando el usuario está en la página principal
- **Manejo de Errores**: Si el anuncio falla al cargar, simplemente no se muestra (no afecta la funcionalidad de la app)
- **SafeArea**: El widget está envuelto en `SafeArea` para respetar las áreas seguras del dispositivo

### Archivos Modificados/Creados

1. ✅ `pubspec.yaml` - Agregada dependencia `google_mobile_ads`
2. ✅ `lib/main.dart` - Inicialización de MobileAds
3. ✅ `android/app/src/main/AndroidManifest.xml` - Application ID de AdMob
4. ✅ `lib/widgets/banner_ad_widget.dart` - Widget del banner (nuevo archivo)
5. ✅ `lib/views/home_page.dart` - Integración del banner como bottomNavigationBar

### Notas Importantes

- Los IDs de prueba solo funcionan en modo debug y no generan ingresos
- Los IDs de producción deben configurarse en la consola de AdMob
- Para iOS, también se debe configurar el Application ID en `Info.plist` (si aplica)
- El banner se carga automáticamente cuando se muestra la `HomePage`
- El anuncio se libera correctamente cuando el widget se destruye para evitar memory leaks