# 🔥 Configuración de Reglas de Firebase Realtime Database

## ⚠️ **PROBLEMA ACTUAL**

Tu app está fallando con este error:
```
Listen at /taxis failed: DatabaseError: Permission denied
```

Esto significa que las reglas de seguridad de Firebase están bloqueando el acceso.

---

## ✅ **SOLUCIÓN: Configurar Reglas de Firebase**

### **1. Ve a Firebase Console:**
- https://console.firebase.google.com/
- Selecciona tu proyecto
- Ve a **Realtime Database** → **Rules**

### **2. Configura estas Reglas:**

#### **Opción A: Desarrollo (Permisivo - Solo para desarrollo)**
```json
{
  "rules": {
    "taxis": {
      ".read": true,
      ".write": true
    },
    "viajes": {
      ".read": true,
      ".write": true
    }
  }
}
```

#### **Opción B: Producción (Seguro - Requiere autenticación)**
```json
{
  "rules": {
    "taxis": {
      "$taxistaId": {
        ".read": true,
        ".write": "auth != null && auth.uid == $taxistaId"
      },
      ".read": true,
      ".write": "auth != null"
    },
    "viajes": {
      "$viajeId": {
        ".read": "auth != null && (data.child('id_pasajero').val() == auth.uid || data.child('id_taxista').val() == auth.uid)",
        ".write": "auth != null && (data.child('id_pasajero').val() == auth.uid || data.child('id_taxista').val() == auth.uid)"
      },
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

#### **Opción C: Híbrido (Recomendado para comenzar)**
```json
{
  "rules": {
    "taxis": {
      ".read": true,
      ".write": true,
      "$taxistaId": {
        ".read": true,
        ".write": true
      }
    },
    "viajes": {
      ".read": true,
      ".write": true,
      "$viajeId": {
        ".read": true,
        ".write": true,
        "ubicacion_taxista": {
          ".read": true,
          ".write": true
        }
      }
    }
  }
}
```

### **3. Publicar las Reglas:**
- Click en **"Publish"**
- Las reglas se aplicarán inmediatamente

---

## 📝 **Estructura de Datos en Firebase**

Tu Firebase debe tener esta estructura:

```json
{
  "taxis": {
    "taxista-123": {
      "latitude": 16.867,
      "longitude": -92.094,
      "timestamp": 1703123456789,
      "disponible": true
    }
  },
  "viajes": {
    "viaje-456": {
      "id_pasajero": "pasajero-123",
      "id_taxista": "taxista-456",
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
      "activo": true,
      "ubicacion_taxista": {
        "lat": 16.880,
        "lon": -92.095,
        "timestamp": 1703123500000
      }
    }
  }
}
```

---

## 🔐 **Seguridad**

**⚠️ IMPORTANTE:**

1. **Para desarrollo**: Usa la Opción A o C (más permisivo)
2. **Para producción**: Usa la Opción B (requiere autenticación)

3. **Autenticación en Firebase:**
   - Si usas la Opción B, necesitas implementar autenticación de Firebase
   - O usa autenticación personalizada y sincroniza usuarios

---

## 🧪 **Verificar que Funciona**

Después de configurar las reglas:

1. Ejecuta la app: `flutter run`
2. Verifica que no aparezca el error de "Permission denied"
3. Verifica que puedas ver taxis en el mapa
4. Verifica que puedas crear viajes

---

## 📚 **Referencias**

- Firebase Realtime Database Rules: https://firebase.google.com/docs/database/security
- Firebase Authentication: https://firebase.google.com/docs/auth

