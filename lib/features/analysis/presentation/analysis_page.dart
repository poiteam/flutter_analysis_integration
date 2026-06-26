import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/platform/poi_analysis_method_channel.dart';
import '../data/analysis_repository.dart';
import 'analysis_controller.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  late final AnalysisController _controller;
  StreamSubscription<void>? _changesSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnalysisController(
      AnalysisRepository(PoiAnalysisMethodChannel()),
    );
    _changesSubscription = _controller.changes.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodeIdsText = _controller.nodeIds.isEmpty
        ? 'Node IDs will appear here'
        : _controller.nodeIds.join('\n');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poilabs Analysis'),
        actions: [
          IconButton(
            tooltip: 'Clear results',
            onPressed: _controller.clearResults,
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                platform: _controller.platform,
                uniqueId: _controller.uniqueId,
                sdkVersion: _controller.sdkVersion,
                statusMessage: _controller.statusMessage,
                lastError: _controller.lastError,
                isScanning: _controller.isScanning,
              ),
              const SizedBox(height: 16),
              const Text(
                'Node IDs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      nodeIdsText,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _controller.isScanning ? null : _controller.startScan,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _controller.isScanning ? _controller.stopScan : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.platform,
    required this.uniqueId,
    required this.sdkVersion,
    required this.statusMessage,
    required this.lastError,
    required this.isScanning,
  });

  final String platform;
  final String uniqueId;
  final String sdkVersion;
  final String? statusMessage;
  final String? lastError;
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Platform: $platform'),
            const SizedBox(height: 4),
            Text('Unique ID: $uniqueId'),
            const SizedBox(height: 4),
            Text('SDK Version: $sdkVersion'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isScanning ? Icons.sensors : Icons.sensors_off,
                  size: 18,
                  color: isScanning ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(isScanning ? 'Scanning' : 'Idle'),
              ],
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 8),
              Text('Status: $statusMessage'),
            ],
            if (lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: $lastError',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
