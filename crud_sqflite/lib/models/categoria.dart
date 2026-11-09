class Categoria {
  final int id;
  final String nome;
  const Categoria({required this.id, required this.nome});

  factory Categoria.fromMap(Map<String, Object?> mapa) =>
      Categoria(id: (mapa['id'] as num).toInt(), nome: mapa['nome'] as String);
}
