import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feedback_system/public/Metrics/effort_rating.dart';
import 'package:feedback_system/public/Metrics/goalcompletionrate_meter.dart';
import 'package:feedback_system/public/Metrics/questionandresponse.dart';
import 'package:feedback_system/public/Metrics/satisfaction_rating.dart';
import 'package:feedback_system/public/Metrics/smiley_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Answer extends StatefulWidget {
  final String data;

  Answer({this.data});

  @override
  _AnswerState createState() => _AnswerState();
}

class _AnswerState extends State<Answer> {
  var data;
  double avg = 0;
  var attended;
  bool perform = false;
  String email;
  var updated;
  var _doc;
  List<QuestionAndResponse> questionObjectList =
      new List<QuestionAndResponse>();

  instantiate() async {
    await Firestore.instance
        .collection('/feedbacks')
        .document(widget.data)
        .get()
        .then((_data) {
      if (!_data.exists) {
        setState(() {
          data = 'Error';
        });
      } else {
        setState(() {
          data = _data;
        });
      }
    });
  }

  getSharedPreferences() async {
    await SharedPreferences.getInstance().then((val) {
      setState(() {
        email = val.getString("email");
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getSharedPreferences();
    instantiate();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (data == null)
      return SpinKitThreeBounce(color: Colors.blue);
    else if (data == 'Error')
      return stopUser('Feedback no longer exists');
    else if (data['attended'].contains(email))
      return stopUser('Can\'t give feedback more than once');
    else
      return fetchDocument(width);
  }

  stopUser(data) {
    return Scaffold(
        body: Center(
      child: Text(data),
    ));
  }

  fetchDocument(double width) {
    return Scaffold(
      appBar: AppBar(
        title: Text(data['name']),
      ),
      body: ListView.separated(
        separatorBuilder: (context, index) =>
            Divider(height: 1.0, color: Colors.grey),
        itemBuilder: (context, index) {
          if (index == data['questions'].length) {
            return Padding(
              padding: const EdgeInsets.all(15.0),
              child: RaisedButton(
                color: Color(0xff23272B),
                child: Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  uploadFeedback(context);
                },
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(5, 2, 5, 2),
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Text(
                    (index + 1).toString() + ")",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  title: Text(
                    data['questions'][index],
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                metric(index)
              ],
            ),
          );
        },
        itemCount: data['questions'].length + 1,
      ),
    );
  }

  metric(int index) {
    switch (data['metrics'][index]) {
      case 'Satisfaction':
        return slider(index);
      case 'SmileyRating':
        return smiley(index);
      case 'EffortScore':
        return effortScore(index);
      case 'GoalCompletionRate':
        return goalCompletionRate(index);
      default:
        return Text('Unexpected error');
    }
  }

  goalCompletionRate(int index) {
    QuestionAndResponse temp =
        QuestionAndResponse(data['questions'][index], "GoalCompletionRate");
    questionObjectList.add(temp);
    return GoalCompletionRateMeter(temp);
  }

  effortScore(int index) {
    QuestionAndResponse temp =
        QuestionAndResponse(data['questions'][index], "EffortScore");
    questionObjectList.add(temp);
    return EffortRatingMeter(temp);
  }

  smiley(int index) {
    QuestionAndResponse temp =
        QuestionAndResponse(data['questions'][index], "SmileyRating");
    questionObjectList.add(temp);
    return SmileyRatingMeter(temp);
  }

  slider(int index) {
    QuestionAndResponse temp =
        QuestionAndResponse(data['questions'][index], "Satisfaction");
    questionObjectList.add(temp);
    return SatisafactionRatingMeter(temp);
  }

  uploadFeedback(context) {
    ProgressDialog pr = new ProgressDialog(context);
    pr.style(message: 'Submitting response');
    pr.show();
    var ref = Firestore.instance.collection('/feedbacks').document(widget.data);
    Firestore.instance.runTransaction((tx) async {
      await ref.get().then((doc) {
        _doc = doc;
        var prev = doc['scores'];
        attended = doc['attended'];
        attended.add(email);
        for (int i = 0; i < questionObjectList.length; i++) {
          int response = questionObjectList[i].response;
          prev[i.toString()][response - 1] += 1;
        }
        updated = prev;
      });
      await tx.update(ref, {
        'scores': updated,
        'attended': attended,
      });
    }).then((val) async {
      await ref.get().then((doc) {
        if (!(doc['attended'].contains(email))) {
          throw Exception('Error');
        }
      }).catchError((e) {
        throw Exception('Error');
      });
      pr.hide();
      Fluttertoast.showToast(msg: 'Feedback submitted succesfully');
      Navigator.of(context, rootNavigator: false).pop();
      Navigator.of(context).pushNamedAndRemoveUntil('/homepage', (r) => false);
    }).catchError((e) {
      pr.hide();
      print(e);
      Fluttertoast.showToast(
          msg: 'Error submitting the feedback. Try again later');
    });
  }
}
