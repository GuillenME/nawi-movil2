# 🔐 Lógica de Autenticación para Taxista

## 📋 **Cómo Funciona el Login de Taxista**

La aplicación determina si un usuario es **taxista** o **pasajero** basándose en la respuesta del backend después del login.

---

## 🔄 **Flujo Completo**

### **1. Login (Usuario ingresa credenciales)**

```40:40:lib/services/auth_service.dart
            await prefs.setString('tipo', data['data']['tipo']);
```

El backend debe retornar en la respuesta:

```json
{
  "success": true,
  "data": {
    "usuario": {
      "id": "uuid",
      "nombre": "Juan",
      "apellido": "Pérez",
      "email": "juan@email.com",
      "id_rol": "3",  // ← IMPORTANTE: 3 = taxista, 2 = pasajero
      "telefono": "1234567890"
    },
    "tipo": "taxista",  // ← IMPORTANTE: "taxista" o "pasajero"
    "access_token": "token_aqui"
  }
}
```

### **2. Guardado de Datos**

```35:41:lib/services/auth_service.dart
            // Guardar datos del usuario en SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                'user_data', jsonEncode(data['data']['usuario']));
            await prefs.setString('token', data['data']['access_token']);
            await prefs.setString('tipo', data['data']['tipo']);
            await prefs.setBool('is_logged_in', true);
```

Se guardan:
- Datos del usuario (incluye `id_rol`)
- Token de acceso
- **Tipo** (`"taxista"` o `"pasajero"`)
- Estado de login

### **3. Detección del Tipo de Usuario**

```52:54:lib/models/user_model.dart
  String get nombreCompleto => '$nombre $apellido';
  bool get isTaxista => tipo == 'taxista' || rolId == '3';
  bool get isPasajero => tipo == 'pasajero' || rolId == '2';
```

El modelo `UserModel` tiene dos formas de determinar si es taxista:
1. **Por `tipo`**: Si `tipo == 'taxista'`
2. **Por `rolId`**: Si `rolId == '3'` (rol 3 = taxista)

**Prioridad:** Se usa `tipo` primero, si no está, se usa `rolId`.

### **4. Navegación a la Pantalla Correcta**

```75:75:lib/views/home_page.dart
      body: _currentUser!.isTaxista ? TaxistaHomePage() : PasajeroHomePage(),
```

En `HomePage`, se verifica:
- Si `isTaxista == true` → Muestra `TaxistaHomePage()`
- Si `isTaxista == false` → Muestra `PasajeroHomePage()`

---

## ✅ **Requisitos para que un Usuario Sea Taxista**

### **En el Backend Laravel:**

El endpoint `POST /api/login` debe retornar:

**Opción 1: Usando el campo `tipo`:**
```json
{
  "success": true,
  "data": {
    "usuario": {
      "id": "uuid",
      "nombre": "Juan",
      "apellido": "Pérez",
      "email": "juan@email.com",
      "id_rol": "3",
      "telefono": "1234567890"
    },
    "tipo": "taxista",  // ← Debe ser "taxista"
    "access_token": "token_aqui"
  }
}
```

**Opción 2: Sin campo `tipo`, solo con `id_rol`:**
```json
{
  "success": true,
  "data": {
    "usuario": {
      "id": "uuid",
      "nombre": "Juan",
      "apellido": "Pérez",
      "email": "juan@email.com",
      "id_rol": "3",  // ← Debe ser "3" para taxista
      "telefono": "1234567890"
    },
    "access_token": "token_aqui"
  }
}
```

**Nota:** Si no se envía `tipo`, la app detectará automáticamente por `id_rol == '3'`.

---

## 🔧 **Implementación en el Backend Laravel**

### **Ejemplo de Controlador de Login:**

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

    // Determinar el tipo de usuario
    $tipo = $user->id_rol == 3 ? 'taxista' : 'pasajero';

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
            'tipo' => $tipo,  // ← IMPORTANTE
            'access_token' => $token,
            'token_type' => 'Bearer'
        ]
    ], 200);
}
```

---

## 📊 **Tabla de Roles**

| Rol ID | Tipo      | Descripción |
|--------|-----------|-------------|
| 2      | pasajero  | Usuario que solicita viajes |
| 3      | taxista   | Usuario que ofrece servicios de transporte |

**Nota:** El rol 1 generalmente es para administradores.

---

## 🧪 **Cómo Probar**

### **1. Verificar que el Usuario Tenga el Rol Correcto:**

En tu base de datos:

```sql
-- Verificar usuarios taxistas
SELECT id, nombre, email, id_rol FROM users WHERE id_rol = 3;

-- O si usas una tabla de roles diferente:
SELECT u.id, u.nombre, u.email, r.id as rol_id, r.nombre as rol_nombre
FROM users u
JOIN roles r ON u.id_rol = r.id
WHERE r.id = 3;
```

### **2. Probar el Login con Postman:**

```
POST https://nawi.click/api/login
Headers:
  Content-Type: application/json
  Accept: application/json
Body:
{
  "email": "taxista@example.com",
  "password": "password123"
}
```

**Respuesta esperada:**
```json
{
  "success": true,
  "data": {
    "usuario": {
      "id_rol": "3",
      ...
    },
    "tipo": "taxista",
    "access_token": "..."
  }
}
```

### **3. Verificar en la App:**

1. Abre la app
2. Inicia sesión con un usuario que tenga `id_rol = 3`
3. Debe mostrar `TaxistaHomePage` automáticamente

---

## 🔍 **Debugging**

### **Si un taxista no entra como taxista:**

1. **Verifica la respuesta del backend:**
   - Revisa los logs de Flutter (los prints que agregamos)
   - Verifica que `tipo: "taxista"` o `id_rol: "3"` estén en la respuesta

2. **Verifica el modelo de usuario:**
   ```dart
   final user = await AuthService.getCurrentUser();
   print('Tipo: ${user?.tipo}');
   print('Rol ID: ${user?.rolId}');
   print('Is Taxista: ${user?.isTaxista}');
   ```

3. **Verifica SharedPreferences:**
   ```dart
   final prefs = await SharedPreferences.getInstance();
   print('Tipo guardado: ${prefs.getString('tipo')}');
   ```

---

## 📝 **Resumen**

**Para que un usuario entre como taxista:**

1. ✅ El usuario debe tener `id_rol = 3` en la base de datos
2. ✅ El backend debe retornar `tipo: "taxista"` en la respuesta del login
3. ✅ O el backend debe retornar `id_rol: "3"` en los datos del usuario
4. ✅ La app detectará automáticamente y mostrará `TaxistaHomePage`

**No se requiere ningún cambio adicional en la app Flutter.** La lógica ya está implementada y funcionará automáticamente cuando el backend retorne los datos correctos.

---

## 🎯 **Checklist para el Backend**

- [ ] El endpoint `/api/login` retorna `tipo: "taxista"` para usuarios con `id_rol = 3`
- [ ] El endpoint `/api/login` retorna `tipo: "pasajero"` para usuarios con `id_rol = 2`
- [ ] Los datos del usuario incluyen `id_rol` en la respuesta
- [ ] La estructura de la respuesta coincide con lo esperado por la app

