import 'package:feedback_system/User%20Management/ManageAdmins.dart';
import 'package:feedback_system/User%20Management/ManageRoot.dart';
import 'package:feedback_system/services/authManagement.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HamBurger {
  Auth auth;
  bool isAdmin;
  SharedPreferences _prefs;

  List<Widget> menu(BuildContext context) {
    auth = new Auth(context);
    return <Widget>[
      ListTile(
        title: Text('Create feedback'),
        onTap: () async {
          _prefs = await SharedPreferences.getInstance();
          isAdmin = _prefs.getBool("admin");
          if (isAdmin) {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/nameFeedback');
          } else {
            Fluttertoast.showToast(msg: "Permission denied!");
          }
        },
      ),
      ListTile(
        title: Text('Closed feedbacks'),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed('/closedFeedback');
        },
      ),
      ListTile(
        title: Text('All feedbacks'),
        onTap: () async {
          _prefs = await SharedPreferences.getInstance();
          bool isroot = _prefs.getBool("root");
          if(isroot) {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/allFeedbacks');
          } else {
            Fluttertoast.showToast(msg: 'This page is only for managers');
          }
        },
      ),
      ListTile(
        title: Text('Manage admins'),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.push(context, MaterialPageRoute(builder: (context) => ManageAdmins()));
        },
      ),
      ListTile(
        title: Text('Department managers'),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.push(context, MaterialPageRoute(builder: (context) => ManageRoot()));
        },
      ),
      ListTile(
          title: Text('Logout'),
          onTap: () {
            auth.signOut();
          })
    ];
  }
}
