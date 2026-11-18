import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buruhku/app.dart';
import 'package:buruhku/config/dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final providers = await buildProviders();
  runApp(MultiProvider(providers: providers, child: const BuruhkuApp()));
}
