# 🔧 Solución: IDs Placeholder vs IDs Reales

## ❌ **Problema Identificado**

Los IDs que estás usando son **valores placeholder** (UUIDs genéricos) que se usan para detectar el **rol** del usuario, pero **NO son los IDs reales** de los usuarios en la base de datos MySQL.

### **IDs Placeholder (NO son IDs reales):**
- `00000000-0000-0000-0000-000000000002` → Rol de **pasajero** (no es un ID real)
- `00000000-0000-0000-0000-000000000003` → Rol de **taxista** (no es un ID real)

Estos UUIDs se usan solo para **detectar el tipo de usuario** en el código Flutter, pero el backend necesita los **IDs reales** de los usuarios que existen en la tabla `users` de MySQL.

---

## 🔍 **¿Qué está pasando?**

### **1. En el Login:**

El backend debe retornar el **ID real** del usuario en la respuesta:

```json
{
  "success": true,
  "data": {
    "usuario": {
      "id": "123e4567-e89b-12d3-a456-426614174000",  // ← ID REAL del usuario en MySQL
      "nombre": "Juan",
      "apellido": "Pérez",
      "email": "juan@email.com",
      "id_rol": "3",  // ← Esto es el ROL, no el ID
      "telefono": "1234567890"
    },
    "tipo": "taxista",
    "access_token": "token_aqui"
  }
}
```

**El problema:** Si el backend retorna `id: "00000000-0000-0000-0000-000000000003"`, ese es un placeholder, no el ID real.

### **2. Al Crear un Viaje:**

El código Flutter envía `user.id` al backend:

```dart
final requestBody = {
  'id_pasajero': user.id,  // ← Si esto es un placeholder, el backend lo rechaza
  'salida': { ... },
  'destino': { ... },
};
```

Si `user.id` es un placeholder, el backend no lo encontrará en la tabla `users` y retornará:
```
The selected id pasajero is invalid.
```

### **3. ID del Taxista desde Firebase:**

Cuando seleccionas un taxista en el mapa, el ID viene de **Firebase** (la key del nodo):

```dart
// En solicitar_viaje_con_mapa_page.dart
idTaxista: _taxistaSeleccionado!['id'],  // ← Key de Firebase
```

Este ID puede ser diferente del ID real del usuario en MySQL.

---

## ✅ **Soluciones**

### **Solución 1: El Backend debe retornar el ID Real del Usuario**

**En tu controlador de login (`AuthController.php`):**

```php
public function login(Request $request)
{
    // ... validación y autenticación ...
    
    $user = Auth::user();
    
    return response()->json([
        'success' => true,
        'message' => 'Login exitoso',
        'data' => [
            'usuario' => [
                'id' => (string)$user->id,  // ← ID REAL del usuario (convertido a string)
                'nombre' => $user->nombre,
                'apellido' => $user->apellido,
                'email' => $user->email,
                'id_rol' => (string)$user->id_rol,  // ← ROL (2 o 3)
                'telefono' => $user->telefono,
            ],
            'tipo' => $user->id_rol == 3 ? 'taxista' : 'pasajero',
            'access_token' => $token,
        ]
    ], 200);
}
```

**Verifica en MySQL:**

```sql
-- Ver los IDs reales de tus usuarios
SELECT id, nombre, email, id_rol FROM users;

-- Ver ejemplo de IDs reales
SELECT id, nombre, email FROM users LIMIT 5;
```

---

### **Solución 2: Mapear IDs de Firebase a IDs de MySQL**

**Opción A: Guardar el ID de MySQL en Firebase**

Cuando un taxista se conecta y actualiza su ubicación en Firebase, guarda también su ID de MySQL:

```dart
// Cuando el taxista actualiza su ubicación
await taxisRef.child(user.id).set({  // ← Usar el ID real de MySQL como key
  'disponible': true,
  'latitude': lat,
  'longitude': lon,
  'user_id': user.id,  // ← ID real de MySQL
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});
```

**Opción B: Buscar el ID de MySQL desde el ID de Firebase**

En el backend, cuando recibas el `id_taxista` de Firebase:

```php
// En tu controlador de crear viaje
if ($request->has('id_taxista')) {
    // Si el id_taxista es una key de Firebase, necesitas mapearlo
    // Opción 1: Si Firebase usa el mismo ID que MySQL
    $taxista = User::find($request->id_taxista);
    
    // Opción 2: Si Firebase tiene un campo que mapea al ID de MySQL
    // Necesitarías una tabla de mapeo o un campo en Firebase
    
    if (!$taxista || $taxista->id_rol != 3) {
        return response()->json([
            'success' => false,
            'message' => 'El taxista seleccionado no es válido'
        ], 422);
    }
}
```

