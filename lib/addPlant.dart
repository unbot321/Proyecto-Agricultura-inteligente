import 'dart:convert';
import 'dart:io';

import 'package:app_semestre/SavePlant.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

class AddPlantScreen extends StatefulWidget {
  @override
  _AddPlantScreenState createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  Future<void> _getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<Map<String, dynamic>> _uploadImage() async {
    var uri = Uri.parse("http://10.0.2.2:8000/identifyPlant");
    var request = http.MultipartRequest('POST', uri);

    // Abre el archivo de imagen
    var file = File(_selectedImage!.path);
    var stream = http.ByteStream(file.openRead());
    var length = await file.length();

    // Agrega el archivo a la petición
    var multipartFile = http.MultipartFile('image', stream, length,
        filename: basename(file.path), contentType: MediaType('image', 'jpeg'));

    request.files.add(multipartFile);

    // Envía la petición
    setState(() {
      _isUploading = true;
    });
    var response = await request.send();
    setState(() {
      _isUploading = false;
    });

    if (response.statusCode == 200) {
      print("Imagen subida con éxito");
      var responseData = await response.stream.bytesToString();
      var plantData = jsonDecode(responseData);
      plantData['image'] = _selectedImage!.path;
      return plantData;
    } else {
      print("Error al subir la imagen");
      throw Exception('Error al subir la imagen');
    }
  }

  Future<void> _askPermission(ImageSource source) async {
    Permission permission;
    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      permission = Permission.photos;
    }
    if (await permission.isGranted) {
      await _getImage(source);
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        await _getImage(source);
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _askPermission(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Seleccionar de la galería'),
                onTap: () {
                  Navigator.pop(context);
                  _askPermission(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Agregar planta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Para agregar la planta, debes tomar una foto o subir una foto de la planta que deseas agregar.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            if (_selectedImage == null)
              Center(
                child: GestureDetector(
                  onTap: () => _showImageSourceActionSheet(context),
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.add_a_photo, size: 50),
                  ),
                ),
              ),
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.file(
                  File(_selectedImage!.path),
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 20),
            if (_selectedImage != null)
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      var plantData = await _uploadImage();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SavePlant(plantData: plantData),
                        ),
                      );
                    } catch (e) {
                      print(e);
                    }
                  },
                  child: _isUploading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text('Agregar planta'),
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
              ),
          ],
        ),
      ),
    );
  }
}
