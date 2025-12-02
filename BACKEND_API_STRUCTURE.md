# Documentación de APIs - Cambios Recientes

## 📋 Índice

1. [APIs de Viajes](#apis-de-viajes)
2. [API de Perfil](#api-de-perfil)

---

## 🚗 APIs de Viajes

### 1. POST /api/pasajero/crear-viaje

**Descripción:** Crear un nuevo viaje (con o sin taxista específico)

**Autenticación:** Requerida (Bearer Token)

**Request Body:**

```json
{
  "salida": {
    "lat": 16.867,
    "lon": -92.094
  },
  "destino": {
    "lat": 16.900,
    "lon": -92.100
  },
  "id_taxista": "uuid-del-taxista",  // OPCIONAL: Si se quiere solicitar a un taxista específico
  "tiempo_limite_minutos": 5  // OPCIONAL: Tiempo límite en minutos (1-30), por defecto 5
}
```

**Response Success (201):**

```json
{
  "success": true,
  "message": "Viaje creado exitosamente",
  "data": {
    "id_pasajero": "uuid-del-pasajero",
    "id_taxista": null,
    "id_taxi": null,
    "latitud_origen": 16.867,
    "longitud_origen": -92.094,
    "direccion_origen": "Origen",
    "latitud_destino": 16.900,
    "longitud_destino": -92.100,
    "direccion_destino": "Destino",
    "estado": "solicitado",
    "fecha_aceptacion": null,
    "fecha_completado": null,
    "tiempo_limite_aceptacion": "2024-01-15T10:35:00Z",  // ⭐ NUEVO: 5 minutos después de la creación
    "tarifa": null,  // ⭐ NUEVO
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "pasajero": {
      "id": "uuid",
      "nombre": "Juan",
      "apellido": "Pérez",
      "email": "juan@example.com",
      "id_rol": "00000000-0000-0000-0000-000000000002",
      "telefono": "1234567890",
      "foto": null,
      "tipo": "pasajero"
    },
    "taxista": null
  }
}
```

---

### 2. GET /api/pasajero/mis-viajes

**Descripción:** Obtener todos los viajes del pasajero autenticado

**Autenticación:** Requerida (Bearer Token)

**Request:** No requiere parámetros

**Response Success (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-del-viaje",
      "pasajero_id": "uuid-del-pasajero",
      "taxista_id": "uuid-del-taxista",
      "latitud_origen": 16.867,
      "longitud_origen": -92.094,
      "direccion_origen": "Calle Principal 123",
      "latitud_destino": 16.900,
      "longitud_destino": -92.100,
      "direccion_destino": "Avenida Central 456",
      "estado": "completado",
      "fecha_creacion": "2024-01-15T10:30:00Z",
      "fecha_aceptacion": "2024-01-15T10:35:00Z",
      "fecha_completado": "2024-01-15T11:00:00Z",
      "tiempo_limite_aceptacion": "2024-01-15T10:35:00Z",  // ⭐ NUEVO
      "tarifa": 150.50,  // ⭐ NUEVO
      "calificacion": 4.5,
      "comentario": "Excelente servicio",
      "pasajero": {
        "id": "uuid",
        "nombre": "Juan",
        "apellido": "Pérez",
        "email": "juan@example.com",
        "id_rol": "00000000-0000-0000-0000-000000000002",
        "telefono": "1234567890",
        "foto": null,
        "tipo": "pasajero"
      },
      "taxista": {
        "id": "uuid",
        "nombre": "Carlos",
        "apellido": "García",
        "email": "carlos@example.com",
        "id_rol": "00000000-0000-0000-0000-000000000003",
        "telefono": "0987654321",
        "foto": null,
        "tipo": "taxista"
      }
    }
  ]
}
```

---

### 3. GET /api/taxista/viajes-disponibles

**Descripción:** Obtener viajes disponibles para el taxista autenticado (excluye expirados)

**Autenticación:** Requerida (Bearer Token)

**Request:** No requiere parámetros

**Response Success (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-del-viaje",
      "pasajero_id": "uuid-del-pasajero",
      "pasajero": {
        "nombre": "Juan",
        "apellido": "Pérez",
        "email": "juan@example.com"
      },
      "taxista": null,
      "latitud_origen": 16.867,
      "longitud_origen": -92.094,
      "direccion_origen": "Calle Principal 123",
      "latitud_destino": 16.900,
      "longitud_destino": -92.100,
      "direccion_destino": "Avenida Central 456",
      "estado": "solicitado",
      "fecha_creacion": "2024-01-15T10:30:00Z",
      "tiempo_limite_aceptacion": "2024-01-15T10:35:00Z",  // ⭐ NUEVO: Solo muestra viajes no expirados
      "tarifa": null  // ⭐ NUEVO
    }
  ]
}
```

