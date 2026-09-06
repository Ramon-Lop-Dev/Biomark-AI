// Pantalla de edición de perfil — Biomark AI
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'biomark_brand.dart';

class EditarPerfilScreen extends StatefulWidget {
  final String nombreActual;
  final String correo;
  final int? edad;
  final String? fotoPath;

  const EditarPerfilScreen({
    super.key,
    required this.nombreActual,
    required this.correo,
    this.edad,
    this.fotoPath,
  });

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late TextEditingController _nombreController;
  File? _fotoSeleccionada;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombreActual);
    if (widget.fotoPath != null) {
      _fotoSeleccionada = File(widget.fotoPath!);
    }
  }

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (imagen != null) {
      setState(() => _fotoSeleccionada = File(imagen.path));
    }
  }

  void _guardarCambios() {
    Navigator.pop(context, {
      'nombre': _nombreController.text.trim(),
      'fotoPath': _fotoSeleccionada?.path,
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
          'Mi perfil',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: BiomarkColors.blue.withValues(alpha: .12),
                    backgroundImage: _fotoSeleccionada != null
                        ? FileImage(_fotoSeleccionada!)
                        : null,
                    child: _fotoSeleccionada == null
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
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre que se muestra en Inicio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                enabled: false,
                controller: TextEditingController(text: widget.correo),
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                enabled: false,
                controller: TextEditingController(
                  text: widget.edad != null ? widget.edad.toString() : '—',
                ),
                decoration: const InputDecoration(
                  labelText: 'Edad (según tu encuesta)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }
}