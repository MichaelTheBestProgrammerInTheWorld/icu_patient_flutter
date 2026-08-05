import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:waveform_flutter/waveform_flutter.dart';

class CoinbaseRepository {
  final String _url = 'wss://ws-feed.exchange.coinbase.com';
  WebSocketChannel? _channel;

  Stream<Amplitude> get tickerStream {
    _channel = WebSocketChannel.connect(Uri.parse(_url));
    
    final subscription = {
      "type": "subscribe",
      "channels": [
        {"name": "ticker", "product_ids": ["BTC-USD"]}
      ]
    };

    _channel!.sink.add(jsonEncode(subscription));

    return _channel!.stream.map((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'ticker' && data['price'] != null) {
        final price = double.tryParse(data['price']) ?? 0.0;
        // Normalize price to a 0.0 - 1.0 range for Amplitude.
        // BTC price is around 60k-70k, so we use a simple heuristic for simulation.
        // In a real app, we'd use a rolling window or fixed range.
        final normalized = (price % 100) / 100.0;
        return Amplitude(current: normalized, peak: 1.0);
      }
      return const Amplitude(current: 0.0, peak: 1.0);
    }).where((amp) => amp.current > 0);
  }

  void dispose() {
    _channel?.sink.close();
  }
}
