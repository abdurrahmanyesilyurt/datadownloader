import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  bool isBluetoothEnabled = true;
  bool _isScanning = true;
  BluetoothCharacteristic? targetCharacteristic;
  Map<String, List<int>> notifyDatas = {};


  @override
  void initState() {
    super.initState();
    _stateListener = widget.device.connectionState.listen((event) {
      if (deviceState != event) {
        setState(() {
          deviceState = event;
        });
      }
    });
    connect();
  }


  Future<bool> connect() async {
    Future<bool>? returnValue;
    setState(() {});
    print('${widget.device.mtuNow}');
    await widget.device
        .connect(autoConnect: false) // autoConnect burada kullanılıyor
        .timeout(const Duration(minutes: 1), onTimeout: () {
      returnValue = Future.value(false);
    }).then((data) async {
      bluetoothService.clear();
      if (returnValue == null) {
        List<BluetoothService> bleServices =
        await widget.device.discoverServices();
        setState(() {
          bluetoothService = bleServices;
          targetCharacteristic = bluetoothService[3].characteristics[0];
        });
        print('target karakteristik: $targetCharacteristic');

        if (targetCharacteristic!.properties.notify && targetCharacteristic!.descriptors.isNotEmpty) {
          if (!targetCharacteristic!.isNotifying) {
            try {
              await targetCharacteristic?.setNotifyValue(true);
              notifyDatas[targetCharacteristic!.uuid.toString()] = List.empty();
              targetCharacteristic?.lastValueStream.listen((value) {
                setState(() {
                  List<int> existingData = notifyDatas[targetCharacteristic!.uuid.toString()] ?? [];
                  notifyDatas[targetCharacteristic!.uuid.toString()] = [...existingData, ...value];
                });
                print('Yeni veri alındı: $value'); // Yeni veriyi konsola yazdır
              });
              await Future.delayed(const Duration(milliseconds: 500));
            } catch (e) {
              print('error ${targetCharacteristic?.uuid} $e');
            }
          }
        }
        returnValue = Future.value(true);
      }
    });

    return returnValue ?? Future.value(false);
  }
  @override
  void dispose() {
    _stateListener?.cancel();
    disconnect();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void disconnect() {
    try {
      widget.device.disconnect();
      MyApp.isBluetoothConnected = false; // Bağlantı kesildiğinde değişkeni güncelle

    } catch (e) {}
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 80.0,
            left: 30.0,
            child: RichText(
              text: TextSpan(
                text: 'Bağlantı:  ',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: deviceState==BluetoothConnectionState.connected ? widget.device.platformName : 'Bağlanıyor...',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color:  Color(0xFF12E200) , // Choose the appropriate color
                    ),
                  ),
                ],
              ),

            ),
          ),
          Positioned(
            top: 60.0,
            right: 20.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Switch(
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey,
                activeTrackColor: const Color(0xFF12E200),
                value:deviceState==BluetoothConnectionState.connected,
                onChanged: (bool value) async {
                  if (Platform.isAndroid) {
                    if (value) {
                      await FlutterBluePlus.stopScan();
                    } else {
                      disconnect();
                      Navigator.pop(context);
                    }
                  }

                  setState(() {
                    _isScanning = value;
                  });
                },
              ),
            ),
          ),


          const Positioned(
            top: 105.0,
            right: 177.0,
            child: Text(
              'Son indirme : Bulunamadı.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w100,
              ),
            ),
          ),
          Positioned(
            top: 45.0,
            left: 150.0,
            child: Center( // Resmi yatay olarak ortalar
              child: Image.asset('resimler/img_2.png',
                width: 75, // Resmin genişliği
                height: 300, // Resmin yüksekliği
              ),
            ),
          ),
          Positioned(
            top: 130.0,
            left: 100.0,
            child: Center( // Resmi yatay olarak ortalar
              child: Image.asset('resimler/img_5.png',
                width: 150, // Resmin genişliği
                height: 300, // Resmin yüksekliği
              ),
            ),
          ),

          const Positioned(
            top: 340.0,
            left: 30,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Verilerin her 4 saatte bir indirilmesi ve\n sorumlu görevli tarafından 1 yıl süreyle \nsaklanması gereklidir.',
                style: TextStyle(
                  fontFamily: 'Roboto', // Roboto Regular
                  fontSize: 16,
                  color: Color(0xFFADB8C9), // Özel renk
                ),
              ),
            ),
          ),
          Positioned(
            top: 420.0,
            left: 45,
            child: Visibility(
              visible: _isScanning && isBluetoothEnabled,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  width: 300.0, // İstenilen genişliği ayarlayabilirsiniz.
                  child: OutlinedButton(
                    onPressed: () {
                      print('sd');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00B2FF),
                      side: const BorderSide(color: Color(0xFF076EB9)),
                      backgroundColor: const Color(0xFF00B2FF), // Arka plan rengi,
                    ),
                    child: const Text('Veri indir',style: TextStyle(fontSize: 18,color: Colors.white),),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 560.0,
            left: 30,
            child: Padding(
              padding: EdgeInsets.only(top: 20.0,right: 180.0),
              child: Text(
                'Önceki indirmeler',
                style: TextStyle(
                  fontFamily: 'Roboto', // Roboto Regular
                  fontSize: 18,
                  color: Colors.white, // Özel renk
                ),
              ),
            ),
          ),
          Positioned(
            top: 580.0,
            left: 15,
            child: SizedBox(
              height: 250.0,
              width: 400.0,
              child: ListView.builder(
                shrinkWrap: true,
                itemExtent: 40.0, // Her öğe için sabit yükseklik
                itemCount: 1,
                itemBuilder: (context, index) {
                  return const ListTile(
                    leading: Icon(Icons.download, color: Color(0xFFADB8C9), size: 25.0),
                    title: Padding(
                      padding: EdgeInsets.only(right: 8.0), // Yazıdan önceki boşluğu ayarlar
                      child: Text(
                        'Kayıt Yok',
                        style: TextStyle(
                          fontSize: 16,
                          color:Color(0xFFADB8C9),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        ],
      ),
    );
  }
}
