import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final Color? prefixIconColor;
  final InputDecoration? decoration;
  final Function(String placeId, String description, double? lat, double? lng)?
      onPlaceSelected;
  final String apiKey;
  final TextStyle? style;

  const PlacesAutocompleteField({
    Key? key,
    required this.controller,
    this.hintText = 'Buscar ubicación...',
    this.prefixIcon,
    this.prefixIconColor,
    this.decoration,
    this.onPlaceSelected,
    required this.apiKey,
    this.style,
  }) : super(key: key);

  @override
  _PlacesAutocompleteFieldState createState() =>
      _PlacesAutocompleteFieldState();
}

class _PlacesAutocompleteFieldState extends State<PlacesAutocompleteField> {
  List<Map<String, dynamic>> _predictions = [];
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          _removeOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.length > 2) {
      _searchPlaces(text);
    } else {
      _removeOverlay();
    }
  }

  Future<void> _searchPlaces(String input) async {
    try {
      // ⭐ ACTUALIZADO: Restringir búsqueda a Ocosingo, Chiapas
      // Coordenadas del centro de Ocosingo para location bias
      const double ocosingoLat = 16.9064;
      const double ocosingoLng = -92.0937;
      const int radius = 10000; // 10 km de radio desde el centro de Ocosingo

      // ⭐ CORREGIDO: Formato correcto de components (usar & para separar, no |)
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=${widget.apiKey}'
        '&components=country:mx'
        '&location=$ocosingoLat,$ocosingoLng'
        '&radius=$radius'
        '&language=es',
      );

      print('🔍 Buscando lugares: $input');
      print('🌐 URL: $url');

      final response = await http.get(url);

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 Status de API: ${data['status']}');

        if (data['status'] == 'OK' && data['predictions'] != null) {
          print('✅ Encontrados ${data['predictions'].length} resultados');

          // ⭐ NUEVO: Filtrar y priorizar resultados para evitar lugares incorrectos
          final predictionsRaw =
              List<Map<String, dynamic>>.from(data['predictions']);
          final predictionsFiltradas =
              _filtrarYPriorizarResultados(predictionsRaw, input);

          setState(() {
            _predictions = predictionsFiltradas;
            _showSuggestions = true;
          });
          _showOverlay();
        } else {
          print('⚠️  No se encontraron resultados o error: ${data['status']}');
          if (data['error_message'] != null) {
            print('❌ Error: ${data['error_message']}');
          }
          setState(() {
            _predictions = [];
            _showSuggestions = false;
          });
          _removeOverlay();
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('📦 Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al buscar lugares: $e');
      setState(() {
        _predictions = [];
        _showSuggestions = false;
      });
      _removeOverlay();
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    try {
      // ⭐ MEJORADO: Solicitar más campos para obtener información completa del lugar
      // Incluimos 'name' para verificar el nombre exacto y 'types' para validar que sea una universidad
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=${widget.apiKey}'
        '&fields=formatted_address,geometry,name,types,place_id,vicinity'
        '&language=es',
      );

      print('🔍 Obteniendo detalles del lugar con place_id: $placeId');
      print('🌐 URL: $url');

      final response = await http.get(url);
      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 Status de API: ${data['status']}');

        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          final address = result['formatted_address'] as String;
          final name = result['name'] as String? ?? 'Sin nombre';
          final types = List<String>.from(result['types'] ?? []);
          final geometry = result['geometry'];
          final location = geometry['location'];
          final lat = location['lat']?.toDouble();
          final lng = location['lng']?.toDouble();

          print('✅ Lugar encontrado: $name');
          print('📍 Dirección: $address');
          print('🏷️  Tipos: ${types.join(", ")}');
          print('🌍 Coordenadas: $lat, $lng');

          // Verificar si las coordenadas son válidas
          if (lat == null || lng == null) {
            print('⚠️  ERROR: Las coordenadas son nulas');
            throw Exception('No se pudieron obtener las coordenadas del lugar');
          }

          widget.controller.text = address;
          _removeOverlay();
          _focusNode.unfocus();

          if (widget.onPlaceSelected != null) {
            widget.onPlaceSelected!(placeId, address, lat, lng);
          }
        } else {
          print('❌ Error en Place Details API: ${data['status']}');
          if (data['error_message'] != null) {
            print('❌ Mensaje de error: ${data['error_message']}');
          }
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('📦 Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al obtener detalles del lugar: $e');
      rethrow;
    }
  }

  // Filtrar y priorizar resultados del autocomplete
  List<Map<String, dynamic>> _filtrarYPriorizarResultados(
      List<Map<String, dynamic>> predictions, String busqueda) {
    final busquedaLower = busqueda.toLowerCase();

    // ⭐ MEJORADO: Detectar búsqueda de universidad incluso con términos cortos
    // "uni" puede ser el inicio de "universidad", "universitario", etc.
    final esBusquedaUniversidad = busquedaLower.contains('universidad') ||
        busquedaLower.contains('tecnológica') ||
        busquedaLower.contains('tecnologica') ||
        busquedaLower.contains('uts') ||
        busquedaLower.startsWith('uni') ||
        (busquedaLower.length >= 3 && busquedaLower.contains('tec'));

    // ⭐ NUEVO: Siempre aplicar filtrado si hay resultados que mencionan "universidad" o "tecnológica"
    // incluso si la búsqueda es corta, para evitar resultados incorrectos
    bool tieneResultadosUniversidad = false;
    for (var prediction in predictions) {
      final description = (prediction['description'] as String).toLowerCase();
      if (description.contains('universidad') ||
          description.contains('tecnológica') ||
          description.contains('tecnologica')) {
        tieneResultadosUniversidad = true;
        break;
      }
    }

    if (!esBusquedaUniversidad && !tieneResultadosUniversidad) {
      // Si no es búsqueda de universidad y no hay resultados de universidad, devolver sin cambios
      return predictions;
    }

    // Lista para almacenar resultados con puntuación
    List<Map<String, dynamic>> resultadosConPuntuacion = [];

    for (var prediction in predictions) {
      final description = (prediction['description'] as String).toLowerCase();
      final structuredFormatting = prediction['structured_formatting'];
      final mainText = structuredFormatting != null
          ? (structuredFormatting['main_text'] as String? ?? '').toLowerCase()
          : '';

      int puntuacion = 0;

      // ❌ PENALIZAR: Si contiene "centrar", "centro", "centro sur", etc.
      if (description.contains('centrar') ||
          description.contains('centro sur') ||
          description.contains('centro norte') ||
          (description.contains('centro') &&
              !description.contains('universidad'))) {
        puntuacion -= 100; // Penalización fuerte
        print('   ⚠️  Penalizado (contiene centro/centrar): $description');
      }

      // ✅ PRIORIZAR: Si contiene el nombre completo de la universidad
      if (description.contains('universidad tecnológica de la selva') ||
          description.contains('universidad tecnologica de la selva')) {
        puntuacion += 50;
        print('   ✅ Bonus (nombre completo): $description');
      }

      // ✅ PRIORIZAR: Si contiene "camino a tonina" o "lequilum" (ubicación correcta)
      if (description.contains('camino a tonina') ||
          description.contains('tonina') ||
          description.contains('lequilum')) {
        puntuacion += 40;
        print('   ✅ Bonus (ubicación correcta): $description');
      }

      // ✅ PRIORIZAR: Si el texto principal contiene "universidad"
      if (mainText.contains('universidad')) {
        puntuacion += 30;
      }

      // ✅ PRIORIZAR: Si NO contiene palabras genéricas de ubicación
      if (!description.contains('centrar') &&
          !description.contains('centro') &&
          !description.contains('sur') &&
          !description.contains('norte')) {
        puntuacion += 10;
      }

      // ✅ PRIORIZAR: Si tiene tipos específicos (verificar si están disponibles)
      final types = prediction['types'] as List<dynamic>?;
      if (types != null) {
        if (types.contains('university')) {
          puntuacion += 60;
          print('   ✅ Bonus (tipo university): $description');
        }
        if (types.contains('school')) {
          puntuacion += 40;
        }
      }

      // Agregar puntuación al resultado
      final resultadoConPuntuacion = Map<String, dynamic>.from(prediction);
      resultadoConPuntuacion['_puntuacion'] = puntuacion;
      resultadosConPuntuacion.add(resultadoConPuntuacion);

      print('   📊 Puntuación: $puntuacion - $description');
    }

    // Ordenar por puntuación (mayor a menor)
    resultadosConPuntuacion.sort((a, b) {
      final puntA = a['_puntuacion'] as int;
      final puntB = b['_puntuacion'] as int;
      return puntB.compareTo(puntA);
    });

    // Remover la puntuación temporal antes de devolver
    final resultadosFinales = resultadosConPuntuacion.map((r) {
      final resultado = Map<String, dynamic>.from(r);
      resultado.remove('_puntuacion');
      return resultado;
    }).toList();

    print(
        '✅ Resultados ordenados por prioridad (${resultadosFinales.length} total)');
    for (var i = 0; i < resultadosFinales.length && i < 3; i++) {
      print('   ${i + 1}. ${resultadosFinales[i]['description']}');
    }

    return resultadosFinales;
  }

  void _showOverlay() {
    _removeOverlay();
    if (!_showSuggestions || _predictions.isEmpty) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _predictions.length > 5 ? 5 : _predictions.length,
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.location_on, color: Colors.blue),
                    title: Text(
                      prediction['description'] as String,
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      _getPlaceDetails(prediction['place_id'] as String);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: widget.style,
        decoration: widget.decoration ??
            InputDecoration(
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: widget.prefixIconColor)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
        inputFormatters: [
          // Filtrar caracteres peligrosos mientras el usuario escribe
          FilteringTextInputFormatter.deny(RegExp(r'[<>\\/&";\x00-\x1F\x7F]')),
        ],
      ),
    );
  }
}
