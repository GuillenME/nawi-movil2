# ✅ Solución Final: Error "Sesión Expirada" al Solicitar Taxi

## 🔧 **Cambios Aplicados en el Código**

He modificado el código para hacer el manejo de autenticación más robusto:

1. **Verificación mejorada del token** antes de enviar la petición
2. **Limpieza del token** (quitar espacios que puedan causar problemas)
3. **Mejor logging** para diagnosticar problemas
4. **Manejo de errores mejorado** para identificar el problema exacto

---

## 📋 **Si el Error Persiste, Prueba Esto:**

### **Opción 1: El backend requiere `id_pasajero` en el body**

En `lib/services/pasajero_service.dart`, línea ~86, **descomenta** esta línea:

```dart
'id_pasajero': user.id,  // ← DESCOMENTAR esta línea
```

Esto hará que el código envíe el ID del pasajero en el body del request.

**Luego en tu backend Laravel**, asegúrate de que valida el ID:

```php
// En tu controlador
public function crearViaje(Request $request)
{
    $user = Auth::user(); // Del token
    $idPasajero = $request->id_pasajero ?? $user->id; // Del body o del token
    
    // Validar que el ID existe
    $pasajero = User::find($idPasajero);
    if (!$pasajero) {
        return response()->json([
            'success' => false,
            'message' => 'El pasajero no existe'
        ], 422);
    }
    
    // Crear el viaje...
}
```

---

### **Opción 2: El backend obtiene `id_pasajero` del token**

Si tu backend usa `Auth::user()->id` para obtener el ID del pasajero, entonces:

1. **NO envíes `id_pasajero` en el body** (ya está comentado por defecto)
2. **Asegúrate que tu backend valide correctamente el token:**

```php
// En tu controlador
public function crearViaje(Request $request)
{
    // Verificar que el usuario está autenticado
    if (!Auth::check()) {
        return response()->json([
            'success' => false,
            'message' => 'No autorizado'
        ], 401);
    }
    
    $user = Auth::user();
    $idPasajero = $user->id; // Obtener del token
    
    // Crear el viaje...
}
```

---

### **Opción 3: El token no se está guardando correctamente**

Si el token no se guarda después del login:

1. **Verifica que el backend retorne el token en el formato correcto:**

```json
{
  "success": true,
  "data": {
    "usuario": {...},
    "access_token": "token_aqui",  // ← Debe estar aquí
    "tipo": "pasajero"
  }
}
```

2. **Verifica en la consola de Flutter** cuando inicias sesión:
   - Debe aparecer: `✅ Token recibido: ... caracteres`
   - Debe aparecer: `✅ Token guardado en SharedPreferences: SÍ`

3. **Si el token no se guarda**, el problema está en el backend (no retorna `access_token`)

---

## 🔍 **Diagnóstico Rápido**

### **1. Revisa la consola cuando intentas solicitar un taxi:**

Busca estos mensajes:
- `🔐 Token obtenido: ... caracteres` → Si no aparece, el token no se guardó
- `🔐 Enviando request a: ...` → Confirma que se está enviando la petición
- `📡 Status Code: 401` → Confirma que es un error de autenticación

### **2. Revisa la consola cuando inicias sesión:**

Busca estos mensajes:
- `✅ Token recibido: ... caracteres` → Confirma que el backend retorna el token
- `✅ Token guardado en SharedPreferences: SÍ` → Confirma que se guardó

---

## 🎯 **Solución Recomendada**

**Si tu backend usa Laravel Passport o Sanctum:**

1. **El backend DEBE obtener `id_pasajero` del token** (más seguro)
2. **NO envíes `id_pasajero` en el body** (ya está comentado)
3. **El backend debe validar el token correctamente:**

```php
// En routes/api.php
Route::middleware('auth:api')->group(function () {
    Route::post('/pasajero/crear-viaje', [PasajeroController::class, 'crearViaje']);
});

// En tu controlador
public function crearViaje(Request $request)
{
    $user = Auth::user(); // Obtiene del token
    $idPasajero = $user->id; // Usa el ID del usuario autenticado
    
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
        'pasajero_id' => $idPasajero,
        'taxista_id' => $idTaxista,
        'latitud_origen' => $request->salida['lat'],
        'longitud_origen' => $request->salida['lon'],
        'latitud_destino' => $request->destino['lat'],
        'longitud_destino' => $request->destino['lon'],
        'estado' => 'solicitado',
    ]);
    
    return response()->json([
        'success' => true,
        'message' => 'Viaje creado exitosamente',
        'data' => $viaje
    ], 201);
}
```

---

## 📝 **Checklist Final**

- [ ] El backend retorna `access_token` en el login
- [ ] El token se guarda en SharedPreferences después del login
- [ ] El token se recupera correctamente antes de crear el viaje
- [ ] El backend valida el token correctamente (middleware `auth:api`)
- [ ] El backend obtiene `id_pasajero` del token o del body (según tu implementación)
- [ ] El backend valida que el taxista existe si se envía `id_taxista`

Con estos cambios, el error "Sesión expirada" debería desaparecer.

