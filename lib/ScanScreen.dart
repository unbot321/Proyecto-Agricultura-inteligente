import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:app_semestre/ImagePreviewScreen.dart';
import 'package:app_semestre/rootScreen.dart';
import 'package:app_semestre/utils/constanst.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class Message {
  final XFile? image;
  String text;
  final bool isOwnMessage;
  bool isLoading;
  bool isError;

  Message(
      {this.image,
      required this.text,
      this.isOwnMessage = false,
      this.isError = false,
      this.isLoading = false});

  set setText(String newText) {
    text = newText;
  }

  set setIsError(bool newState) {
    isError = newState;
  }

  set setIsLoading(bool newState) {
    isLoading = newState;
  }
}

class ScanScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  ScanScreen({required this.userInfo});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _controller = TextEditingController();
  XFile? _selectedImage;
  bool isLoadingMessage = true;
  String? _threadID;

  String _message = '';
  List<Message> _messages = [];
  bool _isScanned = false; // Añade esta línea

  Future<void> _getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewScreen(image: image),
        ),
      );

      if (result is Message) {
        if (mounted) {
          setState(() {
            _messages.add(result);
            _isScanned = true;
            _messages.add(Message(
                image: null, text: '', isOwnMessage: false, isLoading: true));
          });

          await requestResponse(result.text, result.image, null);
        }
      }
    }
  }

  Future<void> requestResponse(
      String message, XFile? image, String? threadID) async {
    isLoadingMessage = true;

    var uri = Uri.parse('http://10.0.2.2:8000/assistant');
    var request = http.MultipartRequest('POST', uri);

    request.fields['textContent'] = message;
    if (threadID != null) {
      request.fields['threadID'] = threadID;
    }

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        Map<String, dynamic> responseBody = jsonDecode(responseString);

        String message = responseBody['message'];

        setState(() {
          _message = '';
          isLoadingMessage = false;
          _messages.last.text = message;
          _messages.last.isLoading = false;
        });

        _threadID = responseBody['threadID'];
      } else {
        String responseString = await response.stream.bytesToString();
        Map<String, dynamic> responseBody = jsonDecode(responseString);
        print('Server response status code: ${response.statusCode}');
        throw Exception('${responseBody} Status code: ${response.statusCode}');
      }

      isLoadingMessage = false;
    } catch (e) {
      setState(() {
        _message = 'Error, vuelve a intentarlo más tarde';
        isLoadingMessage = false;
        _messages.last.isError = true;
        _messages.last.text = 'Error, vuelve a intentarlo más tarde';
        _messages.last.isLoading = false;
      });
      print('Error: $e');
      throw Exception('Failed to send message. Error: $e');
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

  Future<void> _sendMessage() async {
    if (_message.isNotEmpty && !isLoadingMessage) {
      setState(() {
        isLoadingMessage = true;
        _messages.add(Message(image: null, text: _message, isOwnMessage: true));
        _messages.add(Message(
            text: '', isLoading: true, image: null, isOwnMessage: false));
        _selectedImage = null;

        _controller.clear();
      });

      await requestResponse(_message, null, _threadID);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        leading: Container(
          margin: EdgeInsets.only(left: 5),
          child: GestureDetector(
            onTap: () async {
              await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Theme(
                        data: ThemeData(
                            brightness: Brightness.light,
                            useMaterial3: true,
                            colorSchemeSeed: Colors.red,
                            dialogTheme: DialogTheme(
                                surfaceTintColor: Colors.grey.shade300)),
                        child: AlertDialog(
                          title: Center(child: Text('Confirmación')),
                          content: Text(
                              '¿Estás seguro de que quieres cerrar este chat?'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Cancelar'),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            TextButton(
                              child: Text(
                                'Aceptar',
                              ),
                              onPressed: () async {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  PageTransition(
                                      child:
                                          RootPage(userInfo: widget.userInfo),
                                      type: PageTransitionType.topToBottom),
                                  (Route<dynamic> route) => false,
                                );
                              },
                            ),
                          ],
                        ));
                  });
            },
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Constants.primaryColor.withOpacity(.15),
              ),
              child: Icon(
                Icons.close,
                color: Constants.primaryColor,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (!_isScanned)
            Positioned(
              right: 20,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  _showImageSourceActionSheet(context);
                },
                child: Container(
                  width: size.width * .8,
                  height: size.height * .8,
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/code-scan.png',
                          height: 100,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Toca para escanear',
                          style: TextStyle(
                            color: Constants.primaryColor.withOpacity(.80),
                            fontWeight: FontWeight.w500,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_isScanned)
            Container(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Column(
                          crossAxisAlignment: message.isOwnMessage
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!message.isOwnMessage)
                              Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: CircleAvatar(
                                  backgroundColor:
                                      Colors.green.withOpacity(0.5),
                                  radius: 20,
                                  child: Center(
                                    child: Container(
                                        padding: EdgeInsets.all(5),
                                        height: 40,
                                        width: 40,
                                        child: Image.asset(
                                            "assets/images/bot.png")),
                                  ),
                                ),
                              ),
                            Container(
                              margin: EdgeInsets.all(8.0),
                              padding: EdgeInsets.all(8.0),
                              child: Container(
                                padding: EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: message.isError
                                      ? Colors.red
                                      : message.isOwnMessage
                                          ? Colors.grey.shade900
                                          : Colors.greenAccent,
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (message.image != null)
                                      Container(
                                        width: 300,
                                        padding: EdgeInsets.only(bottom: 8.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                          child: Image.file(
                                            File(message.image!.path),
                                            height: 250.0,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      child: message.isLoading
                                          ? LoadingDots()
                                          : Text(
                                              message.text,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18),
                                            ),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    margin: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 200.0, // Define tu altura máxima aquí
                            ),
                            child: Scrollbar(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                    horizontal:
                                        8.0), // Padding horizontal para el texto
                                reverse: true,
                                child: TextField(
                                  controller: _controller,
                                  maxLines:
                                      null, // Esto permitirá que el TextField se expanda a medida que se introduce más texto
                                  onChanged: (value) {
                                    setState(() {
                                      _message = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Escribe un mensaje...',
                                    border: InputBorder
                                        .none, // Elimina la línea inferior del input
                                    contentPadding: EdgeInsets.all(
                                        10.0), // Padding horizontal para el hintText
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send,
                              color: isLoadingMessage
                                  ? Colors.grey.shade400
                                  : Colors.green),
                          onPressed: isLoadingMessage ? null : _sendMessage,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}

class LoadingDots extends StatefulWidget {
  @override
  _LoadingDotsState createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Text(
          '...' + '.' * (_controller.value * 3).round(),
          style: GoogleFonts.poppins(fontSize: 24, color: Colors.white),
        );
      },
    );
  }
}
