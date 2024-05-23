import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  final _bioController = TextEditingController();
  final storage = FlutterSecureStorage();

  Future<void> _getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<Map<String, dynamic>> _uploadPost() async {
    var uri = Uri.parse("http://10.0.2.2:8000/addPost");
    var request = http.MultipartRequest('POST', uri);

    String? token = await storage.read(key: 'token');
    var file = File(_selectedImage!.path);
    var stream = http.ByteStream(file.openRead());
    var length = await file.length();

    var multipartFile = http.MultipartFile('image', stream, length,
        filename: basename(file.path), contentType: MediaType('image', 'jpeg'));

    request.files.add(multipartFile);

    request.fields['post_info'] = _bioController.text;

    request.headers.addAll(<String, String>{'Authorization': 'Bearer $token'});

    setState(() {
      _isUploading = true;
    });
    var response = await request.send();
    setState(() {
      _isUploading = false;
    });

    if (response.statusCode == 200) {
      print("Post subido con éxito");
      var responseData = await response.stream.bytesToString();
      var postData = jsonDecode(responseData);
      postData['image'] = _selectedImage!.path;
      return postData;
    } else {
      var errorResponse = await response.stream.bytesToString();
      print('Error: $errorResponse');
      print("Error al subir el post");
      throw Exception('Error al subir el post');
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
        title: Text('Crear Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Para agregar el post, debes tomar una foto o subir una foto que deseas agregar.',
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
            SizedBox(height: 40),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Biografía',
              ),
            ),
            SizedBox(height: 40),
            if (_selectedImage != null)
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      var postData = await _uploadPost();
                      Navigator.of(context).pop();
                    } catch (e) {
                      print(e);
                    }
                  },
                  child: _isUploading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text('Crear Post'),
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
