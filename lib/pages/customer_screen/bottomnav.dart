import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/customer_screen/home.dart';
import 'package:my_app/pages/customer_screen/profile.dart';
import 'package:my_app/pages/customer_screen/ticketPage.dart';

class Bottomnav extends StatefulWidget {
  const Bottomnav({super.key});
  @override
  State<Bottomnav> createState() => _BottomnavState();
}

class _BottomnavState extends State<Bottomnav> {
  User? user = FirebaseAuth.instance.currentUser;
  late List<Widget> _pages;
  late Home Hompage;
  late TicketPage ticketsPage;
  late ProfilePage profilePage;

  int currentIndex = 0;

  @override
  void initState() {
    Hompage = Home();
    ticketsPage = TicketPage();
    profilePage = ProfilePage();
    _pages = [Hompage, ticketsPage,profilePage,];
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: 'Ticket',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
