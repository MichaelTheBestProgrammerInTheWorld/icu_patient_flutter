import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waveform_flutter/waveform_flutter.dart';
import '../../logic/telemetry/telemetry_bloc.dart';
import '../../logic/telemetry/telemetry_event.dart';
import '../../logic/telemetry/telemetry_state.dart';
import '../../logic/heavy_data/heavy_data_bloc.dart';
import '../../logic/heavy_data/heavy_data_event.dart';
import '../../logic/heavy_data/heavy_data_state.dart';
import '../widgets/telemetry_graph.dart';

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
    context.read<HeavyDataBloc>().add(FetchFdaEvents());
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HeavyDataBloc>().add(FetchFdaEvents()),
          )
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<TelemetryBloc, TelemetryState>(
            listener: (context, state) {
              if (state is TelemetryDataUpdate) {
                _ecgController.add(state.amplitude);
              }
            },
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TelemetryGraph(
                stream: _ecgController.stream,
                label: 'ECG (Simulated via Coinbase BTC-USD)',
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'FDA Event Log (Processed in Background Isolate)',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<HeavyDataBloc, HeavyDataState>(
                  builder: (context, state) {
                    if (state is HeavyDataLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is HeavyDataLoaded) {
                      return ListView.builder(
                        itemCount: state.events.length,
                        itemBuilder: (context, index) {
                          final event = state.events[index];
                          return Card(
                            color: Colors.grey[850],
                            child: ListTile(
                              title: Text(
                                'Report ID: ${event['safetyreportid']}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Received: ${event['receivedate']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          );
                        },
                      );
                    } else if (state is HeavyDataError) {
                      return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)));
                    }
                    return const Center(child: Text('No data', style: TextStyle(color: Colors.white70)));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
