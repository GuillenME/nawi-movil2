# ⚡ Solución Rápida: Error "Personal access client not found"

## 🚨 **Este error se debe resolver en el BACKEND, no en la app móvil**

---

## ✅ **Solución Rápida (5 minutos)**

### **Opción A: Si tienes acceso SSH al servidor**

**1. Conéctate a tu servidor:**
```bash
ssh usuario@nawi.click
# O usa tu método de conexión
```

**2. Ve al directorio del proyecto Laravel:**
```bash
cd /ruta/a/tu/proyecto/laravel
# Ejemplo: cd /var/www/nawi o cd /home/usuario/nawi
```

**3. Ejecuta el comando para crear el Personal Access Client:**
```bash
php artisan passport:client --personal
```

**4. Si te pide un nombre, usa:**
```
Nawi Mobile App
```

**5. Verifica que se creó:**
```bash
php artisan tinker
```
Luego en tinker:
```php
\Laravel\Passport\Client::where('personal_access_client', 1)->count();
// Debería retornar al menos 1
exit
```

**6. Limpia la caché:**
```bash
php artisan config:clear
php artisan cache:clear
```

**7. Prueba el login desde la app nuevamente**

---

### **Opción B: Si NO tienes acceso SSH (usar base de datos directamente)**

**1. Conéctate a tu base de datos MySQL/phpMyAdmin**

**2. Verifica primero si ya existe:**
```sql
SELECT * FROM oauth_clients WHERE personal_access_client = 1;
```

**3. Si NO hay resultados, ejecuta esto:**

```sql
-- Primero, verifica qué ID usar (busca el máximo ID existente)
SELECT MAX(id) FROM oauth_clients;

-- Usa el siguiente ID (si el máximo es 5, usa 6)
-- En este ejemplo uso 1, pero cambia si ya existe

INSERT INTO `oauth_clients` (
    `id`,
    `user_id`,
    `name`,
    `secret`,
    `provider`,
    `redirect`,
    `personal_access_client`,
    `password_client`,
    `revoked`,
    `created_at`,
    `updated_at`
) VALUES (
    1,
    NULL,
    'Nawi Personal Access Client',
    NULL,
    NULL,
    'http://localhost',
    1,
    0,
    0,
    NOW(),
    NOW()
);

-- Si el INSERT falla porque el ID 1 ya existe, busca el siguiente ID disponible:
-- SELECT MAX(id) + 1 FROM oauth_clients;
-- Y usa ese ID en lugar de 1
```

**4. Luego inserta en la tabla de personal access clients:**

```sql
-- Verifica si ya existe un registro
SELECT * FROM oauth_personal_access_clients;

-- Si no existe, inserta (usa el mismo ID que pusiste en oauth_clients)
INSERT INTO `oauth_personal_access_clients` (
    `id`,
    `client_id`,
    `created_at`,
    `updated_at`
) VALUES (
    1,
    1,  -- Este debe ser el mismo ID que usaste en oauth_clients
    NOW(),
    NOW()
);
```

**5. Verifica que se creó correctamente:**
```sql
SELECT * FROM oauth_clients WHERE personal_access_client = 1;
SELECT * FROM oauth_personal_access_clients;
```

**Ambos deberían mostrar al menos un registro.**

**6. Prueba el login desde la app nuevamente**

---

## 🔍 **Si el problema persiste**

### **Verifica que Passport esté instalado correctamente:**

**1. En el servidor, verifica los comandos disponibles:**
```bash
php artisan list | grep passport
```

Deberías ver:
- `passport:install`
- `passport:client`
- `passport:keys`

**2. Si NO ves estos comandos, Passport no está instalado:**

```bash
composer require laravel/passport
php artisan migrate
php artisan passport:install
php artisan passport:client --personal
```

**3. Verifica la configuración en `config/auth.php`:**
```php
'guards' => [
    'api' => [
        'driver' => 'passport',  // ← Debe decir 'passport'
        'provider' => 'users',
    ],
],
```

---

## 📞 **¿Qué necesitas saber?**

Para ayudarte mejor, comparte:

1. **¿Tienes acceso SSH al servidor?** (Sí/No)
2. **¿Tienes acceso a la base de datos?** (phpMyAdmin, MySQL Workbench, etc.)
3. **¿Qué método prefieres usar?** (SSH o Base de datos)
4. **¿El servidor es tuyo o de un hosting?** (Hostinger, cPanel, etc.)

---

## 🎯 **Resumen**

**El problema:** Laravel Passport necesita un "Personal Access Client" para generar tokens de autenticación.

**La solución:** Crear ese cliente en el backend usando:
- SSH: `php artisan passport:client --personal`
- O SQL: INSERT en las tablas `oauth_clients` y `oauth_personal_access_clients`

**Una vez creado, el login debería funcionar inmediatamente.**

