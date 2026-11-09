import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/produto.dart';

enum OrdemProdutos { idDecrescente, nomeCrescente }

class ProdutoRepository {
  static const chave = 'crud.produtos';
  final SharedPreferencesAsync _prefs;
  ProdutoRepository([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  Future<List<Produto>> listar({
    String busca = '',
    OrdemProdutos ordem = OrdemProdutos.idDecrescente,
  }) async {
    final texto = await _prefs.getString(chave);
    if (texto == null || texto.isEmpty) return [];
    final termo = busca.trim().toLowerCase();
    final produtos = (jsonDecode(texto) as List<dynamic>)
        .map((item) => Produto.fromMap(Map<String, Object?>.from(item as Map)))
        .where((produto) => produto.nome.toLowerCase().contains(termo))
        .toList();
    if (ordem == OrdemProdutos.nomeCrescente) {
      produtos.sort((a, b) {
        final resultado = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        return resultado != 0 ? resultado : a.id.compareTo(b.id);
      });
    } else {
      produtos.sort((a, b) => b.id.compareTo(a.id));
    }
    return produtos;
  }

  Future<void> _salvar(List<Produto> produtos) => _prefs.setString(
    chave,
    jsonEncode(produtos.map((produto) => produto.toMap()).toList()),
  );

  Future<void> inserir(String nome, double preco, int quantidade) async {
    final produtos = await listar();
    final maior = produtos.fold<int>(
      0,
      (id, produto) => produto.id > id ? produto.id : id,
    );
    produtos.add(
      Produto(id: maior + 1, nome: nome, preco: preco, quantidade: quantidade),
    );
    await _salvar(produtos);
  }

  Future<void> atualizar(Produto produto) async {
    final produtos = await listar();
    final indice = produtos.indexWhere((item) => item.id == produto.id);
    if (indice < 0) throw StateError('Produto não encontrado.');
    produtos[indice] = produto;
    await _salvar(produtos);
  }

  Future<void> excluir(int id) async {
    final produtos = await listar();
    final anterior = produtos.length;
    produtos.removeWhere((produto) => produto.id == id);
    if (produtos.length == anterior) {
      throw StateError('Produto não encontrado.');
    }
    await _salvar(produtos);
  }
}
