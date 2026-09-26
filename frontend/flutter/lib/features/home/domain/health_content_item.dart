class HealthContentItem {
  const HealthContentItem({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.contenido,
    required this.categoria,
    required this.fuente,
    this.imagenUrl,
    required this.fechaPublicacion,
    this.estado = 'PUBLICADO',
  });

  final String id;
  final String titulo;
  final String descripcion;
  final String contenido;
  final String categoria;
  final String fuente;
  final String? imagenUrl;
  final DateTime fechaPublicacion;
  final String estado;

  factory HealthContentItem.fromJson(Map<String, dynamic> json) {
    return HealthContentItem(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? 'Aviso de Salud',
      descripcion: json['descripcion']?.toString() ?? '',
      contenido: json['contenido']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? 'GENERAL',
      fuente: json['fuente']?.toString() ?? 'MINSA Nicaragua',
      imagenUrl: json['imagen_url']?.toString(),
      fechaPublicacion: DateTime.tryParse(json['fecha_publicacion']?.toString() ?? '') ??
          DateTime.now(),
      estado: json['estado']?.toString() ?? 'PUBLICADO',
    );
  }
}
