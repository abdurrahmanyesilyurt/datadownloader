import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'main.dart';


class DevicePageWidget extends StatefulWidget {
  final BluetoothDevice device;

  const DevicePageWidget({Key? key, required this.device}) : super(key: key);

  @override
  State<DevicePageWidget> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePageWidget> {
  BluetoothConnectionState deviceState = BluetoothConnectionState.disconnected;
  StreamSubscription<BluetoothConnectionState>? _stateListener;
  List<BluetoothService> bluetoothService = [];
  late StreamSubscription<BluetoothAdapterState> subscription;
  bool isBluetoothEnabled = MyApp.isBluetoothEnabled;
  bool _isScanning = MyApp.isScanning;
  Map<String, List<int>> notifyDatas = {};
  StreamController<List<int>> _dataStreamController = StreamController<List<int>>.broadcast();
  Map<String, List<int>> gelenveri = {};



  @override
  void initState() {
    super.initState();
    checkBluetoothSupportAndListenState();
    _stateListener = widget.device.connectionState.listen((event) {
      if (deviceState != event) {
        setState(() {
          deviceState = event;
        });
      }
      connect();
    });
  }
  Future<bool> connect() async {
    Future<bool>? returnValue;
    setState(() {});
    print('${widget.device.mtuNow}');
    print('Connecting to ${widget.device.platformName}...');
    await widget.device.connect(autoConnect: false).timeout(const Duration(minutes: 1), onTimeout: () {
      returnValue = Future.value(false);
    }).then((data) async {
      await widget.device.requestMtu(260).then((mtu) {
      });
      bluetoothService.clear();
      if (returnValue == null) {
        List<BluetoothService> bleServices =
        await widget.device.discoverServices();
        setState(() {
          bluetoothService = bleServices;
        });

        returnValue = Future.value(true);
      }
    });
    print('Connected to ${widget.device.platformName}');
    return returnValue ?? Future.value(false);
  }


  @override
  void dispose() {
    _dataStreamController.close();
    _stateListener?.cancel();
    disconnect();
    FlutterBluePlus.stopScan();
    super.dispose();
  }
  void checkBluetoothSupportAndListenState() async {
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }

    subscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        isBluetoothEnabled = state == BluetoothAdapterState.on;
      });
    });
  }
  void readCharacteristic(BluetoothCharacteristic characteristic) async {
    try {
      List<int> value = await characteristic.read();
      print('Read Value: $value');
      setState(() {
        notifyDatas[characteristic.uuid.toString()] = value;
      });
    } catch (e) {
      print('Read error: $e');
    }
  }


  void writeCharacteristic(BluetoothCharacteristic characteristic, String value) async {
    try {
      List<int> bytes = value.codeUnits;
      await characteristic.write(bytes);
      print('Write Successful');
      // Implement your logic to handle the successful write
    } catch (e) {
      print('Write error: $e');
    }
  }
  void enableNotify(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    characteristic.lastValueStream.listen((value) {
      setState(() {
        notifyDatas[characteristic.uuid.toString()] = value;
      });
    });
  }


  void disconnect() {
    try {
      widget.device.disconnect();
      MyApp.isBluetoothConnected = false; // Bağlantı kesildiğinde değişkeni güncelle

    } catch (e) {}
  }
  String _truncateDeviceName(String deviceName) {
    const maxLength = 12; // Choose a suitable maximum length
    return deviceName.length > maxLength
        ? '${deviceName.substring(0, maxLength)}...'
        : deviceName;
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body:dikey(),
      ),
    );

  }Widget dikey(){
    return   Column(
      children: [
        Row(
          children: [
            Padding(
              padding:  EdgeInsets.only(left: 89.w,top: 45.h),
              child: RichText(
                text: TextSpan(
                  text: 'Bağlantı: ',
                  style:  TextStyle(
                      fontSize: 45.sp,
                      fontFamily: 'Roboto Regular',
                      color: Colors.white,
                      fontWeight: FontWeight.w700
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: deviceState == BluetoothConnectionState.connected
                          ? _truncateDeviceName(widget.device.platformName)
                          : 'Bağlanıyor...',
                      style: TextStyle(
                        fontFamily: 'Roboto Regular',
                        fontWeight: FontWeight.bold,
                        fontSize: 45.sp,
                        color: _isScanning && isBluetoothEnabled
                            ? const Color(0xFFFF8F9F)
                            : const Color(0xFF12E200),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height:20.h),
            Padding(
              padding:  EdgeInsets.only(left: 420.w,top: 20.h),
              child: Switch(
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey,
                activeTrackColor: const Color(0xFF12E200),
                value:deviceState==BluetoothConnectionState.connected,
                onChanged: (bool value) async {
                  if (!isBluetoothEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bluetooth Kapalı. Cihaz taraması yapmak için Açınız. '),
                      ),
                    );
                    return;
                  }

                  if (Platform.isAndroid) {
                    if (value) {
                      await FlutterBluePlus.startScan();
                    } else if (!value) {
                      await FlutterBluePlus.stopScan();
                    }
                  }

                  if (value && isBluetoothEnabled) {
                    await FlutterBluePlus.stopScan();
                  } else {
                    Navigator.pop(context);
                  }

                  setState(() {
                    _isScanning = value;
                  });
                },
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 20.w),
          child: SizedBox(
            height: 1700.0.h,
            width: 1000.0.w,
            child: ListView.builder(
              itemCount: bluetoothService.length,
              itemBuilder: (context, index) {
                BluetoothService service = bluetoothService[index];
                return ExpansionTile(
                  title: Text(
                    'Service: ${service.uuid}',
                    style: TextStyle(color: Colors.white),
                  ),
                  children: service.characteristics
                      .map((characteristic) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          'Characteristic: ${characteristic.uuid}',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Properties: ${characteristic.properties}\n',
                              style: TextStyle(color: Colors.white),
                            ),
                            if (characteristic.properties.read)
                              Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      readCharacteristic(characteristic);
                                    },
                                    child: const Text('Read'),
                                  ),
                                  if (notifyDatas.containsKey(characteristic.uuid.toString()))
                                    Text(
                                      'Read Value: ${notifyDatas[characteristic.uuid.toString()]}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                ],
                              ),
                            if (characteristic.properties.write) // Add a Write text field and button
                              Column(
                                children: [
                                  TextField(
                                    controller:
                                    TextEditingController(), // You may need to create a TextEditingController and use it here
                                    decoration: InputDecoration(
                                      labelText: 'Write Value',
                                      labelStyle: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      String value = 'YourValue';
                                      writeCharacteristic(characteristic, value);
                                    },
                                    child: Text('Write'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Divider(
                        color: Colors.white,
                      ),
                    ],
                  ))
                      .toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
