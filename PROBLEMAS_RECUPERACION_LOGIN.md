# 🔍 Análisis: Problemas de Recuperación de Contraseña y Login

## 📋 **Problemas Identificados**

### **1. Recuperación de Contraseña Inconsistente** ⚠️

**Problema:**
- **En la web:** El correo contiene un **enlace** que permite cambiar la contraseña directamente
- **En móvil:** La app pide un **código/token** que el usuario debe ingresar manualmente

**¿Por qué pasa esto?**
El backend Laravel está enviando un **enlace completo** en el email (típico para web), pero la app móvil está diseñada para recibir solo un **código/token** que el usuario copia y pega.

---

## 🔍 **Cómo Funciona Actualmente la Recuperación de Contraseña**

### **Flujo Actual en la App Móvil:**

1. Usuario hace clic en "¿Olvidaste tu contraseña?"
2. Ingresa su email en `ForgotPasswordPage`
3. Se llama a `POST /api/password/forgot`
4. El backend envía un email con un token/enlace
5. **PROBLEMA:** El email contiene un enlace, pero la app espera un código
6. Usuario va a `ResetPasswordPage` y debe ingresar:
   - Email (ya lo tiene)
   - **Código de recuperación** (debe copiarlo del email)
   - Nueva contraseña
   - Confirmar contraseña
7. Se llama a `POST /api/password/reset` con el token

---

## ✅ **Soluciones Posibles**

### **Opción 1: Modificar el Backend para Enviar Código Simple (Recomendado para Móvil)**

**Modificar el email del backend para incluir un código simple además del enlace:**

```php
// En tu controlador de Laravel (PasswordResetController o similar)
public function sendResetLinkEmail(Request $request)
{
    $request->validate(['email' => 'required|email']);
    
    $status = Password::sendResetLink(
        $request->only('email')
    );
    
    if ($status == Password::RESET_LINK_SENT) {
        // Obtener el token que se generó
        $user = User::where('email', $request->email)->first();
        $token = Password::createToken($user);
        
        // Enviar email con el código simple
        Mail::send('emails.password-reset', [
            'token' => $token,
            'resetUrl' => url('/reset-password?token=' . $token),
            'code' => substr($token, 0, 6) // Primeros 6 caracteres como código
        ], function ($message) use ($user) {
            $message->to($user->email)
                    ->subject('Recuperación de Contraseña - Nawi');
        });
        
        return response()->json([
            'success' => true,
            'message' => 'Se ha enviado un código de recuperación a tu correo'
        ]);
    }
    
    return response()->json([
        'success' => false,
        'message' => 'No se pudo enviar el código'
    ], 400);
}
```

**Plantilla del email (`resources/views/emails/password-reset.blade.php`):**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Recuperación de Contraseña</title>
</head>
<body>
    <h2>Recuperación de Contraseña - Nawi</h2>
    
    <p>Hola,</p>
    
    <p>Has solicitado restablecer tu contraseña. Usa el siguiente código:</p>
    
    <div style="background: #f0f0f0; padding: 20px; text-align: center; font-size: 24px; font-weight: bold; margin: 20px 0;">
        {{ $code }}
    </div>
    
    <p><strong>O haz clic en este enlace para restablecer desde la web:</strong></p>
    <a href="{{ $resetUrl }}" style="display: inline-block; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 5px;">
        Restablecer Contraseña
    </a>
    
    <p>Este código expira en 60 minutos.</p>
    
    <p>Si no solicitaste este cambio, ignora este correo.</p>
</body>
</html>
```

---

### **Opción 2: Modificar la App para Extraer el Token del Enlace** ✅ **IMPLEMENTADO**

Si el backend ya envía enlaces, puedes modificar la app para que el usuario pueda pegar el enlace completo y extraer el token automáticamente.

**Formato del enlace del email:**
```
https://nawi.click/password/reset/jWJg45mPSPqE6CNSUGMCf8gvF1aCDzwBsqoCZ2qDpExzsdDR83T1X8zYxCEgKbyc?email=mariana6guillen%40gmail.com
```

**La app ahora:**
- Detecta automáticamente si el usuario pega un enlace completo
- Extrae el token del path `/password/reset/TOKEN`
- También puede extraer tokens de query parameters `?token=...`
- O aceptar códigos simples directamente

**Modificar `ResetPasswordPage` para aceptar enlaces:**

```dart
// En lib/views/reset_password_page.dart
// Agregar un método para extraer el token de un enlace
String? _extractTokenFromUrl(String input) {
  // Si el input es una URL, extraer el token
  try {
    final uri = Uri.parse(input);
    return uri.queryParameters['token'];
  } catch (e) {
    // Si no es una URL, asumir que es el token directamente
    return input;
  }
}

