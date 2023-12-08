import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool isProcessingQR = false; // Controla si se está procesando un QR

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
    setState(() {
      isProcessingQR = false; // Restablece el control al reanudar la cámara
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lector de Códigos QR'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Text('Código QR: ${result!.code}')
                  : const Text('Escanea un código'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isProcessingQR) {
        setState(() {
          isProcessingQR = true; // Comienza a procesar
          result = scanData;
        });
        await _handleQRCodeResult(scanData);
      }
    });
  }

  Future<void> _handleQRCodeResult(Barcode scanData) async {
    if (scanData.code != null) {
      String qrData = scanData.code!;
      final Uri? qrUri = Uri.tryParse(qrData);

      if (qrUri != null && await canLaunchUrl(qrUri)) {
        await launchUrl(qrUri);
      } else {
        Text("No se pudo abrir: $qrData");
      }

      setState(() {
        isProcessingQR = false; // Procesamiento terminado
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
