import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:waveform_flutter/waveform_flutter.dart';

/// Commands sent from Main Isolate to Worker Isolate
enum WorkerCommand { start, stop }

/// Messages sent from Worker Isolate to Main Isolate
class WorkerMessage {
  final Amplitude? amplitude;
  final String? error;
  final SendPort? commandPort;

  WorkerMessage({this.amplitude, this.error, this.commandPort});
}

class CoinbaseRepository {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPortToWorker;
  final StreamController<Amplitude> _dataController = StreamController<Amplitude>.broadcast();

  Stream<Amplitude> get tickerStream {
    _startIsolate();
    return _dataController.stream;
  }

  Future<void> _startIsolate() async {
    if (_isolate != null) return;

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_workerEntryPoint, _receivePort!.sendPort);

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPortToWorker = message;
        _sendPortToWorker!.send(WorkerCommand.start);
      } else if (message is Map<String, dynamic>) {
        // Handle amplitude data from worker
        final current = message['current'] as double;
        final max = message['max'] as double;
        _dataController.add(Amplitude(current: current, max: max));
      } else if (message is String) {
        // Handle error strings
        _dataController.addError(message);
      }
    });
  }

  static void _workerEntryPoint(SendPort mainSendPort) {
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    WebSocketChannel? channel;
    StreamSubscription? subscription;

    workerReceivePort.listen((command) {
      if (command == WorkerCommand.start) {
        channel = WebSocketChannel.connect(Uri.parse('wss://ws-feed.exchange.coinbase.com'));
        
        final subscriptionMsg = {
          "type": "subscribe",
          "channels": [
            {"name": "ticker", "product_ids": ["BTC-USD"]}
          ]
        };
        channel!.sink.add(jsonEncode(subscriptionMsg));

        subscription = channel!.stream.listen((message) {
          // HEAVY JSON PARSING IN WORKER ISOLATE
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'ticker' && data['price'] != null) {
              final price = double.tryParse(data['price']) ?? 0.0;
              final normalized = (price % 100) / 100.0;
              
              // We send a Map because Amplitude classes cannot be sent across isolates
              // if they contain non-primitive logic, but here it's simple. 
              // However, Maps are always safe.
              mainSendPort.send({'current': normalized, 'max': 1.0});
            }
          } catch (e) {
            mainSendPort.send("Worker Error: ${e.toString()}");
          }
        }, onError: (err) {
          mainSendPort.send("WebSocket Error: ${err.toString()}");
        });
      } else if (command == WorkerCommand.stop) {
        subscription?.cancel();
        channel?.sink.close();
      }
    });
  }

  void dispose() {
    _sendPortToWorker?.send(WorkerCommand.stop);
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _dataController.close();
  }
}
