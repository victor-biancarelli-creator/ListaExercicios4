import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:crud_shared_preferences/data/produto_repository.dart';
import 'package:crud_shared_preferences/models/produto.dart';
import 'package:crud_shared_preferences/widgets/produto_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'CRUD JSON persiste, busca, ordena e mostra reutilização de ID',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repositorio = ProdutoRepository();
      await repositorio.inserir('Caderno', 12.5, 3);
      await repositorio.inserir('Caneta', 3, 8);
      await repositorio.inserir('Borracha', 2, 1);
      final primeiro = await repositorio.listar();
      expect(primeiro.map((p) => p.id), [3, 2, 1]);
      expect((await repositorio.listar(busca: 'CAD')).single.nome, 'Caderno');
      expect(
        (await repositorio.listar(ordem: OrdemProdutos.nomeCrescente))
            .map((p) => p.nome),
        ['Borracha', 'Caderno', 'Caneta'],
      );
      await repositorio.atualizar(
        const Produto(id: 1, nome: 'Caderno', preco: 14.9, quantidade: 4),
      );
      await repositorio.excluir(3);
      await repositorio.inserir('Lápis', 1.5, 0);
      final reaberto = ProdutoRepository();
      final produtos = await reaberto.listar();
      expect(produtos.first.id, 3);
      expect(produtos.last.preco, 14.9);
      expect(produtos.last.quantidade, 4);
      expect(
        jsonDecode(
          (await SharedPreferencesAsync().getString(ProdutoRepository.chave))!,
        ) as List,
        hasLength(3),
      );
    },
  );

  test('JSON antigo recebe estoque zero sem perder o produto', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          ProdutoRepository.chave: '[{"id":1,"nome":"Antigo","preco":5.0}]',
        });
    expect((await ProdutoRepository().listar()).single.quantidade, 0);
  });

  testWidgets('formulário exige preço positivo e estoque não negativo', (
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
                builder: (_) => const ProdutoDialog(),
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
    expect(resultado, isNull);
    await tester.enterText(find.byType(TextFormField).at(1), '12,50');
    await tester.enterText(find.byType(TextFormField).at(2), '0');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(resultado?.preco, 12.5);
    expect(resultado?.quantidade, 0);
  });
}
