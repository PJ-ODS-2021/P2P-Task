import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

typedef OnQRCodeRead = Function(String value);

class QrReaderScreen extends StatefulWidget {
  final OnQRCodeRead onQRCodeRead;

  QrReaderScreen({Key? key, required OnQRCodeRead onQRCodeRead})
      : this.onQRCodeRead = onQRCodeRead,
        super(key: key);

  @override
  _QrReaderScreenState createState() => _QrReaderScreenState();
}

class _QrReaderScreenState extends State<QrReaderScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: (c) => _onQRViewCreated(c, context),
              formatsAllowed: [BarcodeFormat.qrcode],
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller, BuildContext context) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      final result = scanData.code;
      if (result.isNotEmpty) {
        controller.dispose();
        widget.onQRCodeRead(result);
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
