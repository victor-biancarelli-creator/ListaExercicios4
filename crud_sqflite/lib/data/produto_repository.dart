import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/categoria.dart';
import '../models/produto.dart';

enum OrdemProdutos { idDecrescente, nomeCrescente }

class ProdutoRepository {
  final String? caminho;
  Future<Database>? _abertura;
  ProdutoRepository({this.caminho});

  Future<Database> get _database => _abertura ??= _abrir();

  Future<Database> _abrir() async {
    final arquivo = caminho ?? join(await getDatabasesPath(), 'produtos.db');
    return openDatabase(
      arquivo,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await _criarCategorias(db);
        await _criarProdutos(db);
      },
      onUpgrade: (db, antigo, novo) async {
        if (antigo < 2) {
          // Preserva os registros da versão original do capítulo.
          await db.execute('ALTER TABLE produtos RENAME TO produtos_antigos');
          await _criarCategorias(db);
          await _criarProdutos(db);
          await db.execute(
            'INSERT INTO produtos (id, nome, preco, quantidade, categoria_id) '
            'SELECT id, nome, preco, 0, 1 FROM produtos_antigos',
          );
          await db.execute('DROP TABLE produtos_antigos');
          await db.execute(
            "UPDATE sqlite_sequence SET seq = (SELECT MAX(id) FROM produtos) WHERE name = 'produtos'",
          );
        }
      },
    );
  }

  static Future<void> _criarCategorias(Database db) async {
    await db.execute(
      'CREATE TABLE categorias (id INTEGER PRIMARY KEY, nome TEXT NOT NULL UNIQUE)',
    );
    for (final categoria in const [
      'Geral',
      'Papelaria',
      'Eletrônicos',
      'Outros',
    ]) {
      await db.insert('categorias', {'nome': categoria});
    }
  }

  static Future<void> _criarProdutos(Database db) async {
    await db.execute('''
      CREATE TABLE produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        preco REAL NOT NULL CHECK (preco >= 0),
        quantidade INTEGER NOT NULL DEFAULT 0 CHECK (quantidade >= 0),
        categoria_id INTEGER NOT NULL REFERENCES categorias(id)
      )
    ''');
  }

  Future<List<Categoria>> listarCategorias() async {
    final db = await _database;
    final linhas = await db.query(
      'categorias',
      orderBy: 'nome COLLATE NOCASE ASC',
    );
    return linhas.map(Categoria.fromMap).toList();
  }

  Future<List<Produto>> listar({
    String busca = '',
    OrdemProdutos ordem = OrdemProdutos.idDecrescente,
  }) async {
    final db = await _database;
    final ordenacao = ordem == OrdemProdutos.nomeCrescente
        ? 'p.nome COLLATE NOCASE ASC, p.id ASC'
        : 'p.id DESC';
    final linhas = await db.rawQuery(
      'SELECT p.id, p.nome, p.preco, p.quantidade, p.categoria_id, '
      'c.nome AS categoria_nome FROM produtos p '
      'JOIN categorias c ON c.id = p.categoria_id '
      'WHERE instr(lower(p.nome), lower(?)) > 0 ORDER BY $ordenacao',
      [busca.trim()],
    );
    return linhas.map(Produto.fromMap).toList();
  }

  Future<void> inserir(
    String nome,
    double preco,
    int quantidade,
    int categoriaId,
  ) async {
    final db = await _database;
    await db.insert('produtos', {
      'nome': nome,
      'preco': preco,
      'quantidade': quantidade,
      'categoria_id': categoriaId,
    });
  }

  Future<void> atualizar(Produto produto) async {
    final db = await _database;
    final alterados = await db.update(
      'produtos',
      {
        'nome': produto.nome,
        'preco': produto.preco,
        'quantidade': produto.quantidade,
        'categoria_id': produto.categoriaId,
      },
      where: 'id = ?',
      whereArgs: [produto.id],
    );
    if (alterados == 0) throw StateError('Produto não encontrado.');
  }

  Future<void> excluir(int id) async {
    final db = await _database;
    final excluidos = await db.delete(
      'produtos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (excluidos == 0) throw StateError('Produto não encontrado.');
  }

  Future<void> fechar() async {
    final abertura = _abertura;
    if (abertura != null) await (await abertura).close();
    _abertura = null;
  }
}
