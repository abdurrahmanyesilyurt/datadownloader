import 'dart:typed_data';

Uint8List uploadRequest = Uint8List.fromList([
  0x80, 0xEE, 0xF0, 0x0A, 0x35, 0x00,
  0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF,
  0xFF, 0xFF, 0x99
]);
Uint8List START_COM = Uint8List.fromList([
  0x81, 0xEE, 0xF0, 0x81, 0xE0,
]);
Uint8List START_SESSION = Uint8List.fromList([
  0x80, 0xEE, 0xF0, 0x02, 0x10,0x81,0xF1
]);
Uint8List DRIVER_CARD_REQUEST = Uint8List.fromList([
  0x80, 0xEE, 0xF0, 0x02, 0x36,0x06,0x9C
]);
Uint8List POSITIVE_RESPOND_START = Uint8List.fromList([
  0x80,0xF0, 0xEE, 0x03, 0xC1,0xEA,0x8F,0x9B
]);
Uint8List POSITIVE_Diagnostic_Request = Uint8List.fromList([
  0x80,0xF0, 0xEE, 0x03, 0xC1,0xEA,0x8F,0x9B
]);