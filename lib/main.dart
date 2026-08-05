import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/repositories/coinbase_repository.dart';
import 'data/repositories/open_fda_repository.dart';
import 'logic/telemetry/telemetry_bloc.dart';
import 'logic/heavy_data/heavy_data_bloc.dart';
import 'presentation/screens/dashboard_screen.dart';

void main() {
  runApp(const IcuPatientApp());
}

class IcuPatientApp extends StatelessWidget {
  const IcuPatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => CoinbaseRepository()),
        RepositoryProvider(create: (_) => OpenFDARepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => TelemetryBloc(
              context.read<CoinbaseRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => HeavyDataBloc(
              context.read<OpenFDARepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'ICU Patient Dashboard',
          theme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}
