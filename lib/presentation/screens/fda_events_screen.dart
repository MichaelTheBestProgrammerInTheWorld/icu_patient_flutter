import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/heavy_data/heavy_data_bloc.dart';
import '../../logic/heavy_data/heavy_data_event.dart';
import '../../logic/heavy_data/heavy_data_state.dart';

class FdaEventsScreen extends StatefulWidget {
  const FdaEventsScreen({super.key});

  @override
  State<FdaEventsScreen> createState() => _FdaEventsScreenState();
}

class _FdaEventsScreenState extends State<FdaEventsScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically trigger data fetch when screen is opened
    context.read<HeavyDataBloc>().add(FetchFdaEvents());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('FDA Event Log'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HeavyDataBloc>().add(FetchFdaEvents()),
          )
        ],
      ),
      body: BlocBuilder<HeavyDataBloc, HeavyDataState>(
        builder: (context, state) {
          if (state is HeavyDataLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HeavyDataLoaded) {
            if (state.events.isEmpty) {
              return const Center(child: Text('No events found', style: TextStyle(color: Colors.white70)));
            }
            return ListView.builder(
              itemCount: state.events.length,
              itemBuilder: (context, index) {
                final event = state.events[index];
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      'Report ID: ${event['safetyreportid']}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Received: ${event['receivedate']}\nCountry: ${event['primarysource']?['reportercountry'] ?? 'N/A'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          } else if (state is HeavyDataError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}', 
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<HeavyDataBloc>().add(FetchFdaEvents()),
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),
            );
          }
          return const Center(child: Text('Initializing...', style: TextStyle(color: Colors.white70)));
        },
      ),
    );
  }
}