**Nota:** ⭐ Solo muestra viajes que NO han expirado (tiempo_limite_aceptacion > ahora o es null)

---

### 4. POST /api/taxista/aceptar-viaje/{viajeId}

**Descripción:** Aceptar un viaje solicitado (con validación de tiempo límite y tarifa opcional)

**Autenticación:** Requerida (Bearer Token)

**Request Body:**

```json
{
  "tarifa": 150.50  // OPCIONAL: Tarifa que el taxista establece (0-9999.99)
}
```

**Response Success (200):**

```json
{
  "success": true,
  "message": "Viaje aceptado exitosamente",
  "data": {
    "id": "uuid-del-viaje",
    "pasajero_id": "uuid-del-pasajero",
    "taxista_id": "uuid-del-taxista",
    "latitud_origen": 16.867,
    "longitud_origen": -92.094,
    "direccion_origen": "Calle Principal 123",
    "latitud_destino": 16.900,
    "longitud_destino": -92.100,
    "direccion_destino": "Avenida Central 456",
    "estado": "aceptado",
    "fecha_creacion": "2024-01-15T10:30:00Z",
    "fecha_aceptacion": "2024-01-15T10:35:00Z",
    "fecha_completado": null,
    "tiempo_limite_aceptacion": "2024-01-15T10:35:00Z",  // ⭐ NUEVO
    "tarifa": 150.50,  // ⭐ NUEVO: Si se proporcionó en el request
    "calificacion": null,
    "comentario": null,
    "pasajero": {
      "id": "uuid",
      "nombre": "Juan",
      "apellido": "Pérez",
      "email": "juan@example.com",
      "id_rol": "00000000-0000-0000-0000-000000000002",
      "telefono": "1234567890",
      "foto": null,
      "tipo": "pasajero"
    },
    "taxista": {
      "id": "uuid",
      "nombre": "Carlos",
      "apellido": "García",
      "email": "carlos@example.com",
      "id_rol": "00000000-0000-0000-0000-000000000003",
      "telefono": "0987654321",
      "foto": null,
      "tipo": "taxista"
    }
  }
}
```

**Response Error - Viaje Expirado (422):**

```json
{
  "success": false,
  "message": "El tiempo límite para aceptar este viaje ha expirado"
}
```

**Response Error - Tarifa Inválida (422):**

```json
{
  "success": false,
  "message": "Datos de entrada inválidos",
  "errors": {
    "tarifa": ["El campo tarifa debe ser un número entre 0 y 9999.99"]
  }
}
```

---

### 5. GET /api/taxista/mis-viajes

**Descripción:** Obtener todos los viajes del taxista autenticado

**Autenticación:** Requerida (Bearer Token)

**Request:** No requiere parámetros