---

### **Solución 3: El Backend obtiene `id_pasajero` del Token (Recomendado)**

**En tu controlador Laravel:**

```php
public function crearViaje(Request $request)
{
    // Obtener el usuario del token (más seguro)
    $user = Auth::user();
    $idPasajero = $user->id;  // ← ID REAL del usuario autenticado
    
    // NO usar $request->id_pasajero, usar el del token
    // Esto evita que alguien envíe un ID diferente
    
    // Validar taxista si se envía
    $idTaxista = null;
    if ($request->has('id_taxista') && $request->id_taxista) {
        $taxista = User::find($request->id_taxista);
        if (!$taxista || $taxista->id_rol != 3) {
            return response()->json([
                'success' => false,
                'message' => 'El taxista seleccionado no es válido'
            ], 422);
        }
        $idTaxista = $taxista->id;
    }
    
    // Crear el viaje
    $viaje = Viaje::create([
        'pasajero_id' => $idPasajero,  // ← ID real del usuario autenticado
        'taxista_id' => $idTaxista,
        'latitud_origen' => $request->salida['lat'],
        'longitud_origen' => $request->salida['lon'],
        'latitud_destino' => $request->destino['lat'],
        'longitud_destino' => $request->destino['lon'],
        'estado' => 'solicitado',
    ]);
    
    // ... resto del código ...
}
```

**Y en Flutter, NO enviar `id_pasajero`:**

```dart
// En lib/services/pasajero_service.dart
final requestBody = {
  // NO enviar 'id_pasajero' - el backend lo obtiene del token
  'salida': {
    'lat': salidaLat,
    'lon': salidaLon,
  },
  'destino': {
    'lat': destinoLat,
    'lon': destinoLon,
  },
};
```

---

## 🧪 **Cómo Verificar**

### **1. Verificar el ID que retorna el backend en el login:**

**En Flutter, después del login:**

```dart
final user = await AuthService.getCurrentUser();
print('ID del usuario: ${user.id}');
print('Tipo: ${user.tipo}');
print('Rol ID: ${user.rolId}');
```

**Si ves `00000000-0000-0000-0000-000000000002` o `00000000-0000-0000-0000-000000000003`, el backend está retornando un placeholder.**

### **2. Verificar en MySQL:**

```sql
-- Ver todos los usuarios con sus IDs reales
SELECT id, nombre, email, id_rol FROM users;

-- Ver un usuario específico
SELECT id, nombre, email, id_rol FROM users WHERE email = 'tu_email@ejemplo.com';
```

### **3. Verificar en Firebase:**

```javascript
// En Firebase Realtime Database
// Ver la estructura de /taxis
{
  "taxis": {
    "key-123": {  // ← Esta key puede no coincidir con el ID de MySQL
      "disponible": true,
      "latitude": 16.867,
      "longitude": -92.094
    }
  }
}
```

---

## 📝 **Checklist de Verificación**

- [ ] El backend retorna el **ID real** del usuario en el login (no placeholder)
- [ ] El ID del usuario en Flutter coincide con el ID en MySQL
- [ ] El ID del taxista en Firebase corresponde con el ID en MySQL (o se mapea)
- [ ] El backend valida que el taxista existe en MySQL antes de crear el viaje
- [ ] El backend obtiene el `id_pasajero` del token (más seguro) o del body

---

## 🎯 **Próximos Pasos**

1. **Verifica qué ID retorna tu backend en el login:**
   - Haz un login y revisa la respuesta
   - Confirma que el `id` sea el ID real del usuario en MySQL

2. **Si el backend retorna placeholders:**
   - Modifica el controlador de login para retornar `$user->id` (ID real)
   - No uses UUIDs placeholder como IDs

3. **Para el ID del taxista:**
   - Asegúrate de que el ID de Firebase corresponda con el ID de MySQL
   - O implementa un mapeo entre Firebase y MySQL

4. **Recomendación:**
   - Haz que el backend obtenga el `id_pasajero` del token (más seguro)
   - Solo valida el `id_taxista` si se envía

Con estos cambios, el error "The selected id pasajero is invalid" debería desaparecer.

