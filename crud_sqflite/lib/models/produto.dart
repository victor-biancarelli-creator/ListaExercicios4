class Produto {
  final int id;
  final String nome;
  final double preco;
  final int quantidade;
  final int categoriaId;
  final String categoriaNome;

  const Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.quantidade,
    required this.categoriaId,
    this.categoriaNome = '',
  });

  factory Produto.fromMap(Map<String, Object?> mapa) => Produto(
    id: (mapa['id'] as num).toInt(),
    nome: mapa['nome'] as String,
    preco: (mapa['preco'] as num).toDouble(),
    quantidade: (mapa['quantidade'] as num).toInt(),
    categoriaId: (mapa['categoria_id'] as num).toInt(),
    categoriaNome: (mapa['categoria_nome'] as String?) ?? '',
  );
}
