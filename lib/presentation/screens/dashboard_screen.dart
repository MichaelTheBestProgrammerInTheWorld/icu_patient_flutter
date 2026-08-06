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

class _DashboardScreenState extends State<DashboardScreen> {
  final StreamController<Amplitude> _ecgController = StreamController<Amplitude>.broadcast();

  @override
  void initState() {
    super.initState();
    context.read<TelemetryBloc>().add(StartTelemetry());
  }

  @override
  void dispose() {
    _ecgController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ICU Vital Dashboard'),
        backgroundColor: Colors.grey[900],
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
              TelemetryGraph(
                stream: _ecgController.stream,
                label: 'ECG Waveform',
                color: Colors.greenAccent,
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
              // const Text(
              //   'Performance: Ticker parsing offloaded to Background Isolate.\nUI Thread throttled to 100ms updates.',
              //   textAlign: TextAlign.center,
              //   style: TextStyle(color: Colors.white54, fontSize: 12),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
