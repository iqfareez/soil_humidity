import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:lottie/lottie.dart';
import 'package:soil_humidity_app/bluetooth_devices.dart';
import 'package:soil_humidity_app/percent_indicator.dart';

enum BluetoothConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothConnectionState _btStatus = BluetoothConnectionState.disconnected;
  BluetoothConnection? connection;
  String _messageBuffer = '';
  double? percentValue;
  bool _isWatering = false;

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    var message = '';
    if (~index != 0) {
      message = backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString.substring(0, index);
      _messageBuffer = dataString.substring(index);
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }

    // calculate percentage from message
    // analog 10 bit
    if (message.isEmpty) return; // to avoid fomrmat exception
    double? analogMessage = double.tryParse(message.trim());
    setState(() {
      percentValue = (analogMessage ?? 0) / 1023;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_bluetooth),
            onPressed: () async {
              BluetoothDevice? device = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BluetoothDevices()));

              if (device == null) return;

              print('Connecting to device...');
              setState(() {
                _btStatus = BluetoothConnectionState.connecting;
              });

              BluetoothConnection.toAddress(device.address).then((_connection) {
                print('Connected to the device');
                connection = _connection;
                setState(() {
                  _btStatus = BluetoothConnectionState.connected;
                });

                connection!.input!.listen(_onDataReceived).onDone(() {
                  setState(() {
                    _btStatus = BluetoothConnectionState.disconnected;
                  });
                });
              }).catchError((error) {
                print('Cannot connect, exception occured');
                print(error);

                setState(() {
                  _btStatus = BluetoothConnectionState.error;
                });
              });
            },
          ),
        ],
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                switch (_btStatus) {
                  case BluetoothConnectionState.disconnected:
                    return const PercentIndicator.disconnected();
                  case BluetoothConnectionState.connecting:
                    return PercentIndicator.connecting();
                  case BluetoothConnectionState.connected:
                    return PercentIndicator.connected(percent: percentValue);
                  case BluetoothConnectionState.error:
                    return const PercentIndicator.error();
                }
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                String text = 'water';

                setState(() => _isWatering = true);

                if (text.isNotEmpty) {
                  try {
                    connection!.output
                        .add(Uint8List.fromList(utf8.encode("$text\r\n")));
                    await connection!.output.allSent;
                  } finally {
                    Future.delayed(const Duration(seconds: 4), () {
                      setState(() => _isWatering = false);
                    });
                  }
                }
              },
              child: const Text('Water my plant'),
            ),
            const Spacer(),
            SizedBox(
              height: 300,
              child: Builder(
                builder: (context) {
                  if (_isWatering) {
                    return Lottie.asset(
                        'assets/lottie/90819-watering-garden-icon.json');
                  }

                  if (percentValue == null) {
                    return const SizedBox.shrink();
                  }
                  if (percentValue! > 0.7) {
                    return Lottie.asset(
                        'assets/lottie/62044-smart-flowerpot-full-of-water.json');
                  } else if (percentValue! < 0.2) {
                    return Lottie.asset(
                        'assets/lottie/62395-smart-flowerpot-need-water.json');
                  } else {
                    return Lottie.asset(
                        'assets/lottie/61698-smart-flowerpot-sunbath.json');
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
