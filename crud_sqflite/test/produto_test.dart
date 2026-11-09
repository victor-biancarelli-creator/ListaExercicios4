import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:crud_sqflite/data/produto_repository.dart';
import 'package:crud_sqflite/models/categoria.dart';
import 'package:crud_sqflite/models/produto.dart';
import 'package:crud_sqflite/widgets/produto_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory pasta;
  late String caminho;
  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('crud_sqflite_test_');
    caminho = '${pasta.path}/produtos.db';
  });
  tearDown(() async => pasta.delete(recursive: true));

  test(
    'CRUD SQLite mantém categoria, busca, ordenação e ID crescente',
    () async {
      final repositorio = ProdutoRepository(caminho: caminho);
      final categorias = await repositorio.listarCategorias();
      expect(categorias.map((c) => c.nome), contains('Papelaria'));
      final papelaria = categorias.firstWhere((c) => c.nome == 'Papelaria').id;
      await expectLater(
        repositorio.inserir('Sem categoria', 1, 0, 999),
        throwsA(isA<DatabaseException>()),
      );
      await repositorio.inserir('Caderno', 12.5, 3, papelaria);
      await repositorio.inserir('Caneta', 3, 8, papelaria);
      await repositorio.inserir('Borracha', 2, 1, papelaria);
      expect((await repositorio.listar(busca: 'CAD')).single.nome, 'Caderno');
      expect(
        (await repositorio.listar(ordem: OrdemProdutos.nomeCrescente))
            .map((p) => p.nome),
        ['Borracha', 'Caderno', 'Caneta'],
      );
      await repositorio.atualizar(
        Produto(
          id: 1,
          nome: 'Caderno',
          preco: 14.9,
          quantidade: 4,
          categoriaId: papelaria,
        ),
      );
      await repositorio.excluir(3);
      await repositorio.inserir('Lápis', 1.5, 0, papelaria);
      await repositorio.fechar();
      final reaberto = ProdutoRepository(caminho: caminho);
      final produtos = await reaberto.listar();
      expect(produtos.map((p) => p.id), [4, 2, 1]);
      expect(produtos.last.preco, 14.9);
      expect(produtos.last.quantidade, 4);
      expect(produtos.last.categoriaNome, 'Papelaria');
      await reaberto.fechar();
    },
  );

  test('migra banco original e preserva registros e próximos IDs', () async {
    final antigo = await openDatabase(
      caminho,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE produtos (id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT NOT NULL, preco REAL NOT NULL)',
        );
      },
    );
    await antigo.insert('produtos', {'nome': 'Legado', 'preco': 0.0});
    await antigo.close();
    final repositorio = ProdutoRepository(caminho: caminho);
    final produto = (await repositorio.listar()).single;
    expect(produto.quantidade, 0);
    expect(produto.preco, 0);
    expect(produto.categoriaNome, 'Geral');
    await repositorio.inserir('Novo', 2, 0, 1);
    expect((await repositorio.listar()).first.id, 2);
    await repositorio.fechar();
  });

  testWidgets('formulário valida valores e devolve a categoria escolhida', (
    tester,
  ) async {
    Produto? resultado;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => resultado = await showDialog<Produto>(
                context: context,
                builder: (_) => const ProdutoDialog(
                  categorias: [
                    Categoria(id: 1, nome: 'Geral'),
                    Categoria(id: 2, nome: 'Papelaria'),
                  ],
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Caderno');
    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tester.enterText(find.byType(TextFormField).at(2), '-1');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um preço maior que zero.'), findsOneWidget);
    expect(
      find.text('Informe uma quantidade inteira não negativa.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField).at(1), '12,50');
    await tester.enterText(find.byType(TextFormField).at(2), '0');
    await tester.tap(find.text('Geral').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Papelaria').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(resultado?.categoriaId, 2);
    expect(resultado?.preco, 12.5);
  });
}
