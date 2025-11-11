/// Utilidades de validación mejoradas
class Validators {
  // Expresión regular para validar email
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Expresión regular para validar teléfono mexicano
  static final RegExp _phoneRegex = RegExp(
    r'^(\+52)?[1-9]\d{9}$',
  );

  /// Valida un email con expresión regular
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }
    
    // Limpiar espacios
    final email = value.trim();
    
    if (!_emailRegex.hasMatch(email)) {
      return 'Por favor ingresa un correo electrónico válido';
    }
    
    return null;
  }

  /// Valida una contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    
    if (value.length > 50) {
      return 'La contraseña no puede tener más de 50 caracteres';
    }
    
    return null;
  }

  /// Valida confirmación de contraseña
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    
    return null;
  }

  /// Valida un teléfono mexicano
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu teléfono';
    }
    
    // Limpiar espacios y caracteres especiales
    final phone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (phone.length < 10 || phone.length > 13) {
      return 'El teléfono debe tener entre 10 y 13 dígitos';
    }
    
    if (!_phoneRegex.hasMatch(phone)) {
      return 'Por favor ingresa un teléfono válido';
    }
    
    return null;
  }

  /// Valida un campo requerido
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Por favor ingresa $fieldName';
    }
    
    // Sanitizar: quitar caracteres peligrosos
    final sanitized = value.trim();
    if (sanitized.length != value.length) {
      return 'El campo contiene espacios inválidos';
    }
    
    return null;
  }

  /// Sanitiza un string removiendo caracteres peligrosos
  static String sanitize(String input) {
    // Remover caracteres de control y caracteres especiales peligrosos
    return input
        .trim()
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // Caracteres de control
        .replaceAll(RegExp(r'[<>]'), ''); // Posibles tags HTML
  }

  /// Valida un token de recuperación
  static String? validateToken(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa el código de recuperación';
    }
    
    if (value.length < 6) {
      return 'El código debe tener al menos 6 caracteres';
    }
    
    return null;
  }

  /// Valida una ubicación/dirección
  /// Solo permite letras, números, espacios, comas, puntos, guiones y caracteres comunes de direcciones
  /// Rechaza caracteres peligrosos como <, >, /, etc.
  static String? validateLocation(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Por favor ingresa una ubicación';
    }
    
    // Expresión regular que permite letras, números, espacios, comas, puntos, guiones, 
    // números, acentos y caracteres comunes de direcciones
    // Rechaza caracteres peligrosos como <, >, /, \, etc.
    final locationRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s,.\-°#]+$');
    
    // Verificar que no contenga caracteres peligrosos
    if (value.contains('<') || value.contains('>') || value.contains('/') || 
        value.contains('\\') || value.contains('&') || value.contains('"') || 
        value.contains("'") || value.contains(';')) {
      return 'La ubicación no puede contener caracteres especiales como <, >, /, etc.';
    }
    
    // Verificar que coincida con el patrón
    if (!locationRegex.hasMatch(value.trim())) {
      return 'La ubicación solo puede contener letras, números y caracteres comunes de direcciones';
    }
    
    // Verificar longitud mínima
    if (value.trim().length < 3) {
      return 'La ubicación debe tener al menos 3 caracteres';
    }
    
    return null;
  }
}

