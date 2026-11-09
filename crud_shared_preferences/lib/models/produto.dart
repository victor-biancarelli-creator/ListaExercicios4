class Produto {
  final int id;
  final String nome;
  final double preco;
  final int quantidade;

  const Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.quantidade,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'nome': nome,
    'preco': preco,
    'quantidade': quantidade,
  };

  factory Produto.fromMap(Map<String, Object?> mapa) => Produto(
    id: (mapa['id'] as num).toInt(),
    nome: mapa['nome'] as String,
    preco: (mapa['preco'] as num).toDouble(),
    quantidade: (mapa['quantidade'] as num?)?.toInt() ?? 0,
  );
}
