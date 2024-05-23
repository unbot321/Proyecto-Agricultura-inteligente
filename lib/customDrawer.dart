import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final Function onClose;
  final Function onLogout;
  final Function onDeleteAccount;
  final Function onEditProfile;

  CustomDrawer({
    required this.onClose,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage("assets/profileIcon.png"),
                ),
                SizedBox(height: 10),
                Text(
                  'Hola, Usuario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          // ListTile(
          //   leading: Icon(Icons.edit),
          //   title: Text('Editar Perfil'),
          //   onTap: () {
          //     onEditProfile();
          //     onClose();
          //   },
          // ),
          ListTile(
            leading: Icon(Icons.delete),
            title: Text('Borrar Cuenta'),
            onTap: () {
              onDeleteAccount();
              onClose();
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Cerrar Sesión'),
            onTap: () {
              onLogout();
              onClose();
            },
          ),
        ],
      ),
    );
  }
}
