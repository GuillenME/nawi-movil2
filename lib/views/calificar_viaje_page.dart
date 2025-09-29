import 'package:flutter/material.dart';
import 'package:nawii/services/pasajero_service.dart';

class CalificarViajePage extends StatefulWidget {
  final String viajeId;
  final String taxistaNombre;

  const CalificarViajePage({
    Key? key,
    required this.viajeId,
    required this.taxistaNombre,
  }) : super(key: key);

  @override
  _CalificarViajePageState createState() => _CalificarViajePageState();
}

class _CalificarViajePageState extends State<CalificarViajePage> {
  final PasajeroService _pasajeroService = PasajeroService();
  final _comentarioController = TextEditingController();
  double _calificacion = 5.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarCalificacion() async {
    if (_calificacion < 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona una calificación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _pasajeroService.calificarViaje(
        viajeId: widget.viajeId,
        calificacion: _calificacion.round(),
        comentario: _comentarioController.text.trim().isNotEmpty
            ? _comentarioController.text.trim()
            : null,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
            context, true); // Retorna true para indicar que se calificó
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar calificación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calificar Viaje'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información del viaje
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 60,
                      color: Colors.blue[700],
                    ),
                    SizedBox(height: 16),
                    Text(
                      '¡Viaje Completado!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Taxista: ${widget.taxistaNombre}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            // Calificación con estrellas
            Text(
              '¿Cómo calificarías este viaje?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            // Estrellas interactivas
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _calificacion = (index + 1).toDouble();
                      });
                    },
                    child: Icon(
                      index < _calificacion ? Icons.star : Icons.star_border,
                      size: 50,
                      color: Colors.orange,
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 10),

            // Texto de la calificación
            Center(
              child: Text(
                _getCalificacionTexto(_calificacion),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            SizedBox(height: 30),

            // Campo de comentarios
            Text(
              'Comentarios (opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Comparte tu experiencia...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 30),

            // Botón para enviar calificación
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _enviarCalificacion,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.send),
              label: Text(_isLoading ? 'Enviando...' : 'Enviar Calificación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Botón para saltar calificación
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.pop(context,
                          false); // Retorna false para indicar que no se calificó
                    },
              child: Text(
                'Saltar calificación',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCalificacionTexto(double calificacion) {
    if (calificacion >= 5) return '¡Excelente!';
    if (calificacion >= 4) return 'Muy bueno';
    if (calificacion >= 3) return 'Bueno';
    if (calificacion >= 2) return 'Regular';
    return 'Malo';
  }
}
