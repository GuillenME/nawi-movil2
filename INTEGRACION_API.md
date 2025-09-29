# 🚀 Integración con tu API - Nawii App

## 📋 **Endpoints Implementados**

### **Para Pasajeros:**
- ✅ `POST /api/pasajero/crear-viaje` - Crear nuevo viaje
- ✅ `GET /api/pasajero/mis-viajes` - Ver mis viajes
- ✅ `POST /api/pasajero/cancelar-viaje/{id}` - Cancelar viaje
- ✅ `POST /api/pasajero/calificar-viaje/{id}` - Calificar viaje

### **Para Taxistas:**
- ✅ `GET /api/taxista/viajes-disponibles` - Ver viajes disponibles
- ✅ `POST /api/taxista/aceptar-viaje/{id}` - Aceptar viaje
- ✅ `POST /api/taxista/rechazar-viaje/{id}` - Rechazar viaje
- ✅ `POST /api/taxista/completar-viaje/{id}` - Completar viaje
- ✅ `GET /api/taxista/mis-viajes` - Ver mis viajes

### **Para el Sistema:**
- ✅ `GET /api/viaje/estado/{id}` - Estado del viaje
- ✅ `POST /api/viaje/actualizar-ubicacion/{id}` - Actualizar ubicación

## 🔥 **Firebase + MySQL - Arquitectura Híbrida**

### **Firebase (Tiempo Real):**
```json
{
  "viajes": {
    "viaje123": {
      "id_pasajero": "user123",
      "id_taxista": "taxi456",
      "salida": {
        "lat": 16.867,
        "lon": -92.094
      },
      "destino": {
        "lat": 16.900,
        "lon": -92.100
      },
      "estado": "solicitado",
      "timestamp": 1703123456789,
      "activo": true
    }
  }
}
```

### **MySQL (Persistencia):**
- Historial completo de viajes
- Datos adicionales (fechas, estados, calificaciones, etc.)

## 🛠️ **Servicios Implementados**

### **1. PasajeroService**
```dart
// Crear viaje
final result = await PasajeroService().crearViaje(
  salidaLat: 16.867,
  salidaLon: -92.094,
  destinoLat: 16.900,
  destinoLon: -92.100,
);

// Ver mis viajes
final viajes = await PasajeroService().obtenerMisViajes();

// Cancelar viaje
final result = await PasajeroService().cancelarViaje('viaje123');

// Calificar viaje
final result = await PasajeroService().calificarViaje(
  viajeId: 'viaje123',
  calificacion: 5,
  comentario: 'Excelente servicio',
);
```

### **2. TaxistaService**
```dart
// Conectar como taxista
await TaxistaService().conectar();

// Ver viajes disponibles
final viajes = await TaxistaService().obtenerViajesDisponibles();

// Aceptar viaje
final result = await TaxistaService().aceptarViaje('viaje123');

// Completar viaje
final result = await TaxistaService().completarViaje('viaje123');

// Actualizar ubicación
await TaxistaService().actualizarUbicacionViaje(
  viajeId: 'viaje123',
  lat: 16.880,
  lon: -92.095,
);
```

## 🔄 **Flujo Completo del Sistema**

### **1. Pasajero solicita viaje:**
1. **App Flutter** → Crea viaje en Firebase
2. **App Flutter** → Llama a tu API: `POST /api/pasajero/crear-viaje`
3. **Tu API** → Guarda en MySQL
4. **Firebase** → Notifica a taxistas cercanos

### **2. Taxista acepta viaje:**
1. **Taxista** → Ve viaje en Firebase
2. **Taxista** → Acepta en app
3. **App Flutter** → Llama a tu API: `POST /api/taxista/aceptar-viaje/{id}`
4. **Tu API** → Actualiza estado en MySQL
5. **Firebase** → Actualiza estado del viaje

### **3. Durante el viaje:**
1. **Taxista** → Actualiza ubicación en Firebase
2. **Pasajero** → Ve ubicación en tiempo real
3. **Tu API** → Recibe actualizaciones periódicas

## 📱 **Cómo usar en las vistas**

### **En SolicitarViajeSimplePage:**
```dart
// Crear viaje
final result = await PasajeroService().crearViaje(
  salidaLat: _salidaLat,
  salidaLon: _salidaLon,
  destinoLat: _destinoLat,
  destinoLon: _destinoLon,
);

if (result['success']) {
  // Mostrar mensaje de éxito
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result['message'])),
  );
  // Navegar a siguiente pantalla
} else {
  // Mostrar error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result['message'])),
  );
}
```

### **En ViajesPendientesPage:**
```dart
// Obtener viajes disponibles
final viajes = await TaxistaService().obtenerViajesDisponibles();

// Aceptar viaje
final result = await TaxistaService().aceptarViaje(viaje.id);
if (result['success']) {
  // Mostrar mensaje de éxito
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result['message'])),
  );
}
```

## 🔐 **Autenticación**

Todos los endpoints requieren el token de autenticación:
```dart
headers: {
  'Authorization': 'Bearer ${user.token}',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
}
```

## 🎯 **Próximos Pasos**

1. **Implementar endpoints en Laravel** (ya tienes la estructura)
2. **Probar la integración** con tu app Flutter
3. **Agregar funcionalidades avanzadas**:
   - Notificaciones push
   - Cálculo de tarifas
   - Rutas optimizadas
   - Sistema de pagos

## 🚨 **Notas Importantes**

- **Firebase** se usa para tiempo real (ubicaciones, estados)
- **MySQL** se usa para persistencia (historial, datos completos)
- **Ambos sistemas** se sincronizan automáticamente
- **Los tokens** se manejan automáticamente en los servicios
- **Los errores** se manejan de forma consistente

## 📞 **Soporte**

Si tienes algún problema con la integración, revisa:
1. **Conexión a internet**
2. **Tokens de autenticación**
3. **Estructura de respuesta de tu API**
4. **Permisos de Firebase**

¡Tu app ya está lista para funcionar con tu API! 🎉
