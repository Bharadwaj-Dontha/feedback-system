import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feedback_system/Feedback modification/edit_feedback.dart';
import 'package:feedback_system/QRCode/scanner.dart';
import 'package:feedback_system/services/authManagement.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hamburger.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HamBurger hamBurger = new HamBurger();
  int section;
  Auth auth;
  bool isAdmin, isRoot;
  String email;
  String qrText;
  List departments;
  bool _statusStorage;
  Stream<QuerySnapshot> feedbacks;

  requestStoragePermissions() {
    if (Platform.isAndroid) {
      Permission.storage.isGranted.then((status) {
        setState(() {
          _statusStorage = status;
        });
      });
      Permission.storage.isPermanentlyDenied.then((status) {
        Fluttertoast.showToast(
            msg: 'Please grant storage permissions in the setting');
      });
      Permission.storage.isUndetermined.then((status) {
        Permission.storage.request();
      });
    } else if (Platform.isIOS) {
      Permission.photos.isGranted.then((status) {
        setState(() {
          _statusStorage = status;
        });
      });
      Permission.photos.isUndetermined.then((status) {
        Permission.storage.request();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    auth = new Auth(context);
    // requestStoragePermissions();
  }

  @override
  void deactivate() {
    // print('In deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    // print('in dispose');
    super.dispose();
  }

  Future<bool> getUserData() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();

    setState(() {
      email = _prefs.getString('email');
      isAdmin = _prefs.getBool('admin');
      isRoot = _prefs.getBool('root');
    });

    return isAdmin;
  }

  requestCamera() async {
    if (Platform.isAndroid) {
      await Permission.camera.isUndetermined.then((status) async {
        await Permission.camera.request();
      });
      await Permission.camera.isDenied.then((status) async {
        await Permission.camera.request();
      });
    } else {
      await Permission.photos.isUndetermined.then((status) async {
        await Permission.photos.request();
      });
      await Permission.photos.isDenied.then((status) async {
        await Permission.photos.request();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.redAccent,
      appBar: AppBar(
        title: Text('Home'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(children: hamBurger.menu(context)),
      ),
      body: FutureBuilder(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return userContent();
          } else {
            return loading();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
          heroTag: 'Scan',
          child: Icon(MdiIcons.qrcodeScan),
          backgroundColor: Colors.blue,
          onPressed: () async {
            await requestCamera();
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => Scanner()));
          },
          tooltip: 'QR Scanner'),
    );
  }

  loading() {
    return Center(
        child: SpinKitWave(
      color: Colors.blue,
    ));
  }

  userContent() {
    return StreamBuilder(
      stream: Firestore.instance
        .collection('/feedbacks')
        .where('host_id', isEqualTo: email)
        .where('status', isEqualTo: "open")
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.documents.length == 0) {
            return Center(
              child: Text('No active feedbacks'),
            );
          }
          return ListView.separated(
            separatorBuilder: (context, index) =>
                Divider(height: 1.0, color: Colors.grey),
            itemCount: snapshot.data.documents.length,
            itemBuilder: (context, index) {
              DocumentSnapshot feedback = snapshot.data.documents[index];

              return ListTile(
                title: Text(feedback.data['name']),
                subtitle: Text('Host : ' + feedback.data['host']),
                trailing: Text(feedback.data['type'] ?? ""),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditFeedback(
                              feedback: feedback, isRoot: isRoot)));
                },
              );
            },
          );
        } else if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasData) {
          return Center(child: Text('No active feedbacks'));
        } else {
          return loading();
        }
      },
    );
  }

  fetchDepartments() async {
    var docs = await Firestore.instance
        .collection('/root')
        .where('email', isEqualTo: email)
        .getDocuments();

    departments = docs.documents[0].data['departments'];
    return true;
  }

  rootContent() {
    return FutureBuilder(
      future: fetchDepartments(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return StreamBuilder(
            stream: Firestore.instance
                .collection('/feedbacks')
                .where('status', isEqualTo: 'open')
                .where('type', whereIn: departments)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data.documents.length == 0) {
                  return Center(
                    child: Text('No active feedbacks'),
                  );
                }
                return ListView.separated(
                  separatorBuilder: (context, index) =>
                      Divider(height: 1.0, color: Colors.grey),
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot feedback = snapshot.data.documents[index];

                    return ListTile(
                      title: Text(feedback.data['name']),
                      subtitle: Text('Host : ' + feedback.data['host']),
                      trailing: Text(feedback.data['type'] ?? ""),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditFeedback(
                                    feedback: feedback, isRoot: isRoot)));
                      },
                    );
                  },
                );
              } else if (snapshot.connectionState == ConnectionState.done &&
                  !snapshot.hasData) {
                return Center(child: Text('No active feedbacks'));
              } else {
                return loading();
              }
            },
          );
        } else {
          return loading();
        }
      },
    );
  }
}
