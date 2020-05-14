import 'package:feedback_system/Previous%20feedbacks/closedFeedbacks.dart';
import 'package:feedback_system/User%20Management/AddManager.dart';
import 'package:feedback_system/authentication/signup.dart';
import 'package:feedback_system/home/AllFeedbacks.dart';
import 'package:feedback_system/services/authManagement.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flare_splash_screen/flare_splash_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Feedback creation/createFeedback.dart';
import 'Feedback creation/namingFeedback.dart';
import 'authentication/loginpage.dart';
import 'home/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen.navigate(
        name: 'assets/SplashScreen.flr',
        next: (context) => LandingPage(),
        until: () => updateData(context),
        //isLoading: false,
        startAnimation: 'Login Page',
        fit: BoxFit.cover,
        backgroundColor: Color(0xFF272727),
      ),
      routes: <String, WidgetBuilder>{
        '/allFeedbacks': (BuildContext context) => new AllFeedbacks(),
        '/addManager': (BuildContext context) => new AddManager(),
        '/signup': (BuildContext context) => new SignUp(),
        '/nameFeedback': (BuildContext context) => new NamingFeedback(),
        '/landingpage': (BuildContext context) => new LoginPage(),
        '/homepage': (BuildContext context) => new HomePage(),
        '/createFeedback': (BuildContext context) => new CreateFeedback(),
        '/closedFeedback': (BuildContext context) => new ClosedFeedbacks()
      },
    );
  }

  updateData(context) async {
    String email;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email');
    if (email != null) {
      Auth auth = new Auth(context);
      await auth.getAdmins(email).then((docs) {
        prefs.setBool('admin', docs.documents.length > 0);
      });
      await auth.getRoots(email).then((docs) {
        prefs.setBool('root', docs.documents.length > 0);
      });
    }
  }
}

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FirebaseUser>(
      stream: FirebaseAuth.instance.onAuthStateChanged,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          FirebaseUser user = snapshot.data;
          if (user == null) {
            return LoginPage();
          }
          if (user.isEmailVerified)
            return HomePage();
          else
            return LoginPage();
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else
          return null;
      },
    );
  }
}
