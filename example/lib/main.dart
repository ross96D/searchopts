import 'package:flutter/material.dart';
import 'package:searchopts/searchopts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SearchOptions(
          onSelected: (v) => print(v),
          options: Option.fromString(["opt1", "opt2", "opt3"]),
          renderOption: (context, item, config) {
            final theme = Theme.of(context);
            return ListTile(
              title: Text(item),
              tileColor: config.isHighlighted
                  ? Color.alphaBlend(theme.hoverColor, theme.colorScheme.background)
                  : theme.colorScheme.background,
            );
          },
        ),
      ),
    );
  }
}
