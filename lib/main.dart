import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_semestre/rootScreen.dart';
import 'package:app_semestre/signIn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = new FlutterSecureStorage();
  String? token = await storage.read(key: 'token');
  print(token);

  runApp(MyApp(token: token));
}

class MyApp extends StatelessWidget {
  final String? token;

  MyApp({this.token});

  Future<Map<String, dynamic>?> getUserInfo(String token) async {
    final userInfoResponse = await http.get(
      Uri.parse('http://10.0.2.2:8000/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (userInfoResponse.statusCode == 200) {
      return jsonDecode(userInfoResponse.body);
    } else {
      print(
          'Error al obtener la información del usuario: ${userInfoResponse.body}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: token == null
          ? SignIn()
          : FutureBuilder<Map<String, dynamic>?>(
              future: getUserInfo(token!),
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else {
                  if (snapshot.hasError) {
                    print('Error: ${snapshot.error}');
                    return SignIn();
                  } else if (snapshot.hasData) {
                    return RootPage(userInfo: snapshot.data!);
                  } else {
                    return SignIn();
                  }
                }
              },
            ),
    );
  }
}
