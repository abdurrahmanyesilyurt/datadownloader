import 'dart:async';
import 'dart:io';
import 'package:datadownloader/devicePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static bool isBluetoothConnected=false;

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1080, 2399),
      builder: (_ , child) {
        return MaterialApp(

          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFF252A34), // Arka plan rengi
          ),
          home: child,
        );
      },
      child: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late StreamSubscription<BluetoothAdapterState> subscription;
  bool isBluetoothEnabled = false;
  bool _isScanning = false;
  List<ScanResult> scanResultList = [];

  @override
  void initState() {
    super.initState();
    checkBluetoothSupportAndListenState();
  }

  @override
  void dispose() {
    subscription.cancel();
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

      if (state == BluetoothAdapterState.off) {
        showBluetoothOffSnackbar();
      }
    });
  }

  void showBluetoothOffSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Bluetooth Kapalı.Açmak ister misiniz?"),
        action: SnackBarAction(
          label: 'Aç',
          textColor: Colors.white,
          onPressed: () async {
            await FlutterBluePlus.turnOn();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void startScan() {
    if (!isBluetoothEnabled) return;

    scanResultList.clear();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 40));
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResultList = results.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
      });
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
      MyApp.isBluetoothConnected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding:  EdgeInsets.only(left: 89.w,top: 131.h),
                child: RichText(
                  text: TextSpan(
                    text: 'Bağlantı:',
                    style:  TextStyle(
                        fontSize: 45.sp,
                        fontFamily: 'Roboto Regular',
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: _isScanning&&isBluetoothEnabled ? 'Aranıyor...' : 'Kapalı',
                        style: TextStyle(
                          fontFamily: 'Roboto Regular',
                          fontWeight: FontWeight.bold,
                          fontSize: 45.sp,
                          color: _isScanning &&isBluetoothEnabled? const Color(0xFF12E200) : const Color(0xFFFF8F9F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:  EdgeInsets.only(left: 400.w,top: 121.h),
                child: Switch(
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey,
                  activeTrackColor: const Color(0xFF12E200),
                  value: isBluetoothEnabled && _isScanning,
                  onChanged: (bool value) async {
                    if (!isBluetoothEnabled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bluetooth Kapalı. Cihaz taraması yapmak için Açınız.'),
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
                      startScan();
                    } else {
                      stopScan();
                    }

                    setState(() {
                      _isScanning = value;
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h,),
          Padding(
            padding:  EdgeInsets.only(left: 89.w),
            child: RichText(
              text: TextSpan(
                text: 'Son indirme:',
                style:  TextStyle(
                    fontSize: 45.sp,
                    fontFamily: 'Roboto Regular',
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Bulunamadı.',
                    style: TextStyle(
                      fontFamily: 'Roboto Regular',
                      fontWeight: FontWeight.normal,
                      fontSize: 45.sp,
                      color: const Color(0xFFADB8C9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 127.h,),
          Padding(
            padding:  EdgeInsets.only(left: 242.w),
            child: Image.asset('resimler/img.png',
              height: 186.h,
              width: 597.w,
            ),
          ),//resim
          SizedBox(height: 101.h,),
          Padding(
            padding:  EdgeInsets.only(left: 72.w,),
            child: SizedBox(
              width: 937,
              child: Text(
                'Veri indirmek için EKG veri indirme \ncihazını data soketine takın\n '
                    'aşağıda gelen listeden cihazınızı seçin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto', // Roboto Regular
                  fontSize: 50.sp,
                  color: Colors.white, // Yazı rengi
                ),
              ),
            ),
          ),
          SizedBox(height: 38.h,),
          Padding(
            padding:  EdgeInsets.only(left: 72.w),
            child: Text(
              'Cihazın takılı olduğundan ve eşleştirme\n modunun açık olduğundan emin olun.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto', // Roboto Regular
                fontSize: 50.sp,
                color: const Color(0xFFADB8C9), // Özel renk
              ),
            ),
          ),
          SizedBox(height: 101.h,),
          Padding(
            padding:  EdgeInsets.only(left: 87.w),
            child: Text(
              'Bulunan Cihazlar',
              style: TextStyle(
                fontFamily: 'Roboto', // Roboto Regular
                fontSize: 60.sp,
                color: Colors.white, // Özel renk
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding:  EdgeInsets.only(left: 72.h),
                child: Column(
                  children: [
                    for (var result in scanResultList.where((result) => (result.device.platformName != null && result.device.platformName!.isNotEmpty)))
                      ListTile(
                        leading: Icon(
                          Icons.circle_outlined,
                          color: const Color(0xFFADB8C9),
                          size: 63.h,
                        ),
                        title: Text(result.device.platformName!,
                          style: TextStyle(
                              fontSize: 50.sp,
                              color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => DevicePageWidget(device: result.device),),);
                        },
                      ),
                    SizedBox(height: 77.h,),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding:  EdgeInsets.only(left:78.w,),
            child: Visibility(
              visible: _isScanning,
              child: Container(
                height: 91.h,
                width: 960.w,
                child: Row(
                  children: [
                    SizedBox(
                      width: 63.w,
                      height: 63.h,
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4AC8FF)),
                      ),
                    ),
                    SizedBox(width:31.w),
                    Text(
                      'Bluetooth cihazlar aranıyor...',
                      style: TextStyle(
                        fontSize: 50.sp,
                        color: const Color(0xFF4AC8FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Visibility(
            visible: _isScanning&&isBluetoothEnabled,
            child: Container(
              width: 937.w,
              height: 62.h,
              child: Text(
                'veya',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 50.sp,
                ),
              ),
            ),
          ),

          Visibility(
            visible: _isScanning && isBluetoothEnabled,
            child: OutlinedButton(
              onPressed: () {
                print('sd');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00B2FF),
                side: const BorderSide(color: Color(0xFF076EB9)),
                backgroundColor: const Color(0xFF252A34), // Arka plan rengi
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular((22.0).h), // Kenar kıvrımlılığı ayarlayabilirsiniz
                ),
              ),
              child:  Text('Otomatik Bağlantıyı Deneyin',textAlign:TextAlign.center,style: TextStyle(fontSize: 50.sp),),
            ),
          ),
          Padding(
            padding:  EdgeInsets.only(left: 72.w,),
            child: Visibility(
              visible: !isBluetoothEnabled,
              child:  Text(
                'Bluetooth kapalı.\nMobil aygıtınızda Bluetooth’u açın.',
                style: TextStyle(
                  fontFamily: 'Roboto', // Roboto Regular
                  fontSize: 50.sp,
                  color: const Color(0xFF0096D5), // Özel renk
                ),
              ),
            ),
          ),
        ],

      ),
    );
  }
}
