import 'package:flutter/material.dart';

import '../features/analysis/presentation/analysis_page.dart';

class PoiAnalysisApp extends StatelessWidget {
  const PoiAnalysisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poilabs Analysis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066CC)),
        useMaterial3: true,
      ),
      home: const AnalysisPage(),
    );
  }
}
