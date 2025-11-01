import 'package:flutter/material.dart';
import 'package:nawii/services/pasajero_service.dart';
import 'package:nawii/views/pasajero/solicitar_viaje_simple_page.dart';
import 'package:nawii/services/location_service_simple.dart';

class SolicitarViajePage extends StatefulWidget {
  const SolicitarViajePage({super.key});

  @override
  State<SolicitarViajePage> createState() => _SolicitarViajePageState();
}

class _SolicitarViajePageState extends State<SolicitarViajePage> {
  final _origenController = TextEditingController();
  final _destinoController = TextEditingController();
  final PasajeroService _pasajeroService = PasajeroService();

  Map<String, double>? _ubicacionActual;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  @override
  void dispose() {
    _origenController.dispose();
    _destinoController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      // Simular verificación de permisos
      bool hasPermission = await LocationServiceSimple.hasLocationPermission();
      if (!hasPermission) {
        hasPermission = await LocationServiceSimple.requestLocationPermission();
        if (!hasPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Se necesitan permisos de ubicación para usar esta función'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Obtener ubicación simulada
      Map<String, double> position = LocationServiceSimple.getCurrentLocation();

      setState(() {
        _ubicacionActual = position;
      });

      // Obtener dirección actual
      await _obtenerDireccionActual();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _obtenerDireccionActual() async {
    if (_ubicacionActual == null) return;

    try {
      final direccion = await _pasajeroService.obtenerDireccionDesdeCoordenadas(
        _ubicacionActual!['latitude']!,
        _ubicacionActual!['longitude']!,
      );
      _origenController.text = direccion;
    } catch (e) {
      _origenController.text = 'Ubicación actual';
    }
  }

  Future<void> _buscarDestino() async {
    if (_destinoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un destino'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener coordenadas del destino
      await _pasajeroService.obtenerCoordenadasDesdeDireccion(
        _destinoController.text.trim(),
      );

      // Navegar a la página simplificada de solicitar viaje
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SolicitarViajeSimplePage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar destino: $e'),
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
        title: const Text('Solicitar Viaje'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de origen
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Dónde estás?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _origenController,
                      decoration: InputDecoration(
                        hintText: 'Ubicación actual',
                        prefixIcon:
                            const Icon(Icons.my_location, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _obtenerUbicacionActual,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Actualizar ubicación'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Campo de destino
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿A dónde vas?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _destinoController,
                      decoration: InputDecoration(
                        hintText: 'Ingresa tu destino',
                        prefixIcon: const Icon(Icons.flag, color: Colors.red),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón para buscar taxistas
            ElevatedButton.icon(
              onPressed: _ubicacionActual == null || _isLoading
                  ? null
                  : _buscarDestino,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search, size: 24),
              label: Text(
                _isLoading ? 'Buscando...' : 'Buscar Taxistas',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Información adicional
            if (_ubicacionActual != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ubicación detectada correctamente',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
