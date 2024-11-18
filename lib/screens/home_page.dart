import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/glass.dart';
import '../services/bluetooth_manager.dart';
import '../services/commands.dart';
import '../widgets/glass_status.dart';

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

  void _scanAndConnect() async {
    try {
      setState(() {
        leftStatus = 'Scanning...';
        rightStatus = 'Scanning...';
      });

      await bluetoothManager.startScanAndConnect(
        onGlassFound: (Glass glass) async {
          print('Glass found: ${glass.name} (${glass.side})');
          await _connectToGlass(glass);
        },
        onScanTimeout: (message) {
          print('Scan timeout: $message');
          setState(() {
            if (bluetoothManager.leftGlass == null) {
              leftStatus = 'Not Found';
            }
            if (bluetoothManager.rightGlass == null) {
              rightStatus = 'Not Found';
            }
          });
        },
        onScanError: (error) {
          print('Scan error: $error');
          setState(() {
            leftStatus = 'Scan Error';
            rightStatus = 'Scan Error';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scan error: $error')),
          );
        },
      );
    } catch (e) {
      print('Error in _scanAndConnect: $e');
      setState(() {
        leftStatus = 'Error';
        rightStatus = 'Error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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

  if (bluetoothManager.leftGlass != null && bluetoothManager.rightGlass != null) {
    await sendTextPacket(textMessage: text, bluetoothManager: bluetoothManager);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Glasses are not connected')),
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