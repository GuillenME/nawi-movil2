# 🔍 Debug: Error 500 al Iniciar Sesión

## 📋 **Diagnóstico del Error 500**

Un error **500 (Internal Server Error)** significa que hay un problema en el **backend**, no en la app Flutter.

---

## 🔍 **Causas Comunes del Error 500**

### **1. Problema en el Backend Laravel**

El endpoint `POST /api/login` está fallando. Posibles causas:

#### **A. Estructura del Request Incorrecta**
El backend espera un formato diferente. Verifica en tu backend Laravel qué formato espera.

**Lo que envía la app:**
```json
{
  "email": "usuario@example.com",
  "password": "password123"
}
```

**Verifica que tu backend Laravel acepte:**
- `email` (no `correo` o `username`)
- `password` (no `contraseña` o `pass`)

#### **B. Headers Faltantes**
Algunos backends Laravel requieren headers adicionales. La app envía:
```
Content-Type: application/json
Accept: application/json
```

**Verifica en tu backend** si necesitas:
- `X-Requested-With: XMLHttpRequest`
- Otros headers personalizados

#### **C. Validación Falla**
El backend puede estar rechazando la validación. Verifica:
- Que el email sea válido
- Que la contraseña tenga el formato correcto
- Que no haya campos adicionales requeridos

#### **D. Error en la Base de Datos**
El backend puede estar fallando al:
- Consultar la tabla de usuarios
- Verificar la contraseña
- Generar el token

#### **E. Error al Generar Token**
Si usas Sanctum o Passport, puede fallar al generar el token.

---

## 🛠️ **Cómo Diagnosticar el Error 500**

### **1. Revisar los Logs del Backend**

En tu servidor Laravel, revisa los logs:

```bash
# En el servidor
tail -f storage/logs/laravel.log
```

O en Laravel:
```php
// En tu controlador de login
Log::error('Error en login', [
    'email' => $request->email,
    'error' => $e->getMessage(),
    'trace' => $e->getTraceAsString()
]);
```

### **2. Verificar el Endpoint en Postman/Insomnia**

Prueba el endpoint directamente:

**Request:**
```
POST https://nawi.click/api/login
Headers:
  Content-Type: application/json
  Accept: application/json
Body:
{
  "email": "tu_email@example.com",
  "password": "tu_password"
}
```

**Si funciona en Postman pero no en la app:**
- Problema de headers
- Problema de formato de datos

**Si no funciona en Postman:**
- Problema en el backend
- Revisa los logs de Laravel

---

## 🔧 **Soluciones Posibles**

### **1. Verificar Estructura del Request**

Asegúrate que tu backend Laravel espere exactamente:

```php
// En tu controlador Laravel
public function login(Request $request)
{
    $request->validate([
        'email' => 'required|email',
        'password' => 'required|string',
    ]);
    
    // Tu lógica de login...
}
```

### **2. Verificar Estructura de la Respuesta**

El backend debe retornar:

**Si es exitoso (200):**
```json
{
  "success": true,
  "message": "Login exitoso",
  "data": {
    "usuario": {
      "id": "uuid",
      "nombre": "Juan",
      "apellido": "Pérez",
      "email": "juan@email.com",
      "id_rol": "2",
      "telefono": "1234567890"
    },
    "tipo": "pasajero",
    "access_token": "token_aqui",
    "token_type": "Bearer"
  }
}
```

**Si hay error (500):**
```json
{
  "success": false,
  "message": "Mensaje de error descriptivo",
  "error": "Detalles del error"
}
```

### **3. Verificar Autenticación en Laravel**

Si usas **Laravel Sanctum** o **Passport**, verifica:

```php
// routes/api.php
Route::post('/login', [AuthController::class, 'login']);

// app/Http/Controllers/AuthController.php
public function login(Request $request)
{
    try {
        $credentials = $request->only('email', 'password');
        
        if (!Auth::attempt($credentials)) {
            return response()->json([
                'success' => false,
                'message' => 'Credenciales inválidas'
            ], 401);
        }
        
        $user = Auth::user();
        $token = $user->createToken('auth_token')->plainTextToken;
        
        return response()->json([
            'success' => true,
            'message' => 'Login exitoso',
            'data' => [
                'usuario' => $user,
                'tipo' => $user->isTaxista() ? 'taxista' : 'pasajero',
                'access_token' => $token,
                'token_type' => 'Bearer'
            ]
        ], 200);
    } catch (\Exception $e) {
        \Log::error('Error en login: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => 'Error interno del servidor',
            'error' => $e->getMessage()
        ], 500);
    }
}
```

---

## 📝 **Checklist de Verificación Backend**

Verifica en tu backend Laravel:

- [ ] El endpoint `/api/login` existe y está configurado
- [ ] La ruta está registrada en `routes/api.php`
- [ ] El middleware está configurado correctamente
- [ ] La validación de email y password funciona
- [ ] La consulta a la base de datos funciona
- [ ] La generación del token funciona
- [ ] Los logs muestran el error específico
- [ ] La respuesta tiene el formato correcto

---

## 🧪 **Prueba el Endpoint Directamente**

### **Con curl (desde terminal):**
```bash
curl -X POST https://nawi.click/api/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"email":"tu_email@example.com","password":"tu_password"}'
```

### **Con Postman:**
1. Método: `POST`
2. URL: `https://nawi.click/api/login`
3. Headers:
   - `Content-Type: application/json`
   - `Accept: application/json`
4. Body (raw JSON):
```json
{
  "email": "tu_email@example.com",
  "password": "tu_password"
}
```

---

## 🔍 **Mejoras en el Código de la App**

He mejorado el `AuthService` para:
- ✅ Agregar header `Accept: application/json`
- ✅ Mejor manejo de errores 500
- ✅ Logging detallado para debugging
- ✅ Intentar parsear mensajes de error del servidor

Ahora cuando ejecutes la app, verás en la consola:
- 🔐 El email que intenta usar
- 🌐 La URL que está llamando
- 📡 El status code recibido
- 📦 La respuesta completa del servidor
- ❌ Cualquier error específico

---

## 📞 **Siguiente Paso**

1. **Ejecuta la app** y revisa la consola de Flutter
2. **Revisa los logs del backend** (Laravel)
3. **Compara** la estructura del request con lo que espera tu backend
4. **Ajusta** el backend o el request según sea necesario

---

## 💡 **Consejos**

- El error 500 **siempre** es un problema del backend
- Revisa los logs de Laravel para ver el error específico
- Verifica que el endpoint funcione en Postman primero
- Compara la estructura de datos entre lo que envía la app y lo que espera el backend

