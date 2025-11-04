# 📋 Sprint Backlog - Nawii App

## 🎯 **Resumen del Sprint**

Este backlog incluye todas las funcionalidades implementadas y pendientes para la aplicación de transporte (ride-hailing).

---

## ✅ **COMPLETADO - Funcionalidades Implementadas**

### **1. Autenticación y Registro**
- [x] **Login de usuarios** (pasajeros y taxistas)
  - Manejo de tokens con Laravel Passport
  - Detección automática de tipo de usuario (taxista/pasajero)
  - Guardado de sesión en SharedPreferences
  - Validación de credenciales
  - Manejo de errores (500, 401, etc.)

- [x] **Registro de pasajeros**
  - Formulario de registro
  - Validación de datos
  - Integración con backend

### **2. Integración de Google Maps**
- [x] **Configuración de Google Maps SDK**
  - API Key configurada en Android (`AndroidManifest.xml`)
  - API Key configurada en iOS (`AppDelegate.swift`)
  - Dependencias configuradas (`google_maps_flutter`)

- [x] **Servicios de ubicación**
  - Implementación con plugin `location`
  - Permisos de ubicación
  - Ubicación en tiempo real
  - Coordenadas predeterminadas (Ocosingo) como fallback

- [x] **Geocoding (Conversión de direcciones)**
  - API de Google Geocoding integrada
  - Conversión de dirección → coordenadas
  - Conversión de coordenadas → dirección
  - Sistema de scoring para resultados precisos
  - Fallback específico para UTS (coordenadas exactas)

### **3. Solicitud de Viajes (Pasajero)**
- [x] **Página de solicitud con mapa**
  - Mapa interactivo con Google Maps
  - Visualización de ubicación actual
  - Búsqueda y selección de destino
  - Visualización de taxistas disponibles en tiempo real
  - Selección de taxista específico
  - Confirmación de origen y destino

- [x] **Servicio de creación de viajes**
  - Endpoint `/api/pasajero/crear-viaje`
  - Envío de coordenadas de origen y destino
  - Selección opcional de taxista específico
  - Manejo de tokens de autenticación
  - Validación de datos
  - Manejo de errores (401, 422, 500)

- [x] **Integración con Firebase Realtime Database**
  - Sincronización de viajes en tiempo real
  - Escucha de cambios de estado
  - Actualización de ubicaciones

### **4. Visualización de Viaje en Curso**
- [x] **Página de viaje en curso**
  - Mapa con ruta del viaje
  - Seguimiento en tiempo real del taxista
  - Actualización de ubicación del taxista
  - Estados del viaje (solicitado, aceptado, en_progreso, completado)
  - Cancelación de viaje

### **5. Vista de Taxistas**
- [x] **Home de taxista**
  - Interfaz específica para taxistas
  - Navegación a diferentes funciones

- [x] **Viajes pendientes**
  - Visualización de solicitudes en tiempo real
  - Filtrado por taxista específico
  - Estados de viaje (solicitado, aceptado, etc.)

### **6. Manejo de Errores y Validaciones**
- [x] **Manejo de errores de autenticación**
  - Error 401 (Sesión expirada)
  - Error 500 (Error interno)
  - Error 422 (Validación)
  - Mensajes de error claros

- [x] **Validación de IDs**
  - Detección de IDs placeholder
  - Validación de IDs de usuario y taxista
  - Mensajes de error descriptivos

### **7. Configuración de Build**
- [x] **Configuración Android**
  - `AndroidManifest.xml` con API Key
  - Permisos de ubicación
  - SDK version 35

- [x] **Configuración iOS**
  - `AppDelegate.swift` con API Key
  - Configuración de Google Maps

---

## 🔄 **EN PROGRESO - Funcionalidades Parcialmente Implementadas**

### **1. Aceptación/Rechazo de Viajes (Taxista)**
- [x] Visualización de viajes pendientes
- [ ] Aceptar viaje (backend implementado, UI pendiente de verificación)
- [ ] Rechazar viaje (backend implementado, UI pendiente de verificación)
- [ ] Actualización de estado en tiempo real

### **2. Calificación de Viajes**
- [ ] Página de calificación
- [ ] Envío de calificación al backend
- [ ] Visualización de calificaciones

---

## 📝 **PENDIENTE - Funcionalidades por Implementar**

### **1. Funcionalidades de Pasajero**

#### **1.1. Historial de Viajes**
- [ ] Lista de viajes anteriores
- [ ] Filtros (completados, cancelados, etc.)
- [ ] Detalles de cada viaje
- [ ] Integración con endpoint `/api/pasajero/mis-viajes`

#### **1.2. Cancelación de Viaje**
- [ ] Botón de cancelación en viaje solicitado
- [ ] Confirmación de cancelación
- [ ] Integración con endpoint `/api/pasajero/cancelar-viaje/{viajeId}`
- [ ] Notificación al taxista

#### **1.3. Calificación y Comentarios**
- [ ] Página de calificación después de completar viaje
- [ ] Sistema de estrellas (1-5)
- [ ] Campo de comentarios opcional
- [ ] Integración con endpoint `/api/pasajero/calificar-viaje/{viajeId}`

