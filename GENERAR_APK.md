# 📱 Generar APK de tu App Nawi

## 🚀 **Métodos para Generar APK**

---

## ✅ **Método 1: APK de Depuración (Debug)** - Más Rápido

### **Comando:**
```powershell
flutter build apk --debug
```

**Ubicación del APK:**
```
build\app\outputs\flutter-apk\app-debug.apk
```

**Características:**
- ✅ Más rápido de compilar
- ✅ Más grande en tamaño
- ✅ Incluye herramientas de depuración
- ⚠️ No optimizado para producción

---

## ✅ **Método 2: APK de Producción (Release)** - Recomendado

### **Comando:**
```powershell
flutter build apk --release
```

**Ubicación del APK:**
```
build\app\outputs\flutter-apk\app-release.apk
```

**Características:**
- ✅ Optimizado para producción
- ✅ Menor tamaño
- ✅ Mejor rendimiento
- ✅ Listo para distribuir

---

## 📦 **Método 3: APK Dividido por Arquitectura** - Tamaño Reducido

### **Para ARM64 (Dispositivos modernos):**
```powershell
flutter build apk --release --split-per-abi
```

**Ubicación de los APKs:**
```
build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
build\app\outputs\flutter-apk\app-x86_64-release.apk
```

**Ventajas:**
- ✅ APKs más pequeños (cada uno solo para su arquitectura)
- ✅ Los usuarios solo descargan el APK necesario para su dispositivo
- ✅ Ideal para Play Store

---

## 🔧 **Antes de Generar el APK**

### **1. Verificar configuración:**
```powershell
# Verificar que todo está correcto
flutter doctor

# Obtener dependencias actualizadas
flutter pub get

# Limpiar builds anteriores (opcional pero recomendado)
flutter clean
```

### **2. Verificar versión y build number:**
Edita `pubspec.yaml`:
```yaml
version: 1.0.0+1
#         ↑     ↑
#         |     └─ Build number (debe incrementarse)
#         └─────── Version name
```

---

## 📋 **Comandos Completos (Paso a Paso)**

### **Para APK de Release (Producción):**

```powershell
# 1. Limpiar (opcional)
flutter clean

# 2. Obtener dependencias
flutter pub get

# 3. Generar APK de release
flutter build apk --release

# El APK estará en:
# build\app\outputs\flutter-apk\app-release.apk
```

---

## 📁 **Ubicación de los APKs Generados**

Después de ejecutar `flutter build apk`, encontrarás los APKs en:

```
nawi-movil2/
└── build/
    └── app/
        └── outputs/
            └── flutter-apk/
                ├── app-debug.apk          (si usaste --debug)
                ├── app-release.apk        (si usaste --release)
                └── app-*-release.apk      (si usaste --split-per-abi)
```

---

## ⚙️ **Opciones Avanzadas**

### **APK con versión específica:**
```powershell
flutter build apk --release --build-name=1.0.0 --build-number=1
```

### **APK con target file específico:**
```powershell
flutter build apk --release --target=lib/main.dart
```

### **APK con flavor (si tienes configurado):**
```powershell
flutter build apk --release --flavor production
```

---

## 📱 **Instalar el APK en tu Dispositivo**

### **Opción 1: Desde la PC**
```powershell
# Conecta tu dispositivo y ejecuta:
adb install build\app\outputs\flutter-apk\app-release.apk
```

### **Opción 2: Transferir y Instalar Manualmente**
1. Copia el APK a tu dispositivo (USB, email, etc.)
2. Abre el APK en tu dispositivo
3. Permite instalación desde fuentes desconocidas si es necesario
4. Instala

---

## 🔐 **Firmar el APK para Play Store**

Si quieres subir a Google Play Store, necesitas firmar el APK:

### **1. Generar Keystore:**
```powershell
keytool -genkey -v -keystore C:\Users\guill\nawii\nawi-movil2\android\app\key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nawii
```

### **2. Configurar signing en `android/app/build.gradle`:**

Agrega antes del bloque `android {`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### **3. Crear `android/key.properties`:**
```
storePassword=tu_password
keyPassword=tu_password
keyAlias=nawii
storeFile=app/key.jks
```

---

## 📊 **Tamaño del APK**

Después de generar el APK, puedes ver el tamaño:
```powershell
# Ver tamaño del APK
dir build\app\outputs\flutter-apk\app-release.apk
```

---

## ✅ **Checklist Antes de Generar APK**

- [ ] Verificar que `pubspec.yaml` tenga versión correcta
- [ ] Verificar que la API Key de Google Maps esté configurada
- [ ] Verificar que las reglas de Firebase estén configuradas
- [ ] Probar la app en modo debug antes de generar release
- [ ] Verificar que todos los endpoints estén funcionando

---

## 🚀 **Comando Rápido (Todo en Uno)**

```powershell
flutter clean && flutter pub get && flutter build apk --release
```

Este comando:
1. Limpia builds anteriores
2. Obtiene dependencias actualizadas
3. Genera APK de release optimizado

---

## 📝 **Notas Importantes**

- **APK Debug**: ~50-100 MB (grande, incluye debug info)
- **APK Release**: ~30-50 MB (optimizado, más pequeño)
- **APK Split**: ~10-20 MB cada uno (más pequeño, específico por arquitectura)

---

## 🎯 **Recomendación**

Para distribuir la app, usa:
```powershell
flutter build apk --release --split-per-abi
```

Esto genera 3 APKs más pequeños, cada uno para una arquitectura diferente.

