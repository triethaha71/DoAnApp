import 'package:appdatfood/pages/home.dart';
import 'package:appdatfood/pages/order.dart';
import 'package:appdatfood/pages/profile.dart';
import 'package:appdatfood/pages/wallet.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class Bottomnav extends StatefulWidget {
  const Bottomnav({super.key});

  @override
  State<Bottomnav> createState() => _BottomnavState();
}

class _BottomnavState extends State<Bottomnav> {
  int currentTabIndex = 0;

  late List<Widget> pages;
  late Widget currentPage;
  late Home homepage;
  late Profile profile;
  late Order order;
  late Wallet wallet;

  @override
  void initState() {
    homepage = const Home();
    order = const Order();
    profile = const Profile();
    wallet = const Wallet();
    pages = [homepage, order, wallet, profile];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
          height: 65,
          
          backgroundColor: Colors.white,
          color: Color.fromARGB(255, 60, 97, 164),
          animationDuration: const Duration(milliseconds: 500),
          onTap: (int index) {
            setState(() {
              currentTabIndex = index;
            });
          },
          items: [
            const Icon(
              Icons.home_outlined,
              color: Colors.white,
            ),
            const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
            ),
            const Icon(
              Icons.wallet_outlined,
              color: Colors.white,
            ),
            const Icon(
              Icons.person_outline,
              color: Colors.white,
            )
          ]),
          body: pages[currentTabIndex],
    );
  }
}
