import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:app_semestre/DetailsScreen.dart';
import 'package:app_semestre/ScanScreen.dart';
import 'package:app_semestre/customDrawer.dart';
import 'package:app_semestre/homeScreen.dart';
import 'package:app_semestre/models/Plant.dart';
import 'package:app_semestre/models/User.dart';
import 'package:app_semestre/profileScreen.dart';
import 'package:app_semestre/signIn.dart';
import 'package:app_semestre/utils/constanst.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

class RootPage extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  RootPage({required this.userInfo});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  late final User usuario;
  @override
  void initState() {
    usuario = User.fromMap(widget.userInfo);
    super.initState();
  }

  int _bottomNavIndex = 0;

  //List of the pages
  List<Widget> _widgetOptions() {
    return [
      const HomePage(),
      DetailScreen(plantId: Plant.plantList[0].plantId),
      const HomePage(),
      ProfileScreen(userInfo: usuario),
    ];
  }

  //List of the pages icons
  List<IconData> iconList = [
    Icons.home,
    Icons.explore,
    Icons.favorite,
    Icons.person,
  ];

  //List of the pages titles
  List<String> titleList = [
    'Inicio',
    'Explorar',
    'Favoritos',
    'Perfil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Icon(
            Icons.notifications,
            color: Constants.blackColor,
            size: 30.0,
          )
        ],
        title: Text(
          titleList[_bottomNavIndex],
          style: TextStyle(
            color: Constants.blackColor,
            fontWeight: FontWeight.w500,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.0,
      ),
      body: IndexedStack(
        index: _bottomNavIndex,
        children: _widgetOptions(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              PageTransition(
                  child: const ScanScreen(),
                  type: PageTransitionType.bottomToTop));
        },
        child: Image.asset(
          'assets/images/code-scan-two.png',
          height: 30.0,
        ),
        backgroundColor: Constants.primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
          splashColor: Constants.primaryColor,
          activeColor: Constants.primaryColor,
          inactiveColor: Colors.black.withOpacity(.5),
          icons: iconList,
          activeIndex: _bottomNavIndex,
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.softEdge,
          onTap: (index) {
            setState(() {
              _bottomNavIndex = index;
              // final List<Plant> favoritedPlants = Plant.getFavoritedPlants();
              // final List<Plant> addedToCartPlants = Plant.addedToCartPlants();

              // // favorites = favoritedPlants;
              // // myCart = addedToCartPlants.toSet().toList();
            });
          }),
    );
  }
}
