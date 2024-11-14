import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../models/glass.dart';
import '../services/bluetooth_manager.dart';
import '../services/commands.dart';
import '../widgets/glass_status.dart';
import '../providers/glass_provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final BluetoothManager bluetoothManager = BluetoothManager();
  final TextEditingController _textController = TextEditingController();

  // Variables to hold connection status
  String leftStatus = 'Disconnected';
  String rightStatus = 'Disconnected';

  @override
  void initState() {
    super.initState();
    // Optionally initiate scan here or via button
  }

  Future<void> _requestPermissions() async {
    // Your existing permission request logic
  }

  void _scanAndConnect() {
    setState(() {
      leftStatus = 'Scanning...';
      rightStatus = 'Scanning...';
    });

    bluetoothManager.startScanAndConnect(
      onGlassFound: (Glass glass) {
        _connectToGlass(glass);
      },
      onScanTimeout: (message) {
        setState(() {
          leftStatus = 'Scan Timeout';
          rightStatus = 'Scan Timeout';
        });
      },
      onScanError: (error) {
        setState(() {
          leftStatus = 'Scan Error';
          rightStatus = 'Scan Error';
        });
      },
    );
  }

  Future<void> _connectToGlass(Glass glass) async {
    await glass.connect();
    setState(() {
      if (glass.side == 'left') {
        leftStatus = 'Connecting...';
      } else {
        rightStatus = 'Connecting...';
      }
    });

    // Monitor connection
    glass.device.connectionState.listen((BluetoothConnectionState state) {
      if (glass.side == 'left') {
        leftStatus = state.toString().split('.').last;
      } else {
        rightStatus = state.toString().split('.').last;
      }
      setState(() {}); // Update the UI
      print('[${glass.side} Glass] Connection state: $state');
      if (state == BluetoothConnectionState.disconnected) {
        print('[${glass.side} Glass] Disconnected, attempting to reconnect...');
        setState(() {
          if (glass.side == 'left') {
            leftStatus = 'Reconnecting...';
          } else {
            rightStatus = 'Reconnecting...';
          }
        });
        _reconnectGlass(glass);
      }
    });
  }

  Future<void> _reconnectGlass(Glass glass) async {
    try {
      await glass.connect();
      print('[${glass.side} Glass] Reconnected.');
      setState(() {
        if (glass.side == 'left') {
          leftStatus = 'Connected';
        } else {
          rightStatus = 'Connected';
        }
      });
    } catch (e) {
      print('[${glass.side} Glass] Reconnection failed: $e');
      setState(() {
        if (glass.side == 'left') {
          leftStatus = 'Disconnected';
        } else {
          rightStatus = 'Disconnected';
        }
      });
    }
  }

  void _sendText() async {
    String text = _textController.text;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text to send')),
      );
      return;
    }

    // Construct SendResult packet
    SendResult sendResult = SendResult(
      command: Command.SEND_RESULT,
      data: utf8.encode(text),
    );

    List<int> packet = sendResult.build();

    if (bluetoothManager.leftGlass != null && bluetoothManager.leftGlass!.uartTx != null) {
      await bluetoothManager.leftGlass!.sendData(packet);
    } else {
      print('[left Glass] Not connected or UART TX not available.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Left Glass is not connected')),
      );
    }

    if (bluetoothManager.rightGlass != null && bluetoothManager.rightGlass!.uartTx != null) {
      await bluetoothManager.rightGlass!.sendData(packet);
    } else {
      print('[right Glass] Not connected or UART TX not available.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Right Glass is not connected')),
      );
    }
  }

  @override
  void dispose() {
    bluetoothManager.leftGlass?.disconnect();
    bluetoothManager.rightGlass?.disconnect();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glassProvider = Provider.of<GlassProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _scanAndConnect,
              child: const Text('Connect'),
            ),
            const SizedBox(height: 20),
            // Display connection statuses using GlassStatus widget and Provider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlassStatus(side: 'Left', status: leftStatus),
                GlassStatus(side: 'Right', status: rightStatus),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter text to send',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendText,
              child: const Text('Send Text'),
            ),
          ],
        ),
      ),
    );
  }
}