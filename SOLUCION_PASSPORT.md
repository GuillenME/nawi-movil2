# 🔧 Solución: Error "Personal access client not found"

## ❌ **Error que estás viendo:**
```
Personal access client not found. Please create one.
```

## 🔍 **¿Qué significa?**

Este error **NO es un problema de tu cuenta** en la base de datos. El problema es que **Laravel Passport** no tiene configurado el "Personal Access Client" que se usa para generar tokens de autenticación.

---

## ✅ **Solución: Crear el Personal Access Client en el Backend**

### **Opción 1: Usar el comando de Laravel (Recomendado)**

Ejecuta estos comandos **en tu servidor backend** (donde está el código Laravel):

```bash
# 1. Asegúrate de estar en el directorio del proyecto Laravel
cd /ruta/a/tu/proyecto/laravel

# 2. Instala Passport (si no está instalado)
php artisan passport:install

# 3. Si solo falta el personal access client, crea uno manualmente:
php artisan passport:client --personal
```

### **Opción 2: Crear manualmente en la Base de Datos**

Si no tienes acceso SSH al servidor, puedes crear el cliente directamente en la base de datos:

**1. Conéctate a tu base de datos MySQL**

**2. Ejecuta este INSERT:**

```sql
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

-- Actualiza la tabla oauth_personal_access_clients
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

**3. Verifica que se creó correctamente:**

```sql
SELECT * FROM oauth_clients WHERE personal_access_client = 1;
SELECT * FROM oauth_personal_access_clients;
```

---

## 🔄 **Alternativa: Cambiar a Laravel Sanctum**

Si prefieres usar **Laravel Sanctum** (más simple y recomendado para APIs móviles), puedes cambiar el backend:

### **1. Instalar Sanctum:**

```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
```

### **2. Configurar el modelo User:**

```php
// app/Models/User.php
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;
    // ... resto del código
}
```

### **3. Modificar el controlador de Login:**

```php
// app/Http/Controllers/AuthController.php
public function login(Request $request)
{
    $request->validate([
        'email' => 'required|email',
        'password' => 'required|string',
    ]);

    if (!Auth::attempt($request->only('email', 'password'))) {
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
            'usuario' => [
                'id' => $user->id,
                'nombre' => $user->nombre,
                'apellido' => $user->apellido,
                'email' => $user->email,
                'id_rol' => $user->id_rol,
                'telefono' => $user->telefono,
            ],
            'tipo' => $user->id_rol == 3 ? 'taxista' : 'pasajero',
            'access_token' => $token,
            'token_type' => 'Bearer'
        ]
    ], 200);
}
```

---

## 📋 **Verificación del Backend**

### **1. Verifica que Passport esté instalado:**

En tu backend Laravel, verifica:

```bash
# En el servidor
php artisan list | grep passport
```

Deberías ver comandos como:
- `passport:install`
- `passport:client`
- `passport:keys`

### **2. Verifica las tablas de Passport:**

Asegúrate de que existan estas tablas en tu base de datos:
- `oauth_clients`
- `oauth_personal_access_clients`
- `oauth_access_tokens`

Si no existen, ejecuta:
```bash
php artisan migrate
```

### **3. Verifica la configuración:**

En `config/auth.php`:
```php
'guards' => [
    'api' => [
        'driver' => 'passport',
        'provider' => 'users',
    ],
],
```

---

## 🧪 **Cómo Probar**

### **1. Verifica que el cliente existe:**

```sql
-- En tu base de datos
SELECT * FROM oauth_clients WHERE personal_access_client = 1;
```

Si no hay resultados, crea el cliente usando una de las opciones anteriores.

### **2. Prueba el login desde Postman:**

```
POST https://nawi.click/api/login
Headers:
  Content-Type: application/json
  Accept: application/json
Body:
{
  "email": "guillenmariana550@gmail.com",
  "password": "Mariana06"
}
```

### **3. Si funciona en Postman pero no en la app:**

- Verifica los headers que envía la app
- Verifica que el formato del request sea correcto

---

## 🎯 **Resumen de la Solución**

**El problema:** Laravel Passport necesita un "Personal Access Client" para generar tokens.

**La solución rápida:**
1. Ejecuta `php artisan passport:client --personal` en tu servidor
2. O crea el cliente manualmente en la base de datos (SQL arriba)

**Alternativa (más simple):**
- Cambiar de Passport a Sanctum (más fácil para APIs móviles)

---

## 📞 **Si necesitas ayuda adicional**

Comparte:
1. ¿Tienes acceso SSH al servidor?
2. ¿Qué versión de Laravel estás usando?
3. ¿Estás usando Passport o Sanctum?
4. ¿Puedes ejecutar comandos artisan en el servidor?

Con esa información puedo darte instrucciones más específicas.

