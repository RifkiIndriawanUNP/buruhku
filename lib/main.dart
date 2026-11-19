import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buruhku/app.dart';
import 'package:buruhku/config/dependencies.dart';
import 'package:buruhku/ui/core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load(); // pilihan tampilan tersimpan
  final providers = await buildProviders();
  runApp(MultiProvider(providers: providers, child: const BuruhkuApp()));
}
