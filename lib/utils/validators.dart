/// Utilidades de validación mejoradas
class Validators {
  // Expresión regular para validar email
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Expresión regular para validar teléfono (solo números, exactamente 10 dígitos)
  static final RegExp _phoneRegex = RegExp(
    r'^\d{10}$',
  );

  // Expresión regular para validar nombre/apellidos (solo letras, espacios y acentos)
  static final RegExp _nameRegex = RegExp(
    r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$',
  );

  /// Valida un email con expresión regular
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }
    
    // Limpiar espacios
    final email = value.trim();
    
    // Verificar códigos maliciosos
    if (_containsMaliciousCode(email)) {
      return 'El correo electrónico no puede contener caracteres o códigos maliciosos';
    }
    
    if (!_emailRegex.hasMatch(email)) {
      return 'Por favor ingresa un correo electrónico válido';
    }
    
    return null;
  }

  /// Valida una contraseña
  /// Debe contener: mayúsculas, minúsculas, números y caracteres especiales
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    
    // Verificar códigos maliciosos (permitir caracteres especiales seguros para contraseñas)
    final lowerValue = value.toLowerCase();
    final maliciousPatterns = [
      'script',
      'javascript:',
      'onerror=',
      'onclick=',
      'onload=',
      'onmouseover=',
      'eval(',
      'expression(',
      'vbscript:',
      'data:text/html',
      '<iframe',
      '<object',
      '<embed',
      '<?php',
      '<%',
    ];
    
    for (var pattern in maliciousPatterns) {
      if (lowerValue.contains(pattern)) {
        return 'La contraseña no puede contener códigos maliciosos';
      }
    }
    
    // Verificar que no empiece con caracteres peligrosos
    if (value.trim().startsWith('<') || value.trim().startsWith('>')) {
      return 'La contraseña no puede empezar con caracteres peligrosos';
    }
    
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    
    if (value.length > 50) {
      return 'La contraseña no puede tener más de 50 caracteres';
    }

    // Verificar que contenga al menos una mayúscula
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe contener al menos una mayúscula';
    }

    // Verificar que contenga al menos una minúscula
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'La contraseña debe contener al menos una minúscula';
    }

    // Verificar que contenga al menos un número
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe contener al menos un número';
    }

    // Verificar que contenga al menos un carácter especial
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'La contraseña debe contener al menos un carácter especial (!@#\$%^&*(),.?":{}|<>)';
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

  /// Valida un teléfono (solo números, exactamente 10 dígitos)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu teléfono';
    }
    
    // Limpiar espacios y caracteres especiales, dejar solo números
    final phone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (phone.length != 10) {
      return 'El teléfono debe tener exactamente 10 dígitos';
    }
    
    if (!_phoneRegex.hasMatch(phone)) {
      return 'El teléfono solo debe contener números';
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

  /// Detecta códigos maliciosos en el texto
  /// Verifica caracteres peligrosos como <, >, script, javascript:, etc.
  static bool _containsMaliciousCode(String value) {
    final lowerValue = value.toLowerCase();
    
    // Caracteres peligrosos individuales
    final dangerousChars = ['<', '>', '/', '\\', '&', ';', '`', '\$'];
    for (var char in dangerousChars) {
      if (value.contains(char)) {
        return true;
      }
    }
    
    // Patrones maliciosos comunes
    final maliciousPatterns = [
      'script',
      'javascript:',
      'onerror=',
      'onclick=',
      'onload=',
      'onmouseover=',
      'eval(',
      'expression(',
      'vbscript:',
      'data:text/html',
      '<iframe',
      '<object',
      '<embed',
      '<?php',
      '<%',
      r'${',
    ];
    
    for (var pattern in maliciousPatterns) {
      if (lowerValue.contains(pattern)) {
        return true;
      }
    }
    
    // Verificar si empieza con caracteres peligrosos
    if (value.trim().startsWith('<') || value.trim().startsWith('>')) {
      return true;
    }
    
    return false;
  }

  /// Valida nombre y apellidos (solo letras, espacios y acentos, sin números)
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Por favor ingresa $fieldName';
    }
    
    final trimmed = value.trim();
    
    // Verificar códigos maliciosos
    if (_containsMaliciousCode(trimmed)) {
      return '$fieldName no puede contener caracteres o códigos maliciosos';
    }
    
    // Verificar que no contenga números
    if (trimmed.contains(RegExp(r'[0-9]'))) {
      return '$fieldName no puede contener números';
    }
    
    // Verificar que solo contenga letras, espacios y acentos
    if (!_nameRegex.hasMatch(trimmed)) {
      return '$fieldName solo puede contener letras, espacios y acentos';
    }
    
    // Verificar longitud mínima
    if (trimmed.length < 2) {
      return '$fieldName debe tener al menos 2 caracteres';
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

