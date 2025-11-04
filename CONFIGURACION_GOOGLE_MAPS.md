# 🗺️ Configuración de Google Maps API Key

## 📍 **Dónde Poner las Credenciales de Google Maps**

---

## 🤖 **ANDROID**

### **Ubicación:** `android/app/src/main/AndroidManifest.xml`

Ya tienes la configuración en la **línea 29-30**, pero necesitas reemplazar la API Key con la tuya:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI" />
```

**⚠️ IMPORTANTE:** 
- Reemplaza `TU_API_KEY_AQUI` con tu API Key real de Google Maps
- Esta key debe estar dentro de la etiqueta `<activity>` de `MainActivity`
- La key que tienes actualmente (`AIzaSyCaZFeEmON_iOVCBO24V1FmQu0pQ2QrxhU`) parece ser de ejemplo

---

## 🍎 **iOS**

### **Opción 1: En AppDelegate.swift** (Recomendado)

**Ubicación:** `ios/Runner/AppDelegate.swift`

Agrega esta configuración en el método `didFinishLaunchingWithOptions`:

```swift
import Flutter
import UIKit
import GoogleMaps  // ← Agregar este import

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configurar Google Maps API Key
    GMSServices.provideAPIKey("TU_API_KEY_AQUI")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### **Opción 2: En Info.plist** (Alternativa)

**Ubicación:** `ios/Runner/Info.plist`

Agrega esta entrada antes del tag `</dict>`:

```xml
<key>GMSApiKey</key>
<string>TU_API_KEY_AQUI</string>
```

**Nota:** Si usas la Opción 1 (AppDelegate.swift), no necesitas la Opción 2.

---

## 🔑 **Cómo Obtener tu API Key de Google Maps**

1. **Ve a Google Cloud Console:**
   - https://console.cloud.google.com/

2. **Crea un proyecto o selecciona uno existente**

3. **Habilita la API:**
   - Ve a "APIs & Services" → "Library"
   - Busca "Maps SDK for Android" y habilítala
   - Busca "Maps SDK for iOS" y habilítala

4. **Crea credenciales:**
   - Ve a "APIs & Services" → "Credentials"
   - Click en "Create Credentials" → "API Key"
   - Copia la API Key generada

5. **Restringe la API Key** (Recomendado para producción):
   - Click en la API Key creada
   - En "API restrictions", selecciona:
     - ✅ Maps SDK for Android
     - ✅ Maps SDK for iOS
   - En "Application restrictions" (Android):
     - Selecciona "Android apps"
     - Agrega tu package name: `com.example.nawii` (o el que uses)
   - En "Application restrictions" (iOS):
     - Selecciona "iOS apps"
     - Agrega tu Bundle ID

---

## 📝 **Archivos a Modificar**

### **✅ ANDROID** - Ya está configurado, solo cambiar la key:

```
android/app/src/main/AndroidManifest.xml
```

**Línea 29-30:** Cambiar la API Key

### **✅ iOS** - Necesitas agregar la configuración:

```
ios/Runner/AppDelegate.swift
```

**Agregar:** `GMSServices.provideAPIKey("TU_API_KEY")`

---

## 🧪 **Verificación**

### **Android:**
1. Compila la app: `flutter build apk`
2. Si hay errores, verifica que la API Key esté correcta
3. Verifica en Google Cloud Console que la API esté habilitada

### **iOS:**
1. Agrega el import `GoogleMaps` en `AppDelegate.swift`
2. Configura la key con `GMSServices.provideAPIKey()`
3. Compila: `flutter build ios`
4. Si hay errores, verifica que la API Key esté correcta

---

## ⚠️ **Troubleshooting**

### **Error: "API_KEY not valid"**
- Verifica que la API Key sea correcta
- Verifica que las APIs estén habilitadas en Google Cloud Console
- Verifica que la API Key tenga los permisos correctos

### **Error: "This IP, site or mobile application is not authorized to use this API key"**
- Verifica las restricciones de la API Key en Google Cloud Console
- Asegúrate de que el package name (Android) o Bundle ID (iOS) coincida

### **Mapa no se muestra en iOS:**
- Verifica que hayas agregado `import GoogleMaps` en AppDelegate.swift
- Verifica que hayas llamado `GMSServices.provideAPIKey()` antes de `GeneratedPluginRegistrant.register()`

---

## ✅ **Checklist**

- [ ] API Key obtenida de Google Cloud Console
- [ ] Maps SDK for Android habilitada
- [ ] Maps SDK for iOS habilitada
- [ ] AndroidManifest.xml actualizado con la API Key
- [ ] AppDelegate.swift actualizado con `GMSServices.provideAPIKey()`
- [ ] App compila sin errores
- [ ] Mapa se muestra correctamente

---

## 🔐 **Seguridad**

**⚠️ IMPORTANTE:** 
- No subas tu API Key a repositorios públicos
- Usa restricciones en Google Cloud Console
- Considera usar variables de entorno para producción
- Revisa regularmente el uso de la API en Google Cloud Console

