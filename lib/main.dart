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
  static bool isScanning = false;
  static bool isBluetoothEnabled=false;
  static bool isSwitchLocked=false;
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: _getDesignSize(context),
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
  Size _getDesignSize(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait
        ? const Size(1080, 2399)
        : const Size(2399, 1080);
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late StreamSubscription<BluetoothAdapterState> subscription;
  bool isBluetoothEnabled = MyApp.isBluetoothEnabled;
  bool _isScanning=MyApp.isScanning;
  List<ScanResult> scanResultList = [];
  int sayac = 0;
  bool _isSwitchLocked = MyApp.isSwitchLocked;

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
    _lockSwitch();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 60));
    _unlockSwitch();
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResultList = results.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
      });
    });
  }
  void _lockSwitch() {
    setState(() {
      _isSwitchLocked = true;
    });
  }

  void _unlockSwitch() {
    setState(() {
      _isSwitchLocked = false;
    });
  }
  void stopScan() {
    _lockSwitch();
    FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
      isBluetoothEnabled = false;
      scanResultList.clear();
    });
    _unlockSwitch();



    FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        isBluetoothEnabled = state == BluetoothAdapterState.on;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    sayac = scanResultList.where((result) => result.device.platformName != null && result.device.platformName!.isNotEmpty).length;
    final orientation = MediaQuery.of(context).orientation;
    return SafeArea(
      child: Scaffold(
        body:OrientationBuilder(
          builder: (context,orientation){
            return orientation==Orientation.portrait
                ? dikey()
                :yatay();
          },
        ),
      ),
    );
  }
  Widget yatay(){
    return  Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Padding(
                padding:  EdgeInsets.only(top: 45.h,right: 710.w),
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
              SizedBox(height:100.h),
              Padding(
                padding:  EdgeInsets.only(left: 160.w),
                child: Icon(
                  Icons.bluetooth_audio,
                  size: 200.h,
                  color: Colors.white,
                ),
              ),//resim
              SizedBox(height:100.h),
              Padding(
                padding:  EdgeInsets.only(left: 50.w,),
                child:RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Roboto Regular',
                      fontSize: 50.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      const TextSpan(
                        text: ' Veri göndermek için BLE cihazınızın\n',
                      ),
                      WidgetSpan(
                        child: SizedBox(height: 65.h), // İstediğiniz boşluğu ayarlayabilirsiniz.
                      ),
                      const TextSpan(
                          text: 'açık ve tarama durumunda \n'
                      ),
                      WidgetSpan(
                        child: SizedBox(height: 64.h), // İstediğiniz boşluğu ayarlayabilirsiniz.
                      ),
                      const TextSpan(
                        text: ' olduğuna emin olun.',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:  EdgeInsets.only(left: 50.w,top: 38.h),
                child:RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Roboto Regular',
                      fontSize: 50.sp,
                      color: const Color(0xFFADB8C9),
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Taramada bluetooth low energy teknolojisi\n',
                      ),
                      WidgetSpan(
                        child: SizedBox(height: 63.h), // İstediğiniz boşluğu ayarlayabilirsiniz.
                      ),
                      const TextSpan(
                          text: 'içermeyen cihazlar gözükmez.\n'
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding:  EdgeInsets.only(left: 87.w),
                    child: Text(
                      'Bulunan cihazlar',
                      style: TextStyle(
                        fontFamily: 'Roboto', // Roboto Regular
                        fontSize: 45.sp,
                        color: Colors.white, // Özel renk
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding:  EdgeInsets.only(left: 500.w,top: 30.h),
                    child: Switch(
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
                      activeTrackColor: const Color(0xFF12E200),
                      value: isBluetoothEnabled && _isScanning,
                      onChanged: (bool value) async {
                        if (!isBluetoothEnabled) {
                          _unlockSwitch();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bluetooth Kapalı. Cihaz taraması yapmak için Açınız.'),
                            ),
                          );
                          return;
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
              Padding(
                padding:  EdgeInsets.only(right: 180.w),
                child: SizedBox(
                  height: isBluetoothEnabled ? 0 : 200.h, // Set the height to 0 when not visible
                  width: isBluetoothEnabled ? 0 : 900.w,
                  child: Visibility(
                    visible: !isBluetoothEnabled,
                    child: Text(
                      'Bluetooth kapalı.\nMobil aygıtınızda Bluetooth’u açın.',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.blueAccent,
                        fontSize: 45.sp,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h,),
              Expanded(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(), // Sürükleme fiziksel davranışını belirle
                  children: [
                    SizedBox(
                      height: sayac > 5 ? 600.h : (sayac * 120).h,
                      child:ListView.builder(
                        itemExtent: 120.0.h, // Itemler arasındaki sabit boşluğu belirleyin
                        itemCount: sayac,
                        itemBuilder: (BuildContext context, int index) {
                          var filteredList = scanResultList.where((result) => result.device.platformName != null && result.device.platformName!.isNotEmpty).toList();
                          var result = filteredList[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 85.0.w),
                            leading: Icon(
                              Icons.circle_outlined,
                              color: const Color(0xFFADB8C9),
                              size: 75.sp,
                            ),
                            title: Text(
                              result.device.platformName!,
                              style: TextStyle(
                                fontSize: 45.sp,
                                color: Colors.white,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DevicePageWidget(device: result.device),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding:  EdgeInsets.only(left:95.w,bottom: 120.h,top: 20.h),
                      child: Visibility(
                        visible: _isScanning,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60.sp,
                              height: 60.sp,
                              child: const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4AC8FF)),
                              ),
                            ),
                            SizedBox(width:40.w),
                            Text(
                              'Bluetooth cihazlar aranıyor...',
                              style: TextStyle(
                                fontSize: 45.sp,
                                color: const Color(0xFF4AC8FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),



            ],
          ),
        ),

      ],

    );
  }
  Widget dikey(){
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            SizedBox(height:20.h),

            Padding(
              padding:  EdgeInsets.only(left: 400.w,top: 20.h),
              child: Switch(
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey,
                activeTrackColor: const Color(0xFF12E200),
                value: isBluetoothEnabled && _isScanning,
                onChanged: (bool value) async {
                  if (_isSwitchLocked) {
                    return;
                  }
                  _lockSwitch(); // Anahtarı kilitle
                  if (!isBluetoothEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bluetooth Kapalı. Cihaz taraması yapmak için Açınız.'),
                      ),
                    );
                    return;
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
        SizedBox(height: 121.h,),
        Padding(
          padding: EdgeInsets.only(left: 450.w),
          child: Icon(
            Icons.bluetooth,
            size: 200.h,
            color: Colors.blueAccent,
          ),
        ),

        SizedBox(height: 108.h,),
        Padding(
          padding:  EdgeInsets.only(left: 100.w,),
          child:RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Roboto Regular',
                fontSize: 50.sp,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
              children: [
                const TextSpan(
                  text: ' Veri göndermek için BLE cihazınızın\n',
                ),
                WidgetSpan(
                  child: SizedBox(height: 65.h), // İstediğiniz boşluğu ayarlayabilirsiniz.
                ),
                const TextSpan(
                    text: 'açık ve tarama durumunda \n'
                ),
                WidgetSpan(
                  child: SizedBox(height: 64.h), // İstediğiniz boşluğu ayarlayabilirsiniz.
                ),
                const TextSpan(
                  text: ' olduğuna emin olun.',
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding:  EdgeInsets.only(left: 90.w,top: 38.h),
          child:RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Roboto Regular',
                fontSize: 50.sp,
                color: const Color(0xFFADB8C9),
                fontWeight: FontWeight.w400,
              ),
              children: [
                const TextSpan(
                  text: 'Taramada bluetooth low energy teknolojisi\n',
                ),
                WidgetSpan(
                  child: SizedBox(height: 63.h), // İstediğiniz boşluğu ayarlayabilirsiniz.
                ),
                const TextSpan(
                    text: 'içermeyen cihazlar gözükmez.\n'
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 40.h,),
        Padding(
          padding:  EdgeInsets.only(left: 87.w),
          child: Text(
            'Bulunan cihazlar',
            style: TextStyle(
              fontFamily: 'Roboto', // Roboto Regular
              fontSize: 53.sp,
              color: Colors.white, // Özel renk
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 16.h,),
        Padding(
          padding:  EdgeInsets.only(left: 70.w),
          child: SizedBox(
            height: isBluetoothEnabled ? 0 : 200.h, // Set the height to 0 when not visible
            width: isBluetoothEnabled ? 0 : 900.w,
            child: Visibility(
              visible: !isBluetoothEnabled,
              child: Text(
                'Bluetooth kapalı.\nMobil aygıtınızda Bluetooth’u açın.',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.blueAccent,
                  fontSize: 45.sp,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(), // Sürükleme fiziksel davranışını belirle
            children: [
              SizedBox(
                height: sayac > 5 ? 650.h : (sayac * 130).h,
                child:ListView.builder(
                  itemExtent: 120.0.h, // Itemler arasındaki sabit boşluğu belirleyin
                  itemCount: sayac,
                  itemBuilder: (BuildContext context, int index) {
                    var filteredList = scanResultList.where((result) => result.device.platformName != null && result.device.platformName!.isNotEmpty).toList();
                    var result = filteredList[index];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 85.0.w),
                      leading: Icon(
                        Icons.circle_outlined,
                        color: const Color(0xFFADB8C9),
                        size: 75.sp,
                      ),
                      title: Text(
                        result.device.platformName!,
                        style: TextStyle(
                          fontSize: 45.sp,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DevicePageWidget(device: result.device),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding:  EdgeInsets.only(left:95.w,bottom: 120.h,top: 20.h),
                child: Visibility(
                  visible: _isScanning,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60.sp,
                        height: 60.sp,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4AC8FF)),
                        ),
                      ),
                      SizedBox(width:40.w),
                      Text(
                        'Bluetooth cihazlar aranıyor...',
                        style: TextStyle(
                          fontSize: 45.sp,
                          color: const Color(0xFF4AC8FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
