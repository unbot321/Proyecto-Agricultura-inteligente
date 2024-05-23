import 'dart:convert';
import 'dart:io';
import 'package:app_semestre/rootScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class SavePlant extends StatefulWidget {
  final Map<String, dynamic> plantData;

  SavePlant({required this.plantData});

  @override
  _SavePlantState createState() => _SavePlantState();
}

class _SavePlantState extends State<SavePlant> {
  late TextEditingController _nameController;
  late TextEditingController _familyController;
  late TextEditingController _scientificNameController;
  late TextEditingController _wateringTypeController;
  late bool _indoor;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plantData['name']);
    _familyController = TextEditingController(text: widget.plantData['family']);
    _scientificNameController =
        TextEditingController(text: widget.plantData['scientificName']);
    _wateringTypeController =
        TextEditingController(text: widget.plantData['wateringType']);
    _indoor = widget.plantData['indoor'];
  }

  Future<void> _savePlant() async {
    var url = Uri.parse('http://10.0.2.2:8000/addPlant');
    var request = http.MultipartRequest('POST', url);

    String? token = await storage.read(key: 'token');

    request.headers.addAll(<String, String>{
      'Authorization': 'Bearer $token',
    });

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      widget.plantData['image'],
    ));

    request.fields.addAll(<String, String>{
      'plant_info': jsonEncode({
        'name': _nameController.text,
        'family': _familyController.text,
        'scientificName': _scientificNameController.text,
        'wateringType': _wateringTypeController.text,
        'indoor': _indoor.toString(),
      }),
    });

    // Envía la petición
    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var decodedResponse = jsonDecode(responseBody);

      print("Planta agregada con éxito");
      print('Usuario: ${decodedResponse['user']}');
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
            child: RootPage(userInfo: decodedResponse['user']),
            type: PageTransitionType.topToBottom),
        (Route<dynamic> route) => false,
      );
    } else {
      print("Error al agregar la planta");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Guardar Planta'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.plantData['image'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.file(
                  File(widget.plantData['image']),
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre',
              ),
            ),
            TextFormField(
              controller: _familyController,
              decoration: InputDecoration(
                labelText: 'Familia',
              ),
            ),
            TextFormField(
              controller: _scientificNameController,
              decoration: InputDecoration(
                labelText: 'Nombre científico',
              ),
            ),
            TextFormField(
              controller: _wateringTypeController,
              decoration: InputDecoration(
                labelText: 'Tipo de riego',
              ),
            ),
            CheckboxListTile(
              title: Text('Interior'),
              value: _indoor,
              onChanged: (bool? value) {
                setState(() {
                  _indoor = value!;
                });
              },
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _savePlant,
                child: Text('Guardar planta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
