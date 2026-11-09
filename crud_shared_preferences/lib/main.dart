import 'package:flutter/material.dart';

import 'screens/produtos_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'CRUD com SharedPreferences',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    ),
    home: const ProdutosPage(),
  );
}
