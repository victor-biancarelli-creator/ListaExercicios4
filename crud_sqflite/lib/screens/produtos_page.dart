import 'package:flutter/material.dart';

import '../data/produto_repository.dart';
import '../models/categoria.dart';
import '../models/produto.dart';
import '../widgets/produto_dialog.dart';

class ProdutosPage extends StatefulWidget {
  final ProdutoRepository? repositorio;
  const ProdutosPage({super.key, this.repositorio});
  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  late final ProdutoRepository _repositorio;
  final _busca = TextEditingController();
  OrdemProdutos _ordem = OrdemProdutos.idDecrescente;
  List<Produto> _produtos = [];
  List<Categoria> _categorias = [];
  bool _carregando = true;
  bool _processando = false;
  String? _erro;
  int _pedido = 0;

  @override
  void initState() {
    super.initState();
    _repositorio = widget.repositorio ?? ProdutoRepository();
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final pedido = ++_pedido;
    setState(() => _carregando = true);
    try {
      final categorias = await _repositorio.listarCategorias();
      final produtos = await _repositorio.listar(
        busca: _busca.text,
        ordem: _ordem,
      );
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _categorias = categorias;
        _produtos = produtos;
        _erro = null;
      });
    } catch (erro) {
      if (!mounted || pedido != _pedido) return;
      setState(() => _erro = 'Falha ao carregar: $erro');
    } finally {
      if (mounted && pedido == _pedido) setState(() => _carregando = false);
    }
  }

  void _mensagem(String texto) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _abrirFormulario([Produto? original]) async {
    if (_processando) return;
    if (_categorias.isEmpty) {
      _mensagem('Nenhuma categoria disponível.');
      return;
    }
    final produto = await showDialog<Produto>(
      context: context,
      builder: (_) => ProdutoDialog(produto: original, categorias: _categorias),
    );
    if (produto == null || !mounted) return;
    setState(() => _processando = true);
    try {
      if (original == null) {
        await _repositorio.inserir(
          produto.nome,
          produto.preco,
          produto.quantidade,
          produto.categoriaId,
        );
      } else {
        await _repositorio.atualizar(produto);
      }
      await _carregar();
      if (mounted) {
        _mensagem(
          original == null ? 'Produto cadastrado.' : 'Produto atualizado.',
        );
      }
    } catch (erro) {
      if (mounted) _mensagem('Erro ao salvar: $erro');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _excluir(Produto produto) async {
    if (_processando) return;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: Text('Deseja excluir ${produto.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _processando = true);
    try {
      await _repositorio.excluir(produto.id);
      await _carregar();
      if (mounted) _mensagem('Produto excluído.');
    } catch (erro) {
      if (mounted) _mensagem('Erro ao excluir: $erro');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Produtos • SQLite')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _busca,
                onChanged: (_) => _carregar(),
                decoration: const InputDecoration(
                  labelText: 'Buscar por nome',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OrdemProdutos>(
                initialValue: _ordem,
                decoration: const InputDecoration(
                  labelText: 'Ordenar por',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: OrdemProdutos.idDecrescente,
                    child: Text('ID decrescente'),
                  ),
                  DropdownMenuItem(
                    value: OrdemProdutos.nomeCrescente,
                    child: Text('Nome crescente'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    _ordem = valor;
                    _carregar();
                  }
                },
              ),
            ],
          ),
        ),
        if (_carregando) const LinearProgressIndicator(),
        Expanded(
          child: _erro != null
              ? Center(child: Text(_erro!))
              : _produtos.isEmpty
              ? Center(
                  child: Text(
                    _busca.text.isEmpty
                        ? 'Nenhum produto cadastrado.'
                        : 'Nenhum produto encontrado.',
                  ),
                )
              : ListView.builder(
                  itemCount: _produtos.length,
                  itemBuilder: (context, indice) {
                    final produto = _produtos[indice];
                    return ListTile(
                      title: Text(produto.nome),
                      subtitle: Text(
                        'ID ${produto.id} • R\$ ${produto.preco.toStringAsFixed(2).replaceAll('.', ',')} • Estoque: ${produto.quantidade} • ${produto.categoriaNome}',
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Editar ${produto.nome}',
                            onPressed: _processando
                                ? null
                                : () => _abrirFormulario(produto),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Excluir ${produto.nome}',
                            onPressed: _processando
                                ? null
                                : () => _excluir(produto),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _processando ? null : () => _abrirFormulario(),
      icon: const Icon(Icons.add),
      label: const Text('Novo produto'),
    ),
  );
}
