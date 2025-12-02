class DateFormatter {
  /// Convierte una fecha UTC a la zona horaria local de México (America/Mexico_City)
  /// Si la fecha ya está en hora local, la devuelve tal cual
  static DateTime toLocalTime(DateTime fecha) {
    // Si la fecha no tiene información de zona horaria, asumimos que es UTC
    // y la convertimos a hora local
    if (fecha.isUtc) {
      return fecha.toLocal();
    }
    // Si ya es local, devolverla tal cual
    return fecha;
  }

  /// Formatea una fecha con hora en formato DD/MM/YYYY HH:MM (hora local)
  static String formatearFechaConHora(DateTime fecha) {
    final fechaLocal = toLocalTime(fecha);
    final dia = fechaLocal.day.toString().padLeft(2, '0');
    final mes = fechaLocal.month.toString().padLeft(2, '0');
    final anio = fechaLocal.year.toString();
    final hora = fechaLocal.hour.toString().padLeft(2, '0');
    final minuto = fechaLocal.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$minuto';
  }

  /// Formatea una fecha sin hora en formato DD/MM/YYYY (hora local)
  static String formatearFecha(DateTime fecha) {
    final fechaLocal = toLocalTime(fecha);
    final dia = fechaLocal.day.toString().padLeft(2, '0');
    final mes = fechaLocal.month.toString().padLeft(2, '0');
    final anio = fechaLocal.year.toString();
    return '$dia/$mes/$anio';
  }
}

