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
  final Function(String placeId, String description)? onPlaceSelected;
  final String apiKey;

  const PlacesAutocompleteField({
    Key? key,
    required this.controller,
    this.hintText = 'Buscar ubicación...',
    this.prefixIcon,
    this.prefixIconColor,
    this.decoration,
    this.onPlaceSelected,
    required this.apiKey,
  }) : super(key: key);

  @override
  _PlacesAutocompleteFieldState createState() => _PlacesAutocompleteFieldState();
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
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=${widget.apiKey}'
        '&components=country:mx'
        '&language=es',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['predictions'] != null) {
          setState(() {
            _predictions = List<Map<String, dynamic>>.from(data['predictions']);
            _showSuggestions = true;
          });
          _showOverlay();
        } else {
          setState(() {
            _predictions = [];
            _showSuggestions = false;
          });
          _removeOverlay();
        }
      }
    } catch (e) {
      print('Error al buscar lugares: $e');
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=${widget.apiKey}'
        '&fields=formatted_address,geometry'
        '&language=es',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          final address = result['formatted_address'] as String;
          
          widget.controller.text = address;
          _removeOverlay();
          _focusNode.unfocus();

          if (widget.onPlaceSelected != null) {
            widget.onPlaceSelected!(placeId, address);
          }
        }
      }
    } catch (e) {
      print('Error al obtener detalles del lugar: $e');
    }
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

