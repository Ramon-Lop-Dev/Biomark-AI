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
    this.normativaCodigo,
    this.normativaUrl,
    this.tipoAviso = 'CONSEJO',
    this.prioridad = 'MEDIA',
    this.alcanceTipo = 'GENERAL',
    this.condicionesObjetivo = const [],
    this.barrioComunidad = 'Managua',
    this.silais = 'SILAIS Managua',
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
  final String? normativaCodigo;
  final String? normativaUrl;
  final String tipoAviso;
  final String prioridad;
  final String alcanceTipo;
  final List<String> condicionesObjetivo;
  final String barrioComunidad;
  final String silais;

  factory HealthContentItem.fromJson(Map<String, dynamic> json) {
    final rawConds = json['condiciones_objetivo'];
    final condList = rawConds is List
        ? rawConds.map((e) => e.toString()).toList()
        : const <String>[];

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
      normativaCodigo: json['normativa_codigo']?.toString(),
      normativaUrl: json['normativa_url']?.toString(),
      tipoAviso: json['tipo_aviso']?.toString() ?? 'CONSEJO',
      prioridad: json['prioridad']?.toString() ?? 'MEDIA',
      alcanceTipo: json['alcance_tipo']?.toString() ?? 'GENERAL',
      condicionesObjetivo: condList,
      barrioComunidad: json['barrio_comunidad']?.toString() ?? 'Managua',
      silais: json['silais']?.toString() ?? 'SILAIS Managua',
    );
  }
}
