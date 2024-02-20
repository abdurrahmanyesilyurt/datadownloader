import 'dart:typed_data';
import 'package:datadownloader/dataList.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class KWPMessage {

  Future<void> sendUploadRequest(BuildContext context,BluetoothCharacteristic characteristic) async {
    // Yük talebi gönderme
    try {
      await characteristic.write(uploadRequest); // Örnek komutlar, gerçek komutları projenize göre değiştirin
      print('Upload request sent successfully');
      showNotification(context, 'Upload request sent successfully: $uploadRequest');
    } catch (e) {
      print('Error sending upload request: $e');
    }
  }
  Future<void> startCommunicationRequest(BuildContext context,BluetoothCharacteristic characteristic) async {
    // Yük talebi gönderme
    try {
      await characteristic.write(START_COM); // Örnek komutlar, gerçek komutları projenize göre değiştirin
      print('Upload request sent successfully');
      showNotification(context, 'Communication request sent successfully: $START_COM');
    } catch (e) {
      print('Error sending upload request: $e');
    }
  }
  void showNotification(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
  Future<void> PositiveResponseStartCommunication(BuildContext context,BluetoothCharacteristic characteristic) async {
    // Pozitif yanıtı işleme
    try {
      List<int> response = await characteristic.read();
      if(response==POSITIVE_RESPOND_START)
      print('Positive response received: $response'); //0x80,0xF0, 0xEE, 0x03, 0xC1,0xEA,0x8F,0x9B
      else{
        showNotification(context,'Unexpected response received: $response');
      }
    } catch (e) {
      print('Error handling positive response: $e');
    }
  }

  Future<void> handleNegativeResponse(BuildContext context,BluetoothCharacteristic characteristic) async {
    try {
      List<int> response = await characteristic.read();
      print('Negative response received: $response');
      showNotification(context, 'Negative response received: $response');
    } catch (e) {
      print('Error handling negative response: $e');
    }
  }

  Future<void> transferData(BluetoothCharacteristic characteristic) async {
    // Veri transferini işleme
    try {
      List<int> data = await characteristic.read();
      print('Data received: $data');
    } catch (e) {
      print('Error handling data: $e');
    }
  }
}
