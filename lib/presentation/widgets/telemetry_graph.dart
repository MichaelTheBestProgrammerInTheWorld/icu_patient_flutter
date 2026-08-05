import 'dart:async';
import 'package:flutter/material.dart';
import 'package:waveform_flutter/waveform_flutter.dart';

class TelemetryGraph extends StatefulWidget {
  final Stream<Amplitude> stream;
  final Color color;
  final String label;

  const TelemetryGraph({
    super.key,
    required this.stream,
    this.color = Colors.greenAccent,
    required this.label,
  });

  @override
  State<TelemetryGraph> createState() => _TelemetryGraphState();
}

class _TelemetryGraphState extends State<TelemetryGraph> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              width: double.infinity,
              child: AnimatedWaveList(
                stream: widget.stream,
                barBuilder: (animation, amplitude) {
                  return WaveFormBar(
                    animation: animation,
                    amplitude: amplitude,
                    color: widget.color,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
