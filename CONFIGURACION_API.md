# Configuración de API para Nawi

## 🔗 URLs de API Configuradas

Todas las URLs de API han sido configuradas para usar tu servidor:

```
Base URL: https://nawi-2.me/api
```

## 📋 Endpoints Implementados

### ✅ Autenticación
- **POST** `/login` - Iniciar sesión
- **POST** `/register/pasajero` - Registro de pasajero

### 🔄 Endpoints Pendientes (Para implementar en tu backend)

#### Para Taxistas:
- **GET** `/taxista/viajes-pendientes` - Obtener viajes pendientes
- **POST** `/taxista/aceptar-viaje` - Aceptar viaje
- **POST** `/taxista/rechazar-viaje` - Rechazar viaje
- **POST** `/taxista/completar-viaje` - Completar viaje

#### Para Pasajeros:
- **POST** `/pasajero/solicitar-viaje` - Solicitar viaje
- **GET** `/pasajero/viajes` - Obtener viajes del pasajero
- **POST** `/pasajero/cancelar-viaje` - Cancelar viaje
- **POST** `/pasajero/calificar-viaje` - Calificar viaje

## 📱 Estructura de Datos Actualizada

### Modelo de Usuario
```dart
class UserModel {
  final String id;           // UUID
  final String nombre;       // Nombre
  final String apellido;     // Apellido
  final String email;        // Email
  final String rolId;        // ID del rol
  final String? telefono;    // Teléfono
  final String? token;       // Token de acceso
  final String? tipo;        // 'pasajero' o 'taxista'
}
```

### Respuesta de Login
```json
{
  "success": true,
  "message": "Login exitoso",
  "data": {
    "usuario": {
      "id": "uuid",
      "nombre": "Juan",
      "apellido": "Pérez",
      "email": "juan@email.com",
      "id_rol": "2",
      "telefono": "1234567890"
    },
    "tipo": "pasajero",
    "access_token": "token_aqui",
    "token_type": "Bearer"
  }
}
```

### Respuesta de Registro
```json
{
  "success": true,
  "message": "Pasajero registrado exitosamente",
  "data": {
    "usuario": {
      "id": "uuid",
      "nombre": "Juan",
      "apellido": "Pérez",
      "email": "juan@email.com",
      "id_rol": "2",
      "telefono": "1234567890"
    },
    "tipo": "pasajero"
  }
}
```

## 🔧 Configuración de Headers

Todos los requests incluyen:
```dart
headers: {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Authorization': 'Bearer $token', // Para requests autenticados
}
```

## 📝 Campos de Registro Actualizados

### Formulario de Registro:
- ✅ **Nombre** (requerido)
- ✅ **Apellido** (requerido)
- ✅ **Email** (requerido)
- ✅ **Teléfono** (requerido)
- ✅ **Contraseña** (requerido)
- ✅ **Confirmar Contraseña** (requerido)

### Validaciones:
- Email único en la base de datos
- Contraseña mínimo 6 caracteres
- Teléfono máximo 15 caracteres
- Nombre y apellido máximo 45 caracteres

## 🚀 Próximos Pasos

1. **Implementar endpoints faltantes** en tu backend Laravel
2. **Configurar Google Maps API Key** en `android/app/src/main/AndroidManifest.xml`
3. **Probar la aplicación** con los endpoints existentes
4. **Implementar funcionalidades adicionales** según sea necesario

## 🧪 Testing

Para probar la aplicación:

1. **Registro de Pasajero:**
   - Llenar formulario completo
   - Verificar que se crea el usuario con rol 2
   - Verificar que se crea registro en tabla pasajeros

2. **Login:**
   - Usar credenciales del usuario registrado
   - Verificar que se obtiene el token
   - Verificar que se determina el tipo de usuario

3. **Navegación:**
   - Verificar que se muestra la pantalla correcta según el tipo de usuario
   - Verificar que se mantiene la sesión

## 🔍 Debugging

Si hay errores, revisar:

1. **URLs de API** - Verificar que apunten a tu servidor
2. **Headers** - Verificar que incluyan Content-Type y Accept
3. **Tokens** - Verificar que se envíen en requests autenticados
4. **Estructura de datos** - Verificar que coincida con tu API

## 📞 Soporte

Si necesitas ayuda con la implementación de endpoints adicionales, puedo ayudarte a:
- Definir la estructura de datos
- Implementar la lógica de negocio
- Configurar las rutas en Laravel
- Probar la integración