### **2. Funcionalidades de Taxista**

#### **2.1. Gestión de Disponibilidad**
- [ ] Toggle de disponibilidad (disponible/no disponible)
- [ ] Actualización de estado en Firebase
- [ ] Indicador visual de disponibilidad

#### **2.2. Aceptación/Rechazo de Viajes**
- [ ] Botón de aceptar en viajes pendientes
- [ ] Botón de rechazar en viajes pendientes
- [ ] Confirmación de acciones
- [ ] Integración con endpoints:
  - `POST /api/taxista/aceptar-viaje/{viajeId}`
  - `POST /api/taxista/rechazar-viaje/{viajeId}`

#### **2.3. Actualización de Ubicación en Tiempo Real**
- [ ] Actualización automática de ubicación mientras está disponible
- [ ] Envío de ubicación durante viaje en curso
- [ ] Integración con endpoint `/api/viaje/actualizar-ubicacion/{viajeId}`

#### **2.4. Completar Viaje**
- [ ] Botón de completar viaje
- [ ] Confirmación de finalización
- [ ] Integración con endpoint `/api/taxista/completar-viaje/{viajeId}`
- [ ] Transición a pantalla de calificación

#### **2.5. Historial de Viajes del Taxista**
- [ ] Lista de viajes realizados
- [ ] Filtros y estadísticas
- [ ] Integración con endpoint `/api/taxista/mis-viajes`

### **3. Funcionalidades del Sistema**

#### **3.1. Notificaciones Push**
- [ ] Configuración de Firebase Cloud Messaging (FCM)
- [ ] Notificaciones cuando hay nueva solicitud (taxista)
- [ ] Notificaciones cuando el viaje es aceptado (pasajero)
- [ ] Notificaciones de actualización de estado

#### **3.2. Rutas y Navegación**
- [ ] Cálculo de ruta entre origen y destino
- [ ] Visualización de ruta en el mapa
- [ ] Integración con Google Directions API
- [ ] Polilíneas en el mapa

#### **3.3. Estimación de Tiempo y Distancia**
- [ ] Cálculo de distancia entre puntos
- [ ] Estimación de tiempo de llegada
- [ ] Estimación de costo (si aplica)
- [ ] Visualización en UI

#### **3.4. Perfil de Usuario**
- [ ] Edición de perfil
- [ ] Cambio de foto
- [ ] Actualización de información
- [ ] Integración con endpoint `/api/user`

#### **3.5. Documentos del Taxista**
- [ ] Subida de matrícula
- [ ] Subida de licencia
- [ ] Visualización de documentos
- [ ] Integración con endpoints:
  - `POST /api/taxista/upload-matricula`
  - `POST /api/taxista/upload-licencia`
  - `GET /api/taxista/documents`

### **4. Mejoras de UX/UI**

#### **4.1. Estados de Carga**
- [ ] Indicadores de carga consistentes
- [ ] Skeleton screens
- [ ] Animaciones de transición

#### **4.2. Manejo de Errores Mejorado**
- [ ] Mensajes de error más descriptivos
- [ ] Opciones de reintento
- [ ] Manejo de errores de conexión

#### **4.3. Optimización de Mapas**
- [ ] Caché de mapas
- [ ] Optimización de marcadores
- [ ] Mejora de rendimiento en mapas grandes

#### **4.4. Búsqueda Inteligente de Direcciones**
- [ ] Autocompletado de direcciones
- [ ] Historial de direcciones frecuentes
- [ ] Sugerencias basadas en ubicación

### **5. Testing y Calidad**

#### **5.1. Testing Unitario**
- [ ] Tests para servicios
- [ ] Tests para modelos
- [ ] Tests para validaciones

#### **5.2. Testing de Integración**
- [ ] Tests de flujo completo de viaje
- [ ] Tests de autenticación
- [ ] Tests de integración con Firebase

#### **5.3. Testing E2E**
- [ ] Flujo completo pasajero
- [ ] Flujo completo taxista
- [ ] Escenarios de error

### **6. Documentación**

#### **6.1. Documentación Técnica**
- [ ] Documentación de arquitectura
- [ ] Documentación de servicios
- [ ] Guías de integración

#### **6.2. Documentación de Usuario**
- [ ] Guía de uso para pasajeros
- [ ] Guía de uso para taxistas
- [ ] FAQ

---

## 🔒 **SEGURIDAD - Requisitos de Seguridad**

### **✅ Implementado (70%)**
- [x] HTTPS para todas las comunicaciones
- [x] Autenticación con tokens JWT (Laravel Passport)
- [x] Validación básica de formularios
- [x] Manejo de sesiones con persistencia
- [x] Registro de usuarios
- [x] Integración segura con Web Services (HTTPS)

### **❌ Falta Implementar (CRÍTICO)**
- [ ] **Recuperación de contraseñas** - Prioridad ALTA
  - Página "Olvidé mi contraseña"
  - Endpoint `/api/password/forgot`
  - Endpoint `/api/password/reset`
  - Envío de email con token de recuperación

