# 🔍 Diagnóstico: Error "IDs inválidos" al Solicitar Taxi

## ❌ **Error Actual:**
```
The selected id pasajero is invalid., The selected id taxista is invalid.
```

## 🔍 **Pasos para Diagnosticar:**

### **1. Revisa la Consola de Flutter**

Cuando intentes solicitar un taxi, verás en la consola algo como:

```
🔐 Creando viaje con token: ...
👤 Usuario ID: ...
👤 Usuario tipo: ...
👤 Usuario rolId: ...
🚕 Taxista ID: ...
📝 Configuración del request: ...
📤 Enviando datos: ...
📦 Body JSON: {...}
📡 Status Code: 422
📦 Response Body: {...}
```

**Comparte estos valores** para identificar el problema exacto.

---

## 🎯 **Soluciones Rápidas:**

### **Solución 1: El Backend obtiene `id_pasajero` del Token**

En `lib/services/pasajero_service.dart`, línea 77, **comenta** la línea:

```dart
// 'id_pasajero': user.id,  // ← COMENTAR esta línea
```

Esto hará que el backend obtenga el ID del usuario del token (más seguro).

**Luego en tu backend Laravel**, asegúrate de que obtiene el ID del token:

```php
// En tu controlador
public function crearViaje(Request $request)
{
    $user = Auth::user(); // Obtiene del token
    $idPasajero = $user->id; // Usa el ID real del usuario autenticado
    
    // ... resto del código ...
}
```

---

### **Solución 2: El Backend requiere `id_pasajero` en el Body**

Si el backend necesita `id_pasajero` en el body, entonces:

1. **Asegúrate que el backend retorne el ID REAL en el login:**

```php
// En AuthController.php
return response()->json([
    'success' => true,
    'data' => [
        'usuario' => [
            'id' => (string)$user->id,  // ← ID REAL de MySQL, NO placeholder
            // ...
        ],
    ],
]);
```

2. **Verifica en MySQL que el ID existe:**

```sql
SELECT id, nombre, email, id_rol FROM users WHERE id = 'ID_QUE_SE_ENVIA';
```

---

### **Solución 3: El ID del Taxista no coincide**

El ID del taxista viene de Firebase (key del nodo), pero puede que no coincida con el ID en MySQL.

**Opción A: Guardar el ID de MySQL en Firebase**

Cuando el taxista actualiza su ubicación, guarda también su ID de MySQL:

```dart
// En el código del taxista (cuando actualiza ubicación)
await taxisRef.child(user.id).set({  // ← Usar ID real de MySQL como key
  'disponible': true,
  'latitude': lat,
  'longitude': lon,
  'user_id': user.id,  // ← ID real de MySQL
  'timestamp': now,
});
```

**Opción B: En el backend, buscar el taxista por email o nombre**

En tu controlador Laravel, si recibes un ID de Firebase que no coincide, puedes buscar el taxista de otra forma:

```php
// En tu controlador
if ($request->has('id_taxista')) {
    // Opción 1: Buscar directamente (si el ID coincide)
    $taxista = User::find($request->id_taxista);
    
    // Opción 2: Si no coincide, buscar por otro campo
    // Por ejemplo, si Firebase tiene un campo 'email' o 'user_id'
    // $taxista = User::where('email', $request->taxista_email)->first();
    
    if (!$taxista || $taxista->id_rol != 3) {
        return response()->json([
            'success' => false,
            'message' => 'El taxista seleccionado no es válido'
        ], 422);
    }
}
```

---

## 📋 **Checklist de Verificación:**

- [ ] El backend retorna el **ID real** del usuario en el login (no placeholder)
- [ ] El ID del usuario en Flutter coincide con el ID en MySQL
- [ ] El ID del taxista en Firebase corresponde con el ID en MySQL
- [ ] El backend valida que el taxista existe antes de crear el viaje
- [ ] Los logs muestran qué IDs se están enviando

---

## 🧪 **Prueba Esto:**

1. **Prueba SIN enviar `id_pasajero` en el body:**
   - Comenta la línea 77 en `pasajero_service.dart`
   - El backend debe usar `Auth::user()->id`

2. **Si sigue fallando, verifica:**
   - ¿Qué ID retorna el backend en el login?
   - ¿Ese ID existe en MySQL?
   - ¿El ID del taxista de Firebase coincide con MySQL?

3. **Comparte los logs:**
   - Los valores de `👤 Usuario ID: ...`
   - Los valores de `🚕 Taxista ID: ...`
   - El `📦 Body JSON: ...`
   - El `📦 Response Body: ...`

Con esa información podré ajustar el código exactamente como necesita tu backend.

