# 🔧 Solución: Error "The selected id pasajero is invalid., The selected id taxista is invalid."

## ❌ **Error que estás viendo:**
```
The selected id pasajero is invalid., The selected id taxista is invalid.
```

## 🔍 **¿Qué significa?**

Este error indica que el backend Laravel está validando que los IDs (`id_pasajero` e `id_taxista`) existan en la base de datos, pero no los encuentra.

---

## 🔍 **Causas Posibles**

### **1. El `id_pasajero` no existe en la base de datos**

El backend puede estar validando:
```php
// En Laravel
$request->validate([
    'id_pasajero' => 'required|exists:users,id',
    // o
    'id_pasajero' => 'required|exists:pasajeros,id',
]);
```

**Posibles problemas:**
- El `user.id` es un UUID pero la tabla usa enteros
- El `user.id` no coincide con el ID en la base de datos
- El backend espera obtener el `id_pasajero` del token (usuario autenticado) en lugar del body

### **2. El `id_taxista` no existe en la base de datos**

El ID del taxista viene de Firebase (la key del nodo), pero puede que:
- No corresponda con el ID real en MySQL
- El taxista no esté registrado en la tabla `users` o `taxistas`
- El formato del ID sea diferente (UUID vs entero)

### **3. El backend espera obtener `id_pasajero` del token**

Algunos backends obtienen el ID del usuario del token JWT en lugar del body:

```php
// En Laravel (usando el token)
$user = Auth::user(); // Obtiene el usuario del token
$idPasajero = $user->id; // Usa el ID del usuario autenticado
```

En este caso, **no debes enviar `id_pasajero` en el body**.

---

## ✅ **Soluciones**

### **Opción 1: No enviar `id_pasajero` (si el backend lo obtiene del token)**

Si tu backend obtiene el ID del usuario del token, **elimina `id_pasajero` del body**:

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

### **Opción 2: Verificar que los IDs existan en la base de datos**

**En el backend Laravel**, verifica que:

1. **El usuario existe:**
```php
// En tu controlador
$user = Auth::user(); // Del token
// O si usas el ID del body:
$pasajero = User::find($request->id_pasajero);
if (!$pasajero) {
    return response()->json([
        'success' => false,
        'message' => 'El pasajero no existe'
    ], 422);
}
```

2. **El taxista existe (si se envía):**
```php
if ($request->has('id_taxista')) {
    $taxista = User::find($request->id_taxista);
    if (!$taxista || $taxista->id_rol != 3) { // 3 = taxista
        return response()->json([
            'success' => false,
            'message' => 'El taxista no existe o no es válido'
        ], 422);
    }
}
```

### **Opción 3: Mapear IDs de Firebase a IDs de MySQL**

Si el `id_taxista` viene de Firebase pero necesita ser el ID de MySQL:

**Opción A: Guardar el ID de MySQL en Firebase**
```dart
// Cuando el taxista se conecta, guardar también su ID de MySQL
await taxisRef.child(taxistaId).set({
  'disponible': true,
  'latitude': lat,
  'longitude': lon,
  'user_id': user.id, // ID de MySQL aquí
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});
```

**Opción B: Buscar el ID de MySQL desde Firebase**
En el backend, cuando recibas el `id_taxista` de Firebase:
```php
// Buscar el usuario por el ID de Firebase o por algún campo relacionado
$taxista = DB::table('users')
    ->where('firebase_id', $request->id_taxista) // O el campo que uses
    ->where('id_rol', 3)
    ->first();
```

---

## 🧪 **Cómo Diagnosticar**

### **1. Revisa la consola de Flutter**

Cuando intentes crear el viaje, verás:
```
👤 Usuario ID: ...
🚕 Taxista ID: ...
📤 Enviando datos: ...
📦 Body JSON: {...}
📡 Status Code: 422
❌ Error 422 (Validación): ...
```

**Comparte estos valores** para identificar el problema.

### **2. Verifica en el backend**

**En tu controlador Laravel**, agrega logging:

```php
public function crearViaje(Request $request) {
    \Log::info('Crear viaje request', [
        'id_pasajero' => $request->id_pasajero,
        'id_taxista' => $request->id_taxista,
        'user_from_token' => Auth::id(), // ID del usuario autenticado
    ]);
    
    // Verificar que el usuario existe
    $userFromToken = Auth::user();
    \Log::info('Usuario del token', [
        'id' => $userFromToken->id,
        'email' => $userFromToken->email,
    ]);
    
    // Si se envía id_taxista, verificar que existe
    if ($request->id_taxista) {
        $taxista = User::find($request->id_taxista);
        \Log::info('Taxista buscado', [
            'id_buscado' => $request->id_taxista,
            'encontrado' => $taxista ? 'Sí' : 'No',
        ]);
    }
    
    // Tu lógica...
}
```

### **3. Verifica en la base de datos**

**Ejecuta estos queries:**

```sql
-- Verificar que el usuario existe
SELECT id, email, id_rol FROM users WHERE id = 'ID_DEL_USUARIO';

-- Verificar que el taxista existe
SELECT id, email, id_rol FROM users WHERE id = 'ID_DEL_TAXISTA' AND id_rol = 3;

-- Ver todos los taxistas
SELECT id, email, id_rol FROM users WHERE id_rol = 3;
```

---

## 🔧 **Cambios en el Backend (Recomendado)**

### **Opción 1: Obtener `id_pasajero` del token (Más seguro)**

```php
// En tu controlador
public function crearViaje(Request $request) {
    $user = Auth::user(); // Obtener del token
    $idPasajero = $user->id; // Usar el ID del usuario autenticado
    
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
    
    // Crear el viaje usando $idPasajero y $idTaxista
    // ...
}
```

### **Opción 2: Validar que el `id_pasajero` del body coincida con el token**

```php
public function crearViaje(Request $request) {
    $user = Auth::user();
    
    // Verificar que el id_pasajero del body coincida con el usuario autenticado
    if ($request->id_pasajero != $user->id) {
        return response()->json([
            'success' => false,
            'message' => 'El ID del pasajero no coincide con el usuario autenticado'
        ], 422);
    }
    
    // Validar taxista...
}
```

---

## 📝 **Checklist de Verificación**

- [ ] El `user.id` en Flutter coincide con el ID en MySQL
- [ ] El backend valida que el usuario existe
- [ ] El backend valida que el taxista existe (si se envía)
- [ ] El formato del ID es correcto (UUID vs entero)
- [ ] El backend obtiene `id_pasajero` del token o del body (según tu implementación)
- [ ] Los logs muestran los IDs que se están enviando

---

## 🎯 **Próximos Pasos**

1. **Revisa la consola de Flutter** y comparte:
   - El `👤 Usuario ID: ...`
   - El `🚕 Taxista ID: ...`
   - El `📦 Body JSON: ...`
   - El `📦 Response Body: ...`

2. **Verifica en MySQL:**
   - ¿Existe el usuario con ese ID?
   - ¿Existe el taxista con ese ID?
   - ¿Qué formato tienen los IDs? (UUID o entero)

3. **Ajusta el backend** según corresponda:
   - Si obtienes `id_pasajero` del token, no lo envíes en el body
   - Si validas el `id_taxista`, asegúrate de que exista en la BD

Con esa información podré ajustar el código de Flutter para que envíe los datos en el formato correcto.

