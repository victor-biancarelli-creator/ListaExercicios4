# Exercícios de persistência (itens 4 a 9)

## 4. Quantidade em estoque

Os dois modelos e formulários incluem `quantidade`. No projeto SharedPreferences, `toMap` grava o campo no JSON e `fromMap` assume zero ao ler registros antigos. No SQLite, a versão 2 do banco adiciona a coluna `quantidade`; a migração copia os produtos existentes com estoque zero.

## 5. Validação

Os formulários aceitam somente preço finito e estritamente maior que zero e quantidade inteira maior ou igual a zero. O banco SQLite exige quantidade não negativa. No banco, preço zero continua permitido para preservar registros criados pela versão inicial do capítulo; novos cadastros passam pela validação do formulário.

## 6. Ordenação

A seleção da tela alterna entre nome crescente e ID decrescente. No JSON, a lista recuperada é ordenada em Dart; no SQLite, a consulta usa `ORDER BY`. Assim, o SQLite entrega os registros já ordenados, enquanto o JSON precisa carregar e ordenar a lista no aplicativo.

## 7. Busca

O campo de busca procura parte do nome, sem diferenciar maiúsculas e minúsculas. O projeto JSON filtra a lista após decodificá-la. O SQLite aplica o filtro na consulta SQL antes de devolver os registros.

## 8. Identificadores

Ao cadastrar três produtos (IDs 1, 2 e 3), excluir o terceiro e cadastrar outro, o novo ID é 3 no projeto JSON e 4 no SQLite. O primeiro calcula `maior ID atual + 1` e reutiliza o número excluído. O segundo usa `AUTOINCREMENT`, que não reutiliza um ID já emitido.

## 9. Categorias

O SQLite possui a tabela `categorias` e a coluna `produtos.categoria_id` como chave estrangeira. O formulário permite escolher uma categoria e a listagem mostra seu nome. SharedPreferences armazena um texto JSON por chave: não oferece tabelas, chave estrangeira nem integridade referencial implementadas pelo banco. Uma associação semelhante exigiria código manual para manter os dados consistentes.
