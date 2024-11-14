import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';
import '../models/glass.dart';

// Define callback types for clarity
typedef OnGlassFound = void Function(Glass);
typedef OnScanTimeout = void Function(String);
typedef OnScanError = void Function(String);

class BluetoothManager {
  Glass? leftGlass;
  Glass? rightGlass;

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetooth]!.isDenied ||
        statuses[Permission.bluetoothScan]!.isDenied ||
        statuses[Permission.bluetoothConnect]!.isDenied ||
        statuses[Permission.location]!.isDenied) {
      // Permissions are denied, show a message and exit
      throw Exception('Permissions are required to use Bluetooth');
    }
  }

  void startScanAndConnect({
    required OnGlassFound onGlassFound,
    required OnScanTimeout onScanTimeout,
    required OnScanError onScanError,
  }) async {
    await _requestPermissions();

    // Start scanning for devices
    FlutterBluePlus.startScan(
      timeout: Duration(seconds: 10),
    ).then((_) {
      print('Scanning started');
    }).catchError((error) {
      print('Error starting scan: $error');
      onScanError('Failed to start scan: $error');
    });

    // Listen to scan results with additional logs
    FlutterBluePlus.scanResults.listen((results) {
      print('Scan started, listening for results...');
      for (ScanResult result in results) {
        String deviceName = result.device.name;
        String deviceId = result.device.id.id;
        print('Found device: $deviceName with ID: $deviceId');

        if (deviceName.contains('_L_') && leftGlass == null) {
          // Connect to Left Glass
          Glass glass = Glass(
            name: deviceName,
            device: result.device,
            side: 'left',
            onLeftStatusChanged: (status) {
              // Handle left status changes if needed
            },
            onRightStatusChanged: (status) {
              // Handle right status changes if needed
            },
          );
          leftGlass = glass;
          onGlassFound(glass);
        } else if (deviceName.contains('_R_') && rightGlass == null) {
          // Connect to Right Glass
          Glass glass = Glass(
            name: deviceName,
            device: result.device,
            side: 'right',
            onLeftStatusChanged: (status) {
              // Handle left status changes if needed
            },
            onRightStatusChanged: (status) {
              // Handle right status changes if needed
            },
          );
          rightGlass = glass;
          onGlassFound(glass);
        }

        if (leftGlass != null && rightGlass != null) {
          FlutterBluePlus.stopScan();
          print('Both glasses found. Stopping scan.');
          break;
        }
      }
    }, onError: (error) {
      print('Scan error: $error');
      onScanError('Scan error: $error');
    });

    // Listen to scanning state with logs
    FlutterBluePlus.isScanning.listen((isScanning) {
      print('Is scanning: $isScanning');
      if (!isScanning) {
        print('Scan completed');
        onScanTimeout('Scan completed');
      }
    });
  }

  Future<void> connectToDevice(BluetoothDevice device, {required String side}) async {
    try {
      await device.connect();
      print('Connected to $side glass: ${device.name}');

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == BluetoothConstants.UART_SERVICE_UUID) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() == BluetoothConstants.UART_TX_CHAR_UUID) {
              // Handle TX Characteristic
            } else if (characteristic.uuid.toString().toUpperCase() == BluetoothConstants.UART_RX_CHAR_UUID) {
              // Handle RX Characteristic
            }
          }
        }
      }
    } catch (e) {
      print('Error connecting to $side glass: $e');
      await device.disconnect();
    }
  }

  void stopScanning() {
    FlutterBluePlus.stopScan().then((_) {
      print('Stopped scanning');
    }).catchError((error) {
      print('Error stopping scan: $error');
    });
  }
}