**Response Success (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-del-viaje",
      "pasajero_id": "uuid-del-pasajero",
      "taxista_id": "uuid-del-taxista",
      "latitud_origen": 16.867,
      "longitud_origen": -92.094,
      "direccion_origen": "Calle Principal 123",
      "latitud_destino": 16.900,
      "longitud_destino": -92.100,
      "direccion_destino": "Avenida Central 456",
      "estado": "completado",
      "fecha_creacion": "2024-01-15T10:30:00Z",
      "fecha_aceptacion": "2024-01-15T10:35:00Z",
      "fecha_completado": "2024-01-15T11:00:00Z",
      "tiempo_limite_aceptacion": "2024-01-15T10:35:00Z",  // ⭐ NUEVO
      "tarifa": 150.50,  // ⭐ NUEVO
      "calificacion": 4.5,
      "comentario": "Excelente servicio",
      "pasajero": {
        "id": "uuid",
        "nombre": "Juan",
        "apellido": "Pérez",
        "email": "juan@example.com",
        "id_rol": "00000000-0000-0000-0000-000000000002",
        "telefono": "1234567890",
        "foto": null,
        "tipo": "pasajero"
      },
      "taxista": {
        "id": "uuid",
        "nombre": "Carlos",
        "apellido": "García",
        "email": "carlos@example.com",
        "id_rol": "00000000-0000-0000-0000-000000000003",
        "telefono": "0987654321",
        "foto": null,
        "tipo": "taxista"
      }
    }
  ]
}
```

---

### 6. POST /api/pasajero/calificar-viaje/{viajeId}

**Descripción:** Califica un viaje completado

**Autenticación:** Requerida (Bearer Token)

**Request Body:**

```json
{
  "calificacion": 5,                    // int, requerido, rango 1-5
  "comentario": "Excelente servicio"      // string, opcional, máximo 500 caracteres
}
```

**Response Success (201):**

```json
{
  "success": true,
  "message": "Viaje calificado exitosamente",
  "data": {
    "id": "uuid-del-viaje",
    "calificacion": 5,
    "comentario": "Excelente servicio"
  }
}
```

**Response Error - Validación (422):**

```json
{
  "success": false,
  "message": "Datos de entrada inválidos",
  "errors": {
    "calificacion": ["El campo calificacion debe estar entre 1 y 5"],
    "comentario": ["El campo comentario no puede tener más de 500 caracteres"]
  }
}
```

**Response Error - Viaje no completado (422):**

```json
{
  "success": false,
  "message": "El viaje debe estar completado para poder calificarlo"
}
```

**Response Error - Viaje ya calificado (422):**

```json
{
  "success": false,
  "message": "Este viaje ya ha sido calificado"
}
```

**Response Error - No encontrado (404):**

```json
{
  "success": false,
  "message": "Viaje no encontrado o no pertenece al pasajero"
}
```

**Response Error - No autorizado (401):**

```json
{
  "success": false,
  "message": "Usuario no autenticado"
}
```

**Response Error - Prohibido (403):**

```json
{
  "success": false,
  "message": "Usuario no es un pasajero"
}
```

**Validaciones implementadas:**

- ✅ Verifica que el token JWT sea válido (middleware `auth:api` - retorna 401 si no es válido)
- ✅ Verifica que el usuario sea un pasajero (retorna 403 si no lo es)
- ✅ Verifica que el viaje pertenezca al pasajero autenticado
- ✅ Verifica que el viaje esté en estado "completado"
- ✅ Valida que `calificacion` esté entre 1 y 5 (integer)
- ✅ Valida que `comentario` sea opcional pero si existe, tenga máximo 500 caracteres
- ✅ Verifica que el viaje no haya sido calificado previamente
- ✅ Valida que el ID del viaje no esté vacío

---

## 👤 API de Perfil

### 7. PUT /api/usuario/perfil

**Descripción:** Actualizar perfil del usuario autenticado

**Autenticación:** Requerida (Bearer Token)

**Request Body:**

```json
{
  "nombre": "Juan",           // OPCIONAL: string, max 45 caracteres
  "apellido": "Pérez",        // OPCIONAL: string, max 45 caracteres
  "telefono": "1234567890",   // OPCIONAL: string, max 15 caracteres
  "email": "nuevo@email.com", // OPCIONAL: email válido, único en BD
  "password": "nueva123"      // OPCIONAL: string, mínimo 6 caracteres
}
```

**Nota:** Todos los campos son opcionales. Solo se actualizan los campos que se envían.

**Response Success (200):**

```json
{
  "success": true,
  "message": "Perfil actualizado exitosamente",
  "data": {
    "id": "uuid-del-usuario",
    "nombre": "Juan",
    "apellido": "Pérez",
    "email": "nuevo@email.com",
    "id_rol": "00000000-0000-0000-0000-000000000002",
    "telefono": "1234567890",
    "foto": "url-de-la-foto.jpg",
    "tipo": "pasajero"
  }
}
```

**Response Error - Validación (422):**

```json
{
  "success": false,
  "message": "Datos de entrada inválidos",
  "errors": {
    "email": ["El email ya está en uso"],
    "password": ["La contraseña debe tener al menos 6 caracteres"]
  }
}
```

**Response Error - No Autenticado (401):**

```json
{
  "success": false,
  "message": "Usuario no autenticado"
}
```

---

## 📝 Notas Importantes

### Campos Nuevos en Viajes:

- ⭐ **tiempo_limite_aceptacion**: Timestamp en formato ISO 8601. Se establece automáticamente a 5 minutos después de la creación (o el tiempo personalizado si se especifica).

- ⭐ **tarifa**: Decimal con 2 decimales. Se establece cuando el taxista acepta el viaje (opcional).

### Validaciones:

- **tiempo_limite_minutos**: Entre 1 y 30 minutos (al crear viaje)

- **tarifa**: Entre 0 y 9999.99 (al aceptar viaje)

- Los viajes expirados se marcan automáticamente como "cancelado" y no aparecen en viajes disponibles

### Formato de Fechas:

- Todas las fechas se envían en formato ISO 8601: `"2024-01-15T10:30:00Z"`

### Actualización de Perfil:

- Solo se actualizan los campos que se envían en el request

- El email debe ser único (excepto el del mismo usuario)

- La contraseña se hashea automáticamente si se proporciona

---

## 🔄 Cambios Implementados en Flutter

### Modelo ViajeModel

Se agregaron los siguientes campos:
- `tiempoLimiteAceptacion` (DateTime?): Tiempo límite para aceptar el viaje
- `tarifa` (double?): Tarifa del viaje establecida por el taxista

**Parseo del campo `id`:**
- ⭐ **ACTUALIZADO**: El parseo del campo `id` está alineado con la documentación del backend
- El backend SIEMPRE envía el campo `id` como UUID (string) y nunca es null
- El código valida que el ID esté presente y muestra errores claros si falta
- Se filtran automáticamente los viajes sin ID válido antes de mostrarlos en la UI

### Servicio PasajeroService

- `crearViaje()` ahora acepta el parámetro opcional `tiempoLimiteMinutos` (int?, rango 1-30)

### Servicio TaxistaService

- `obtenerViajesDisponibles()` ahora valida que cada viaje tenga un ID válido antes de agregarlo
- Se omiten automáticamente los viajes sin ID válido (aunque el backend no debería enviarlos)
- Logging mejorado para diagnosticar problemas con IDs faltantes

### Validaciones Implementadas

1. **Validación de ID del viaje:**
   - Se verifica que el campo `id` esté presente en cada respuesta del backend
   - Se filtran viajes sin ID válido antes de mostrarlos al usuario
   - Se muestra un mensaje claro si se intenta aceptar un viaje sin ID

2. **Manejo de errores:**
   - Diálogos de error mejorados con información detallada para debugging
   - Información del viaje (ID, estado, tiempo límite) incluida en mensajes de error

### Servicio TaxistaService

- `aceptarViaje()` ahora acepta el parámetro opcional `tarifa` (double?, rango 0-9999.99)
- Manejo mejorado del error 422 para viajes expirados y tarifas inválidas
