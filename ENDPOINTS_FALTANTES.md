# 📋 Endpoints Faltantes - Nawii App

## 🔗 Base URL
```
https://nawi.click/api
```

---

## ✅ **ENDPOINTS IMPLEMENTADOS** (Ya funcionando)

### **Autenticación:**
1. ✅ `POST /login`
2. ✅ `POST /register/pasajero`

---

## 🔴 **ENDPOINTS FALTANTES** (Necesarios para el funcionamiento completo)

### **📱 PARA PASAJEROS**

#### 1. `POST /pasajero/crear-viaje`
**Descripción:** Crear un nuevo viaje (con o sin taxista específico)

**Headers:**
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

**Body:**
```json
{
  "id_pasajero": "uuid-del-pasajero",
  "salida": {
    "lat": 16.867,
    "lon": -92.094
  },
  "destino": {
    "lat": 16.900,
    "lon": -92.100
  },
  "id_taxista": "uuid-del-taxista" // OPCIONAL - Solo si se seleccionó un taxista
}
```

**Response (200/201):**
```json
{
  "success": true,
  "message": "Viaje creado exitosamente",
  "data": {
    "id": "viaje-uuid",
    "id_pasajero": "uuid",
    "id_taxista": "uuid" || null,
    "latitud_origen": 16.867,
    "longitud_origen": -92.094,
    "direccion_origen": "Origen",
    "latitud_destino": 16.900,
    "longitud_destino": -92.100,
    "direccion_destino": "Destino",
    "estado": "solicitado",
    "fecha_creacion": "2024-01-15T10:30:00Z"
  }
}
```

**Notas importantes:**
- Si se envía `id_taxista`, el viaje debe estar dirigido específicamente a ese taxista
- El estado inicial debe ser `"solicitado"`
- Debes guardar también en MySQL para persistencia

---

#### 2. `GET /pasajero/mis-viajes`
**Descripción:** Obtener todos los viajes del pasajero autenticado

**Headers:**
```
Accept: application/json
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "viaje-uuid",
      "pasajero_id": 123,
      "taxista_id": 456,
      "latitud_origen": 16.867,
      "longitud_origen": -92.094,
      "direccion_origen": "Origen",
      "latitud_destino": 16.900,
      "longitud_destino": -92.100,
      "direccion_destino": "Destino",
      "estado": "completado",
      "fecha_creacion": "2024-01-15T10:30:00Z",
      "fecha_aceptacion": "2024-01-15T10:35:00Z",
      "fecha_completado": "2024-01-15T11:00:00Z",
      "calificacion": 5.0,
      "comentario": "Excelente servicio"
    }
  ]
}
```

---

#### 3. `POST /pasajero/cancelar-viaje/{viajeId}`
**Descripción:** Cancelar un viaje solicitado

**Headers:**
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

**URL Parameters:**
- `viajeId`: UUID del viaje

**Response (200):**
```json
{
  "success": true,
  "message": "Viaje cancelado exitosamente"
}
```

**Validaciones:**
- Solo puede cancelar el pasajero que creó el viaje
- Solo se puede cancelar si el estado es `"solicitado"` o `"aceptado"`
- No se puede cancelar si ya está `"en_progreso"`

---

#### 4. `POST /pasajero/calificar-viaje/{viajeId}`
**Descripción:** Calificar un viaje completado

**Headers:**
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

**URL Parameters:**
- `viajeId`: UUID del viaje

**Body:**
```json
{
  "calificacion": 5,
  "comentario": "Excelente servicio, muy puntual" // OPCIONAL
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Viaje calificado exitosamente"
}
```

**Validaciones:**
- Solo se puede calificar si el estado es `"completado"`
- La calificación debe estar entre 1 y 5
- Solo puede calificar el pasajero que realizó el viaje

---

### **🚕 PARA TAXISTAS**

#### 5. `GET /taxista/viajes-disponibles`
**Descripción:** Obtener viajes disponibles para el taxista autenticado

