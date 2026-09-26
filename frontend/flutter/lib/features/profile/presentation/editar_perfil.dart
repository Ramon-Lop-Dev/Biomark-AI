import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_biomark/biomark_brand.dart';
class EditarPerfilScreen extends StatefulWidget {
  final String nombreActual;
  final String correo;
  final int? edad;
  final DateTime? fechaNacimiento;
  final String? fotoUrl;
  final String? generoActual;

  const EditarPerfilScreen({
    super.key,
    required this.nombreActual,
    required this.correo,
    this.edad,
    this.fechaNacimiento,
    this.fotoUrl,
    this.generoActual,
  });

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late final TextEditingController _nombreController;
  late final TextEditingController _correoController;
  late final TextEditingController _edadController;
  late final FocusNode _nombreFocus;
  DateTime? _fechaNacimiento;
  Uint8List? _fotoBytes;
  String? _fotoNombre;
  String? _generoSeleccionado;

  final List<String> _opcionesGenero = const [
    'Femenino',
    'Masculino',
    'Otro',
    'Prefiero no decir',
  ];

  int? get _edadCalculada {
    if (_fechaNacimiento != null) {
      final now = DateTime.now();
      var age = now.year - _fechaNacimiento!.year;
      if (now.month < _fechaNacimiento!.month ||
          (now.month == _fechaNacimiento!.month && now.day < _fechaNacimiento!.day)) {
        age--;
      }
      return age;
    }
    return widget.edad;
  }

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombreActual);
    _correoController = TextEditingController(text: widget.correo);
    _fechaNacimiento = widget.fechaNacimiento;
    _edadController = TextEditingController(
      text: _edadCalculada != null ? _edadCalculada.toString() : '—',
    );
    _nombreFocus = FocusNode();
    _generoSeleccionado = _normalizarGenero(widget.generoActual);
  }

  String? _normalizarGenero(String? genero) {
    const valoresBackend = {
      'FEMENINO': 'Femenino',
      'MASCULINO': 'Masculino',
      'OTRO': 'Otro',
      'NO_ESPECIFICA': 'Prefiero no decir',
    };
    return valoresBackend[genero?.toUpperCase()] ??
        (_opcionesGenero.contains(genero) ? genero : null);
  }

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      setState(() {
        _fotoBytes = bytes;
        _fotoNombre = imagen.name;
      });
    }
  }

  void _guardarCambios() {
    Navigator.pop(context, {
      'nombre': _nombreController.text.trim(),
      'genero': _generoSeleccionado,
      'fechaNacimiento': _fechaNacimiento,
      'fotoBytes': _fotoBytes,
      'fotoNombre': _fotoNombre ?? 'perfil.jpg',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mi perfil y datos de cuenta',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
          maxLines: 2,
          softWrap: true,
        ),
        actions: [
          TextButton(
            onPressed: _guardarCambios,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: BiomarkColors.blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: BiomarkColors.blue.withValues(alpha: .12),
                        backgroundImage: _fotoBytes != null
                          ? MemoryImage(_fotoBytes!)
                          : widget.fotoUrl != null
                            ? NetworkImage(widget.fotoUrl!)
                            : null,
                        child: _fotoBytes == null && widget.fotoUrl == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: BiomarkColors.blue,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _cambiarFoto,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: BiomarkColors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    focusNode: _nombreFocus,
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre que se muestra en Inicio',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _generoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wc_rounded),
                    ),
                    items: _opcionesGenero
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _generoSeleccionado = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    enabled: false,
                    controller: _correoController,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final initial = _fechaNacimiento ?? DateTime(2000, 1, 1);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial.isAfter(now) ? now : initial,
                        firstDate: DateTime(1900),
                        lastDate: now,
                        helpText: 'Selecciona tu fecha de nacimiento',
                        cancelText: 'Cancelar',
                        confirmText: 'Confirmar',
                      );
                      if (picked != null) {
                        setState(() {
                          _fechaNacimiento = picked;
                          _edadController.text = '${_edadCalculada ?? '—'}';
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake_outlined),
                        suffixIcon: Icon(Icons.edit_calendar_rounded, size: 20),
                        helperText: 'Tu edad se actualiza de forma automática cada año según el calendario.',
                        helperMaxLines: 2,
                      ),
                      child: Text(
                        _fechaNacimiento != null
                            ? '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/${_fechaNacimiento!.month.toString().padLeft(2, '0')}/${_fechaNacimiento!.year}${_edadCalculada != null ? ' ($_edadCalculada años)' : ''}'
                            : (_edadCalculada != null ? '$_edadCalculada años (Toca para fijar fecha)' : 'Toca para seleccionar fecha'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreFocus.dispose();
    _nombreController.dispose();
    _correoController.dispose();
    _edadController.dispose();
    super.dispose();
  }
}