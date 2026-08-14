import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:waveform_flutter/waveform_flutter.dart';

/// Commands sent from Main Isolate to Worker Isolate
enum WorkerCommand { start, stop }

enum WorkerState {
  stopped,
  starting,
  ready,
  streaming,
  exited,
}

class CoinbaseRepository {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPortToWorker;
  
  // FIX: Don't close the controller in stop(), only in dispose()
  late StreamController<Amplitude> _dataController;

  // Synchronization to prevent multiple concurrent initializations
  Completer<void>? _initCompleter;

  WorkerState _workerState = WorkerState.stopped;
  bool get isWorkerHealthy {
    return _workerState == WorkerState.ready ||
        _workerState == WorkerState.streaming;
  }

  CoinbaseRepository() {
    _dataController = StreamController<Amplitude>.broadcast();
  }

  Stream<Amplitude> get tickerStream {
    // Lazy start only when the stream is requested
    return _dataController.stream;
  }

  /// Explicitly starts/stops the stream without killing the isolate
  Future<void> setStreaming(bool active) async {
    if (active) {
      print(
          'STREAM START -> isolate=${_isolate != null}, '
          'sendPort=${_sendPortToWorker != null}'
      );
      await _startIsolate(); // Isolate creation is now synchronized
      _sendPortToWorker?.send(WorkerCommand.start);
    } else {
      _updateWorkerState(
          WorkerState.ready,
      );
      _sendPortToWorker?.send(WorkerCommand.stop);
    }
  }

  Future<void> _startIsolate() async {
    // 1. If already fully initialized, just ensure it's started
    if (_isolate != null && isWorkerHealthy) {
      print("Existing isolate detected");
      print("Sending START to existing worker");
      _sendPortToWorker?.send(WorkerCommand.start);
      _updateWorkerState(
          WorkerState.streaming,
      );
      return;
    }
    // if (_isolate != null) {
    //   print("KILLING OLD ISOLATE");
    //
    //   _receivePort?.close();
    //   _isolate?.kill(priority: Isolate.immediate);
    //
    //   _isolate = null;
    //   _sendPortToWorker = null;
    //   _initCompleter = null;
    // }


    // 2. If initialization is already in progress, wait for it
    if (_initCompleter != null) {
      await _initCompleter!.future;
      _sendPortToWorker?.send(WorkerCommand.start);
      return;
    }

    // 3. Start initialization
    _initCompleter = Completer<void>();

    _updateWorkerState(
      WorkerState.starting,
    );
    
    try {
      _receivePort = ReceivePort();
      final errorPort = ReceivePort();
      errorPort.listen((error) {
        print('ISOLATE ERROR: $error');
      });
      final exitPort = ReceivePort();
      exitPort.listen((_) {
        print("Worker exited");
        _updateWorkerState(
            WorkerState.exited,
        );
        _recreateWorker();
      });

      _isolate = await Isolate.spawn(
        _workerEntryPoint,
        _receivePort!.sendPort,
        onError: errorPort.sendPort,
        onExit: exitPort.sendPort,
      );
      //_isolate = await Isolate.spawn(_workerEntryPoint, _receivePort!.sendPort);

      _receivePort!.listen((message) {
        if (message is SendPort) {
          _sendPortToWorker = message;
          _updateWorkerState(
              WorkerState.ready,
          );
          _sendPortToWorker!.send(WorkerCommand.start);
          _updateWorkerState(
              WorkerState.streaming,
          );
          if (!_initCompleter!.isCompleted) {
            _initCompleter!.complete();
          }
        } else if (message is Map<String, dynamic>) {
          if (!_dataController.isClosed) {
            final current = message['current'] as double;
            final max = message['max'] as double;
            _dataController.add(Amplitude(current: current, max: max));
          }
        } else if (message is String) {
          if (!_dataController.isClosed) {
            _dataController.addError(message);
          }
        }
      }, onDone: () {
        _isolate = null;
        _initCompleter = null;
      });
    } catch (e) {
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.completeError(e);
      }
      _initCompleter = null;
      rethrow;
    }
  }

  static void _workerEntryPoint(SendPort mainSendPort) {
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    WebSocketChannel? channel;
    StreamSubscription? subscription;

    workerReceivePort.listen((command) {
      print("Worker received command: $command");
      if (command == WorkerCommand.start) {
        // Prevent multiple simultaneous connections
        if (subscription != null) return;

        print("Worker received START");

        channel = WebSocketChannel.connect(Uri.parse('wss://ws-feed.exchange.coinbase.com'));

        print("WebSocket connected");

        final subscriptionMsg = {
          "type": "subscribe",
          "channels": [
            {"name": "ticker", "product_ids": ["BTC-USD"]}
          ]
        };
        channel!.sink.add(jsonEncode(subscriptionMsg));

        subscription = channel!.stream.listen((message) {
          try {
            final data = jsonDecode(message);
            print("Ticker received");
            if (data['type'] == 'ticker' && data['price'] != null) {
              final price = double.tryParse(data['price']) ?? 0.0;
              final normalized = (price % 100) / 100.0;
              mainSendPort.send({'current': normalized, 'max': 1.0});
            }
          } catch (e) {
            print("Worker Error: $e");
            mainSendPort.send("Worker Error: ${e.toString()}");
          }
        }, onError: (err) {
          print("WebSocket Error: $err");
          subscription = null;
          channel?.sink.close();
          channel = null;
          mainSendPort.send("WebSocket Error: ${err.toString()}");
        },
          onDone: () {
            subscription = null;
            channel = null;
            mainSendPort.send("WebSocket Connection Closed");
          },
        );
      } else if (command == WorkerCommand.stop) {
        subscription?.cancel();
        subscription = null;
        channel?.sink.close();
        channel = null;
      }
    });
  }

  void _updateWorkerState(WorkerState state) {
    _workerState = state;
    print(
      'WorkerState -> ${state.name}',
    );
  }

  void _recreateWorker(){
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);

    _isolate = null;
    _sendPortToWorker = null;
    _initCompleter = null;

    _updateWorkerState(
        WorkerState.stopped,
    );
  }

  void dispose() {
    _sendPortToWorker?.send(WorkerCommand.stop);
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _initCompleter = null;
    if (!_dataController.isClosed) {
      _dataController.close();
    }
  }
}