### **⚠️ Mejorable (Media Prioridad)**
- [ ] Encriptación local de datos sensibles (`flutter_secure_storage`)
- [ ] Validación explícita de certificados SSL
- [ ] Sanitización avanzada de entrada
- [ ] Renovación automática de tokens
- [ ] Validación de email más robusta (regex)

**Ver documento completo:** `ANALISIS_SEGURIDAD.md`

---

## 🐛 **BUGS CONOCIDOS - Por Resolver**

### **1. Autenticación**
- [ ] Error "Sesión expirada" después de iniciar sesión (en diagnóstico)
  - Posible causa: Token no se guarda correctamente
  - Posible causa: Backend no valida token correctamente
  - Estado: En investigación

### **2. Geocoding**
- [x] Búsqueda de UTS redirige al centro (RESUELTO con coordenadas exactas)
- [ ] Otras direcciones pueden tener problemas de precisión

### **3. IDs de Usuario**
- [ ] IDs placeholder pueden causar problemas
  - Solución: Backend debe retornar IDs reales
  - Estado: Documentado en `SOLUCION_IDS_PLACEHOLDER.md`

### **4. Firebase**
- [ ] Permisos de Firebase pueden necesitar ajustes
  - Documentado en `FIREBASE_RULES.md`

---

## 📊 **Priorización (Método MoSCoW)**

### **MUST HAVE (Crítico para MVP)**
1. ✅ Autenticación y registro
2. ✅ Solicitud de viaje con mapa
3. ✅ Visualización de taxistas disponibles
4. ✅ Selección de taxista
5. ✅ Creación de viaje
6. 🔄 Aceptación/rechazo de viaje (taxista)
7. 🔄 Actualización de ubicación en tiempo real
8. 🔄 Completar viaje
9. 📝 Cancelación de viaje (pasajero)
10. 📝 Calificación de viaje

### **SHOULD HAVE (Importante pero no crítico)**
1. 📝 Historial de viajes
2. 📝 Notificaciones push
3. 📝 Rutas y navegación
4. 📝 Estimación de tiempo y distancia
5. 📝 Perfil de usuario

### **COULD HAVE (Mejoras deseables)**
1. 📝 Autocompletado de direcciones
2. 📝 Historial de direcciones frecuentes
3. 📝 Documentos del taxista
4. 📝 Estadísticas de viajes
5. 📝 Optimización de mapas

### **WON'T HAVE (Fuera del alcance actual)**
1. Pagos integrados
2. Chat entre pasajero y taxista
3. Múltiples paradas
4. Compartir viaje
5. Sistema de cupones/descuentos

---

## 🎯 **Sprint Actual - Objetivos**

### **Objetivo Principal:**
Completar el flujo básico de solicitud y aceptación de viajes

### **Tareas del Sprint:**

#### **Semana 1:**
- [x] Integración de Google Maps
- [x] Solicitud de viaje con mapa
- [x] Selección de taxista
- [x] Creación de viaje

#### **Semana 2:**
- [ ] Resolver error de autenticación (401)
- [ ] Aceptación de viaje (taxista)
- [ ] Actualización de ubicación en tiempo real
- [ ] Visualización de viaje en curso

#### **Semana 3:**
- [ ] Completar viaje
- [ ] Cancelación de viaje
- [ ] Calificación de viaje
- [ ] Testing y corrección de bugs

---

## 📈 **Métricas de Progreso**

### **Completado:**
- ✅ **60%** - Funcionalidades core implementadas
- ✅ **100%** - Integración de mapas
- ✅ **80%** - Autenticación
- ✅ **70%** - Solicitud de viajes

### **En Progreso:**
- 🔄 **50%** - Gestión de viajes (taxista)
- 🔄 **30%** - Tiempo real

### **Pendiente:**
- 📝 **0%** - Notificaciones
- 📝 **0%** - Historial
- 📝 **0%** - Perfil de usuario

---

## 🔗 **Referencias**

- `ENDPOINTS_FALTANTES.md` - Lista de endpoints del backend
- `VERIFICACION_ENDPOINTS.md` - Verificación de endpoints
- `SOLUCION_ERROR_IDS_INVALIDOS.md` - Solución de errores de IDs
- `SOLUCION_IDS_PLACEHOLDER.md` - Manejo de IDs placeholder
- `SOLUCION_FINAL_ERROR_401.md` - Solución de error 401
- `FIREBASE_RULES.md` - Reglas de Firebase
- `GENERAR_APK.md` - Guía de generación de APK

---

## 📅 **Próximos Pasos Recomendados**

1. **Resolver error 401** - Prioridad alta
2. **Completar flujo de aceptación de viaje** - Prioridad alta
3. **Implementar actualización de ubicación en tiempo real** - Prioridad alta
4. **Testing de flujo completo** - Prioridad media
5. **Implementar calificación** - Prioridad media
6. **Notificaciones push** - Prioridad baja

---

**Última actualización:** $(date)
**Sprint:** Sprint 1 - Flujo Básico de Viajes

