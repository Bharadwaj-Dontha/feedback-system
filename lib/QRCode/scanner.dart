import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feedback_system/QRCode/Answer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_code_scanner/qr_scanner_overlay_shape.dart';

class Scanner extends StatefulWidget {
  @override
  _ScannerState createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  GlobalKey qrKey = new GlobalKey();
  var qrText = "";
  String feedbackId;
  QRViewController controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width - 25;
    return Scaffold(
      appBar: AppBar(title: Text('QR Scanner')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 7,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQrViewCreated,
              overlay: QrScannerOverlayShape(
                  borderColor: Colors.red,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 8,
                  cutOutSize: 200),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                SizedBox(
                  width: 5,
                ),
                SizedBox(
                  width: (width * 4) / 5,
                  child: TextField(
                    keyboardType: TextInputType.numberWithOptions(
                        signed: false, decimal: false),
                    decoration: InputDecoration(
                      hintText: 'Enter the code below',
                    ),
                    onChanged: (value) {
                      feedbackId = value;
                    },
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                SizedBox(
                  width: width / 5,
                  child: RaisedButton(
                    color: Colors.blue,
                    child: Text(
                      'Next',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      var snapshot = await Firestore.instance
                          .collection('/feedbacks')
                          .where('id', isEqualTo: int.parse(feedbackId))
                          .where('status', isEqualTo: 'open')
                          .getDocuments();

                      if (snapshot.documents.length > 0) {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Answer(
                                    data: snapshot.documents[0].documentID)));
                      } else {
                        AwesomeDialog(
                                dialogType: DialogType.ERROR,
                                context: context,
                                desc: 'Not a valid ID',
                                tittle: 'Error',
                                dismissOnTouchOutside: true)
                            .show();
                      }
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  _onQrViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((data) {
      print(data);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Answer(data: data)));
    });
  }
}
