import 'package:flutter/material.dart';

import '../models/produto.dart';

class ProdutoDialog extends StatefulWidget {
  final Produto? produto;
  const ProdutoDialog({super.key, this.produto});
  @override
  State<ProdutoDialog> createState() => _ProdutoDialogState();
}

class _ProdutoDialogState extends State<ProdutoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _preco;
  late final TextEditingController _quantidade;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.produto?.nome ?? '');
    _preco = TextEditingController(
      text: widget.produto?.preco.toStringAsFixed(2).replaceAll('.', ',') ?? '',
    );
    _quantidade = TextEditingController(
      text: widget.produto?.quantidade.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nome.dispose();
    _preco.dispose();
    _quantidade.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Produto(
        id: widget.produto?.id ?? 0,
        nome: _nome.text.trim(),
        preco: double.parse(_preco.text.trim().replaceAll(',', '.')),
        quantidade: int.parse(_quantidade.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.produto == null ? 'Cadastrar produto' : 'Editar produto',
    ),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) => valor == null || valor.trim().isEmpty
                    ? 'Informe o nome.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _preco,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Preço',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  final numero = double.tryParse(
                    (valor ?? '').trim().replaceAll(',', '.'),
                  );
                  return numero == null || !numero.isFinite || numero <= 0
                      ? 'Informe um preço maior que zero.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantidade,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade em estoque',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  final numero = int.tryParse((valor ?? '').trim());
                  return numero == null || numero < 0
                      ? 'Informe uma quantidade inteira não negativa.'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _salvar, child: const Text('Salvar')),
    ],
  );
}
