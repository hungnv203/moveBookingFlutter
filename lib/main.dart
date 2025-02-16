import 'package:flutter/material.dart';
import 'package:my_app/pages/admin_screen/AdminCinemaPage.dart';
import 'package:my_app/pages/admin_screen/AdminHomePage.dart';
import 'package:my_app/pages/customer_screen/booking.dart';
import 'package:my_app/pages/customer_screen/bottomnav.dart';
import 'package:my_app/pages/customer_screen/detail_page_film.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_app/pages/customer_screen/home.dart';
import 'package:my_app/pages/customer_screen/ticketPage.dart';
import 'package:my_app/pages/sign_in_screen.dart';
import 'package:my_app/pages/sign_up_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Bottomnav(),
    );
  }
}
