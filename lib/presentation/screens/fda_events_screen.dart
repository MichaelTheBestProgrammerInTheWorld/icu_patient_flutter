import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/heavy_data/heavy_data_bloc.dart';
import '../../logic/heavy_data/heavy_data_event.dart';
import '../../logic/heavy_data/heavy_data_state.dart';

class FdaEventsScreen extends StatelessWidget {
  const FdaEventsScreen({super.key});

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
                child: Text('Error: ${state.message}', 
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return const Center(child: Text('No data loaded', style: TextStyle(color: Colors.white70)));
        },
      ),
    );
  }
}
