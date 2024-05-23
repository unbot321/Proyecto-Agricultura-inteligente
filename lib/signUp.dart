import 'dart:convert';

import 'package:app_semestre/rootScreen.dart';
import 'package:app_semestre/signIn.dart';
import 'package:app_semestre/utils/constanst.dart';
import 'package:app_semestre/widgets/customTextField.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

class SignUp extends StatelessWidget {
  SignUp({Key? key}) : super(key: key);

  TextEditingController credentialController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  final storage = new FlutterSecureStorage();
  void validateAndSubmit(BuildContext context) async {
    String errorMessage = '';
    if (credentialController.text.isEmpty &&
        fullNameController.text.isEmpty &&
        usernameController.text.isEmpty &&
        passwordController.text.isEmpty) {
      errorMessage = 'Error: Completa todos los campos';
    } else if (credentialController.text.isEmpty) {
      errorMessage = 'Error: Completa el campo de email';
    } else if (fullNameController.text.isEmpty) {
      errorMessage = 'Error: Completa el campo de nombre de usuario';
    } else if (usernameController.text.isEmpty) {
      errorMessage = 'Error: Completa el campo de nombre completo';
    } else if (passwordController.text.isEmpty) {
      errorMessage = 'Error: Completa el campo de contraseña';
    }

    if (errorMessage.isNotEmpty) {
      showSnackBar(context, errorMessage);
    } else {
      try {
        print('hola');
        final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/register'),
          body: jsonEncode({
            'id': '1',
            'userName': usernameController.text,
            'name': fullNameController.text,
            'password': passwordController.text,
            'email': credentialController.text,
            'credential': ''
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> responseBody = jsonDecode(response.body);
          await storage.write(
              key: 'token', value: responseBody['access_token']);
          print('Usuario registrado con éxito');

          // Get user info
          final userInfoResponse = await http.get(
            Uri.parse('http://10.0.2.2:8000/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${responseBody['access_token']}',
            },
          );

          if (userInfoResponse.statusCode == 200) {
            Map<String, dynamic> userInfo = jsonDecode(userInfoResponse.body);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RootPage(userInfo: userInfo),
              ),
            );
          } else {
            showSnackBar(
                context, 'Error al obtener la información del usuario');
          }
        } else {
          Map<String, dynamic> responseBody =
              jsonDecode(utf8.decode(response.bodyBytes));
          showSnackBar(context, 'Error: ${responseBody['detail']['message']}');
        }
      } catch (e) {
        showSnackBar(context, 'No fue posible conectarse con el servidor');
      }
    }
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.06),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(height: 10),
              Flexible(
                child: Text(message,
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/createAccount.png'),
              const Text(
                'Registro',
                style: TextStyle(
                  fontSize: 35.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              CustomTextfield(
                controller: credentialController,
                obscureText: false,
                hintText: 'Ingresa email',
                icon: Icons.alternate_email,
              ),
              CustomTextfield(
                controller: usernameController,
                obscureText: false,
                hintText: 'Ingresa nombre de usuario',
                icon: Icons.person,
              ),
              CustomTextfield(
                controller: fullNameController,
                obscureText: false,
                hintText: 'Ingresa nombre completo',
                icon: Icons.person,
              ),
              CustomTextfield(
                controller: passwordController,
                obscureText: true,
                hintText: 'Ingresa contraseña',
                icon: Icons.lock,
              ),
              const SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: () {
                  validateAndSubmit(context);
                },
                child: Container(
                  width: size.width,
                  decoration: BoxDecoration(
                    color: Constants.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: const Center(
                    child: Text(
                      'Registrarme',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              // Row(
              //   children: const [
              //     Expanded(child: Divider()),
              //     Padding(
              //       padding: EdgeInsets.symmetric(horizontal: 10),
              //       child: Text('OR'),
              //     ),
              //     Expanded(child: Divider()),
              //   ],
              // ),
              // const SizedBox(
              //   height: 20,
              // ),
              // Container(
              //   width: size.width,
              //   decoration: BoxDecoration(
              //       border: Border.all(color: Constants.primaryColor),
              //       borderRadius: BorderRadius.circular(10)),
              //   padding:
              //       const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceAround,
              //     children: [
              //       SizedBox(
              //         height: 30,
              //         child: Image.asset('assets/google.png'),
              //       ),
              //       Text(
              //         'Sign Up with Google',
              //         style: TextStyle(
              //           color: Constants.blackColor,
              //           fontSize: 18.0,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(
              //   height: 20,
              // ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      PageTransition(
                          child: SignIn(),
                          type: PageTransitionType.bottomToTop));
                },
                child: Center(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: 'Have an Account? ',
                        style: TextStyle(
                          color: Constants.blackColor,
                        ),
                      ),
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(
                          color: Constants.primaryColor,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
