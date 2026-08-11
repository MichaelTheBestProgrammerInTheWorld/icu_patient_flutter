import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waveform_flutter/waveform_flutter.dart';
import '../../logic/telemetry/telemetry_bloc.dart';
import '../../logic/telemetry/telemetry_event.dart';
import '../../logic/telemetry/telemetry_state.dart';
import '../widgets/telemetry_graph.dart';
import 'fda_events_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  final StreamController<Amplitude> _ecgController = StreamController<Amplitude>.broadcast();
  bool _isStreaming = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<TelemetryBloc>().add(StartTelemetry());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ecgController.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // RESOURCE MANAGEMENT: Pause telemetry when app is backgrounded to save battery/network
    if (state == AppLifecycleState.paused) {
      context.read<TelemetryBloc>().add(StopTelemetry());
    } else if (state == AppLifecycleState.resumed && _isStreaming) {
      context.read<TelemetryBloc>().add(StartTelemetry());
    }
  }

  void _toggleStreaming() {
    setState(() {
      _isStreaming = !_isStreaming;
    });
    if (_isStreaming) {
      context.read<TelemetryBloc>().add(StartTelemetry());
    } else {
      context.read<TelemetryBloc>().add(StopTelemetry());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ICU Vital Dashboard'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: Icon(_isStreaming ? Icons.pause_circle_filled : Icons.play_circle_filled),
            color: _isStreaming ? Colors.redAccent : Colors.greenAccent,
            onPressed: _toggleStreaming,
            tooltip: _isStreaming ? 'Stop Telemetry' : 'Start Telemetry',
          ),
        ],
      ),
      body: BlocListener<TelemetryBloc, TelemetryState>(
        listener: (context, state) {
          if (state is TelemetryDataUpdate) {
            _ecgController.add(state.amplitude);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PERFORMANCE ENHANCEMENT: RepaintBoundary isolates high-frequency repaints
              // from the rest of the UI (buttons, appbar, text).
              RepaintBoundary(
                child: BlocBuilder<TelemetryBloc, TelemetryState>(
                  buildWhen: (previous, current) => 
                      current is TelemetryLoading || current is TelemetryError || current is TelemetryInitial
                          || current is TelemetryDataUpdate,
                  builder: (context, state) {
                    if (state is TelemetryLoading) {
                      return const SizedBox(
                        height: 140,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (state is TelemetryError) {
                      return Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent),
                            const SizedBox(height: 8),
                            Text('Error: ${state.message}', style: const TextStyle(color: Colors.white70)),
                            TextButton(
                              onPressed: () => context.read<TelemetryBloc>().add(StartTelemetry()),
                              child: const Text('RETRY'),
                            )
                          ],
                        ),
                      );
                    }
                    if (!_isStreaming && state is TelemetryInitial) {
                      return const SizedBox(
                        height: 140,
                        child: Center(child: Text('Telemetry Paused', style: TextStyle(color: Colors.white54))),
                      );
                    }

                    return TelemetryGraph(
                      stream: _ecgController.stream,
                      label: 'ECG (Parsed in Long-Lived Isolate)',
                      color: Colors.greenAccent,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FdaEventsScreen()),
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: const Text('VIEW FDA EVENTS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Optimization: RepaintBoundary & Lifecycle Awareness active.\nUI updates strictly capped at 100ms.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