// Modificar el campo de token para aceptar tanto código como URL
TextFormField(
  controller: _tokenController,
  decoration: InputDecoration(
    labelText: 'Código de recuperación o enlace',
    hintText: 'Pega el código o el enlace completo del correo',
    // ... resto del código
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa el código o enlace';
    }
    // Si es un enlace, extraer el token
    final token = _extractTokenFromUrl(value);
    if (token == null || token.isEmpty) {
      return 'Código o enlace inválido';
    }
    return null;
  },
),
```

**Modificar `_resetPassword` para usar el token extraído:**

```dart
Future<void> _resetPassword() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
  });

  // Extraer el token (ya sea código directo o del enlace)
  final tokenInput = _tokenController.text.trim();
  final token = _extractTokenFromUrl(tokenInput) ?? tokenInput;

  final result = await AuthService.resetPassword(
    email: widget.email,
    token: token,
    password: _passwordController.text,
    passwordConfirmation: _confirmPasswordController.text,
  );

  // ... resto del código
}
```

---

### **Opción 3: Agregar Deep Linking (Más Avanzado)**

Permitir que la app móvil abra directamente desde el enlace del email:

**1. Configurar Deep Linking en Flutter:**

```yaml
# pubspec.yaml
dependencies:
  uni_links: ^0.5.1
```

**2. Configurar en Android (`android/app/src/main/AndroidManifest.xml`):**

```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleTop">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="nawi" android:host="reset" />
    </intent-filter>
</activity>
```

**3. Modificar el email del backend para usar deep link:**

```html
<a href="nawi://reset?token={{ $token }}&email={{ $user->email }}">
    Restablecer Contraseña en la App
</a>
```

**4. Capturar el deep link en la app:**

```dart
// En main.dart o donde inicialices la app
import 'package:uni_links/uni_links.dart';

void initUniLinks() async {
  try {
    final initialLink = await getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }
    
    linkStream.listen((String? link) {
      if (link != null) {
        _handleDeepLink(link);
      }
    });
  } catch (e) {
    print('Error con uni_links: $e');
  }
}

void _handleDeepLink(String link) {
  final uri = Uri.parse(link);
  if (uri.scheme == 'nawi' && uri.host == 'reset') {
    final token = uri.queryParameters['token'];
    final email = uri.queryParameters['email'];
    
    if (token != null && email != null) {
      Navigator.pushNamed(
        context,
        '/reset-password',
        arguments: {
          'email': email,
          'token': token,
        },
      );
    }
  }
}
```

---

## 🔴 **Problema 2: Error "Personal access client not found"**

Este error aparece porque **Laravel Passport** no tiene configurado el "Personal Access Client" que se necesita para generar tokens de autenticación.

### **Solución Rápida:**

**1. En tu servidor backend, ejecuta:**

```bash
php artisan passport:client --personal
```

**2. O crea manualmente en la base de datos:**

```sql
-- Verificar si existe
SELECT * FROM oauth_clients WHERE personal_access_client = 1;

-- Si no existe, crear uno
INSERT INTO `oauth_clients` (
    `id`,
    `user_id`,
    `name`,
    `secret`,
    `provider`,
    `redirect`,
    `personal_access_client`,
    `password_client`,
    `revoked`,
    `created_at`,
    `updated_at`
) VALUES (
    1,
    NULL,
    'Nawi Personal Access Client',
    NULL,
    NULL,
    'http://localhost',
    1,
    0,
    0,
    NOW(),
    NOW()
);

INSERT INTO `oauth_personal_access_clients` (
    `id`,
    `client_id`,
    `created_at`,
    `updated_at`
) VALUES (
    1,
    1,
    NOW(),
    NOW()
);
```

**3. Verificar que se creó:**

```sql
SELECT * FROM oauth_clients WHERE personal_access_client = 1;
SELECT * FROM oauth_personal_access_clients;
```

---

## 📝 **Resumen de Recomendaciones**

### **Para la Recuperación de Contraseña:**

1. **Opción Recomendada:** Modificar el backend para enviar un **código simple** (6-8 caracteres) además del enlace en el email
2. **Alternativa:** Modificar la app para aceptar tanto códigos como enlaces completos
3. **Futuro:** Implementar deep linking para una mejor experiencia

### **Para el Error de Login:**

1. Crear el Personal Access Client en el backend (comando o SQL)
2. Verificar que Passport esté correctamente configurado
3. Probar el login nuevamente

---

## 🧪 **Cómo Probar**

### **1. Probar Recuperación de Contraseña:**

1. En la app móvil, haz clic en "¿Olvidaste tu contraseña?"
2. Ingresa tu email
3. Revisa tu correo
4. Deberías ver:
   - **Opción A:** Un código simple (ej: `ABC123`)
   - **Opción B:** Un enlace que puedes copiar y pegar
5. Ingresa el código o pega el enlace en la app
6. Ingresa tu nueva contraseña
7. Debería funcionar

### **2. Probar Login:**

1. Después de crear el Personal Access Client
2. Intenta iniciar sesión en la app
3. El error "Personal access client not found" debería desaparecer

---

## 📞 **Próximos Pasos**

1. **Backend:** Modificar el email de recuperación para incluir código simple
2. **App (Opcional):** Mejorar `ResetPasswordPage` para aceptar enlaces
3. **Backend:** Crear el Personal Access Client si no existe
4. **Probar:** Verificar que ambos flujos funcionen correctamente

---

## 📚 **Referencias**

- Ver `SOLUCION_PASSPORT.md` para más detalles sobre el error de Passport
- Ver `lib/services/auth_service.dart` para ver cómo funciona el reset de contraseña
- Ver `lib/views/reset_password_page.dart` para ver la UI de recuperación

