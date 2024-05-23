import 'package:app_semestre/models/User.dart';
import 'package:app_semestre/signIn.dart';
import 'package:app_semestre/utils/constanst.dart';
import 'package:app_semestre/widgets/ProfileWidget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:page_transition/page_transition.dart';

class ProfileScreen extends StatefulWidget {
  final User userInfo;

  ProfileScreen({required this.userInfo});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final storage = new FlutterSecureStorage();

  Future<void> logout(BuildContext context, bool isDialog) async {
    if (isDialog) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Theme(
            data: ThemeData(
              brightness: Brightness.light,
              useMaterial3: true,
              colorSchemeSeed: Colors.red,
              dialogTheme: DialogTheme(
                surfaceTintColor: Colors.grey.shade300,
              ),
            ),
            child: AlertDialog(
              title: Center(child: Text('Confirmación')),
              content: Text(
                '¿Estás seguro de que quieres cerrar sesión?',
                style: TextStyle(fontSize: 18),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Aceptar'),
                  onPressed: () async {
                    await storage.delete(key: 'token');

                    Navigator.pushAndRemoveUntil(
                      context,
                      PageTransition(
                          child: SignIn(),
                          type: PageTransitionType.topToBottom),
                      (Route<dynamic> route) => false,
                    );

                    print('Has cerrado sesión exitosamente.');
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      await storage.delete(key: 'token');

      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(child: SignIn(), type: PageTransitionType.topToBottom),
        (Route<dynamic> route) => false,
      );
      print('Has cerrado sesión exitosamente.');
    }
  }

  void editProfile() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                Divider(
                  height: 12.0,
                  thickness: 2.0,
                ),
                Text(
                  'Editar perfil',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Cambiar nombre',
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Cambiar nombre de usuario',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Solicitar cambio de email
                  },
                  child: Text('Solicitar cambio de email'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Solicitar cambio de contraseña
                  },
                  child: Text('Solicitar cambio de contraseña'),
                ),
                Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () {
                      // Guardar cambios
                    },
                    child: Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteUser(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
            data: ThemeData(
                brightness: Brightness.light,
                useMaterial3: true,
                colorSchemeSeed: Colors.red,
                dialogTheme:
                    DialogTheme(surfaceTintColor: Colors.grey.shade300)),
            child: AlertDialog(
              title: Center(child: Text('Confirmación')),
              content: Text('¿Estás seguro de que quieres eliminar tu cuenta?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    'Aceptar',
                  ),
                  onPressed: () async {
                    var token = await storage.read(key: 'token');
                    final response = await http.delete(
                      Uri.parse('http://10.0.2.2:8000/deleteUser'),
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                        'Authorization': 'Bearer $token',
                      },
                    );

                    if (response.statusCode == 200) {
                      print('Usuario eliminado exitosamente.');
                      await logout(context, false);
                    } else {
                      throw Exception('Error al eliminar el usuario.');
                    }
                  },
                ),
              ],
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 150,
            child: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.5),
              radius: 60,
              backgroundImage: ExactAssetImage('assets/profileIcon.png'),
            ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Constants.primaryColor.withOpacity(.5),
                width: 5.0,
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            widget.userInfo.name,
            style: TextStyle(
              color: Constants.blackColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '@${widget.userInfo.userName}',
            style: TextStyle(
              color: Constants.blackColor.withOpacity(.3),
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.userInfo.email,
            style: TextStyle(
              color: Constants.blackColor.withOpacity(.3),
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 30,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfileWidget(
                icon: Icons.logout,
                title: 'Cerrar Sesion',
                color: Colors.red,
                onTap: () => logout(context, true),
              ),
              ProfileWidget(
                icon: Icons.delete,
                title: 'Eliminar cuenta',
                color: Colors.red,
                onTap: () => deleteUser(context),
              ),
            ],
          ),
        ],
      ),
    )));
  }
}
