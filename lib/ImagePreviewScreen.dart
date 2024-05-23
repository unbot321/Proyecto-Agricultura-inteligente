import 'dart:io';

import 'package:app_semestre/ScanScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class ImagePreviewScreen extends StatefulWidget {
  final XFile image;

  ImagePreviewScreen({required this.image});

  @override
  _ImagePreviewScreenState createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage(BuildContext context) {
    final String message = _controller.text;
    if (message.isNotEmpty) {
      Navigator.pop(context,
          Message(image: widget.image, text: message, isOwnMessage: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1, // Puedes ajustar esto según tus necesidades
                  child: Image.file(
                    File(widget.image.path),
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
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
                        maxHeight: 200.0,
                      ),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          reverse: true,
                          child: TextField(
                            controller: _controller,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(10.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.green),
                    onPressed: () {
                      _sendMessage(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
