import 'package:app_semestre/DetailsScreen.dart';
import 'package:app_semestre/header.dart';
import 'package:app_semestre/models/Plant.dart';
import 'package:app_semestre/utils/constanst.dart';
import 'package:app_semestre/widgets/plantWidget.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class HomePage extends StatefulWidget {
  final List<Plant> plantList;

  const HomePage({Key? key, required this.plantList}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Plant> filteredPlantList = [];

  @override
  void initState() {
    super.initState();
    filteredPlantList = List.from(widget.plantList);
  }

  void _filterPlants(String query) {
    setState(() {
      filteredPlantList = widget.plantList
          .where((plant) =>
              plant.name.toLowerCase().contains(query.toLowerCase()) ||
              plant.scientificName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    int selectedIndex = 0;
    Size size = MediaQuery.of(context).size;

    //Plants category
    List<String> _plantTypes = [
      'Interior',
      'Exterior',
      'Jardin',
    ];

    //Toggle Favorite button
    bool toggleIsFavorated(bool isFavorited) {
      return !isFavorited;
    }

    void onSuccess(String plantId) {
      print('La planta con id $plantId se eliminó con éxito');
      setState(() {
        widget.plantList.removeWhere((plant) => plant.id == plantId);
        filteredPlantList.removeWhere((plant) => plant.id == plantId);
      });
    }

    return Scaffold(
      body: widget.plantList.isEmpty
          ? Center(child: Text('Aún no has subido plantas'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ),
                        width: size.width * .9,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              color: Colors.black54.withOpacity(.6),
                            ),
                            Expanded(
                              child: TextField(
                                onChanged: _filterPlants,
                                showCursor: false,
                                decoration: InputDecoration(
                                  hintText: 'Buscar planta',
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        decoration: BoxDecoration(
                          color: Constants.primaryColor.withOpacity(.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ListView.builder(
                      itemCount: filteredPlantList.length,
                      scrollDirection: Axis.vertical,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (BuildContext context, int index) {
                        return PlantWidget(
                          index: index,
                          plantList: filteredPlantList,
                          onSuccess: onSuccess,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
