import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:progress_dialog/progress_dialog.dart';

class AddManager extends StatefulWidget {
  @override
  _AddManagerState createState() => _AddManagerState();
}

class _AddManagerState extends State<AddManager> {
  final formKey = new GlobalKey<FormState>();
  String _email;
  List<String> departments = new List<String>();

  validateAndSave() {
    final form = formKey.currentState;

    if (form.validate() && departments.isNotEmpty) {
      form.save();
      return true;
    }
    Fluttertoast.showToast(msg: 'Please fill in all the details');
    return false;
  }

  validateAndSubmit() async {
    if (validateAndSave()) {
      ProgressDialog pr = new ProgressDialog(context);
      pr.style(message: 'Just a moment');
      pr.show();
      var userDocs = await Firestore.instance
          .collection('/users')
          .where('email', isEqualTo: _email)
          .getDocuments();

      if(userDocs.documents.length == 0) {
        Fluttertoast.showToast(msg: 'User doesn\'t exist');
        pr.hide();
      } else {
        var docID = userDocs.documents[0].documentID;
        var doc = userDocs.documents[0];

        await Firestore.instance.collection('/users').document(docID).updateData({'isadmin': true}).catchError((e) {
          print(e);
          pr.hide();
        });

        await Firestore.instance.collection('/root').add({
          'name': doc.data['name'],
          'departments': departments,
          'email': doc.data['email']
        }).then((val) {
          pr.hide();
          Navigator.of(context).pop();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manager details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(15),
          child: Form(
            key: formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: detailsForm()),
          ),
        ),
      ),
    );
  }

  List<Widget> detailsForm() {
    return <Widget>[
      TextFormField(
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
            labelText: 'Email', suffixIcon: Icon(MdiIcons.email)),
        validator: (value) {
          return value.isEmpty ? "Email is required" : null;
        },
        onSaved: (value) => _email = value,
      ),
      SizedBox(
        height: 5,
      ),
      CheckboxGroup(
        labels: <String>["Training", "Seminar", "Workshop", "Faculty"],
        onSelected: (checked) => departments = checked,
      ),
      SizedBox(
        height: 5,
      ),
      RaisedButton(
        child: Text('Add', style: TextStyle(color: Colors.white)),
        color: Colors.blue,
        onPressed: validateAndSubmit,
      )
    ];
  }
}