**Headers:**
```
Accept: application/json
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "viaje-uuid",
      "pasajero_id": 123,
      "taxista_id": null, // null si no está asignado
      "latitud_origen": 16.867,
      "longitud_origen": -92.094,
      "direccion_origen": "Origen",
      "latitud_destino": 16.900,
      "longitud_destino": -92.100,
      "direccion_destino": "Destino",
      "estado": "solicitado",
      "fecha_creacion": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Lógica del backend:**
- Debe retornar viajes con estado `"solicitado"`
- Debe filtrar viajes que:
  - Tengan `id_taxista` igual al ID del taxista autenticado (solicitudes dirigidas a él)
  - O viajes sin `id_taxista` (solicitudes generales)
- Ordenar por fecha de creación (más recientes primero)

---

#### 6. `GET /taxista/mis-viajes`
**Descripción:** Obtener todos los viajes del taxista autenticado

**Headers:**
```
Accept: application/json
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "viaje-uuid",
      "pasajero_id": 123,
      "taxista_id": 456,
      "latitud_origen": 16.867,
      "longitud_origen": -92.094,
      "direccion_origen": "Origen",
      "latitud_destino": 16.900,
      "longitud_destino": -92.100,
      "direccion_destino": "Destino",
      "estado": "completado",
      "fecha_creacion": "2024-01-15T10:30:00Z",
      "fecha_aceptacion": "2024-01-15T10:35:00Z",
      "fecha_completado": "2024-01-15T11:00:00Z",
      "calificacion": 5.0,
      "comentario": "Excelente pasajero"
    }
  ]
}
```

**Lógica:**
- Retornar todos los viajes donde `taxista_id` coincide con el taxista autenticado
- Incluir todos los estados: `aceptado`, `en_progreso`, `completado`, `cancelado`

---

#### 7. `POST /taxista/aceptar-viaje/{viajeId}`
**Descripción:** Aceptar un viaje solicitado

**Headers:**
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

**URL Parameters:**
- `viajeId`: UUID del viaje

**Response (200):**
```json
{
  "success": true,
  "message": "Viaje aceptado exitosamente"
}
```

**Validaciones:**
- Solo puede aceptar viajes con estado `"solicitado"`
- El viaje debe estar dirigido a este taxista (`id_taxista` coincide)
- O el viaje no debe tener `id_taxista` asignado (solicitud general)
- Actualizar `taxista_id` con el ID del taxista que acepta
- Cambiar estado a `"aceptado"`
- Actualizar `fecha_aceptacion`

---

#### 8. `POST /taxista/rechazar-viaje/{viajeId}`
**Descripción:** Rechazar un viaje solicitado

**Headers:**
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

**URL Parameters:**
- `viajeId`: UUID del viaje

**Response (200):**
```json
{
  "success": true,
  "message": "Viaje rechazado exitosamente"
}
```

**Validaciones:**
- Solo puede rechazar viajes con estado `"solicitado"`
- El viaje debe estar dirigido a este taxista
- Cambiar estado a `"rechazado"`
- Si el viaje tiene `id_taxista` específico, el pasajero debe ser notificado

---

#### 9. `POST /taxista/completar-viaje/{viajeId}`
**Descripción:** Marcar un viaje como completado

**Headers:**
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

**URL Parameters:**
- `viajeId`: UUID del viaje

**Response (200):**
```json
{
  "success": true,
  "message": "Viaje completado exitosamente"
}
```

**Validaciones:**
- Solo puede completar viajes donde el taxista autenticado es el asignado
- El estado debe ser `"aceptado"` o `"en_progreso"`
- Cambiar estado a `"completado"`
- Actualizar `fecha_completado`

---

### **🌐 PARA EL SISTEMA**

#### 10. `GET /viaje/estado/{viajeId}`
**Descripción:** Obtener el estado actual de un viaje

**Headers:**
```
Accept: application/json
Authorization: Bearer {token}
```

**URL Parameters:**
- `viajeId`: UUID del viaje

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "viaje-uuid",
    "estado": "aceptado",
    "id_pasajero": "uuid",
    "id_taxista": "uuid",
    "salida": {
      "lat": 16.867,
      "lon": -92.094
    },
    "destino": {
      "lat": 16.900,
      "lon": -92.100
    },
    "timestamp": 1703123456789
  }
}
```

---

#### 11. `POST /viaje/actualizar-ubicacion/{viajeId}`
**Descripción:** Actualizar la ubicación del taxista durante un viaje

**Headers:**
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

**URL Parameters:**
- `viajeId`: UUID del viaje

**Body:**
```json
{
  "lat": 16.880,
  "lon": -92.095
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Ubicación actualizada exitosamente"
}
```

**Validaciones:**
- Solo el taxista asignado puede actualizar la ubicación
- El viaje debe estar en estado `"aceptado"` o `"en_progreso"`
- Se actualiza en Firebase también para tiempo real

---

## 📝 **NOTAS IMPORTANTES**

### **Estructura de Estados:**
```
solicitado → aceptado → en_progreso → completado
              ↓
          cancelado / rechazado
```

### **IDs:**
- Los IDs pueden ser UUIDs (strings) o enteros, según tu base de datos
- Asegúrate de que coincidan entre MySQL y Firebase

### **Firebase Integration:**
- Los viajes también se guardan en Firebase para actualizaciones en tiempo real
- La estructura de Firebase debe coincidir con la estructura mostrada arriba

### **Autenticación:**
- Todos los endpoints (excepto login y registro) requieren el header `Authorization: Bearer {token}`
- El token se obtiene del endpoint `/login`

### **Errores Comunes:**
- **401 Unauthorized**: Token inválido o expirado
- **403 Forbidden**: El usuario no tiene permisos para esta acción
- **404 Not Found**: El recurso no existe
- **422 Unprocessable Entity**: Validación fallida

### **Estructura de Respuesta de Error:**
```json
{
  "success": false,
  "message": "Mensaje de error descriptivo"
}
```

---

## ✅ **CHECKLIST DE IMPLEMENTACIÓN**

### **Prioridad Alta (Flujo Principal):**
- [ ] `POST /pasajero/crear-viaje` - **CRÍTICO**
- [ ] `POST /taxista/aceptar-viaje/{id}` - **CRÍTICO**
- [ ] `POST /taxista/rechazar-viaje/{id}` - **CRÍTICO**

### **Prioridad Media:**
- [ ] `GET /pasajero/mis-viajes`
- [ ] `POST /pasajero/cancelar-viaje/{id}`
- [ ] `GET /taxista/viajes-disponibles`
- [ ] `POST /taxista/completar-viaje/{id}`

### **Prioridad Baja:**
- [ ] `POST /pasajero/calificar-viaje/{id}`
- [ ] `GET /taxista/mis-viajes`
- [ ] `GET /viaje/estado/{id}`
- [ ] `POST /viaje/actualizar-ubicacion/{id}`

---

## 🔗 **Relación con Firebase**

Todos los endpoints que modifican el estado de un viaje deben:
1. Actualizar MySQL (persistencia)
2. Actualizar Firebase (tiempo real)
3. Retornar respuesta JSON

El flujo completo usa **MySQL como fuente de verdad** y **Firebase para sincronización en tiempo real**.

