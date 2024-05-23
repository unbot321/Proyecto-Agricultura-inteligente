import 'package:app_semestre/DetailsScreen.dart';
import 'package:app_semestre/models/Plant.dart';
import 'package:app_semestre/utils/constanst.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

class PlantWidget extends StatelessWidget {
  final Function onSuccess;
  PlantWidget({
    Key? key,
    required this.index,
    required this.plantList,
    required this.onSuccess,
  }) : super(key: key);

  final storage = FlutterSecureStorage();

  Future<void> deletePlant() async {
    String? token = await storage.read(key: 'token');
    print(token);
    final response = await http.delete(
      Uri.parse(
          'http://10.0.2.2:8000/deletePlant?plant_id=${plantList[index].id}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    print(response.body);
    if (response.statusCode == 200) {
      onSuccess(plantList[index].id);
      print('Planta eliminada con éxito');
    } else {
      throw Exception('Error al eliminar la planta');
    }
  }

  final int index;
  final List<Plant> plantList;

  @override
  Widget build(BuildContext context) {
    Uint8List imageBytes = base64Decode(plantList[index].image);
    Size size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            PageTransition(
                child: DetailsScreen(
                  plant: plantList[index],
                ),
                type: PageTransitionType.bottomToTop));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Constants.primaryColor.withOpacity(.1),
          borderRadius: BorderRadius.circular(10),
        ),
        height: 80.0,
        padding: const EdgeInsets.only(left: 10, top: 10),
        margin: const EdgeInsets.only(bottom: 10, top: 10),
        width: size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60.0,
                  height: 60.0,
                  decoration: BoxDecoration(
                    color: Constants.primaryColor.withOpacity(.8),
                    shape: BoxShape.circle,
                  ),
                ),
                Positioned(
                  bottom: 5,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 60.0, // Ajusta el tamaño de la imagen
                    width: 60.0, // Ajusta el tamaño de la imagen
                    child: ClipOval(
                      // Envuelve la imagen en un ClipOval
                      child: Image.memory(imageBytes,
                          fit: BoxFit
                              .cover), // Asegúrate de que la imagen cubra todo el espacio
                    ),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  left: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plantList[index].family),
                      Text(
                        plantList[index].name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Constants.blackColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            GestureDetector(
                onTap: deletePlant,
                child: Container(
                    padding: const EdgeInsets.only(right: 10),
                    child: Center(
                      child: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    )))
          ],
        ),
      ),
    );
  }
}
