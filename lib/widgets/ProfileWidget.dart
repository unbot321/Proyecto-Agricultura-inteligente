import 'package:app_semestre/utils/constanst.dart';
import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color; // Parámetro opcional para el color
  final VoidCallback? onTap; // Parámetro opcional para la función onTap

  const ProfileWidget({
    Key? key,
    required this.icon,
    required this.title,
    this.color, // Inicializa el color aquí
    this.onTap, // Inicializa la función onTap aquí
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Usa la función onTap aquí
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color ??
                      Constants.blackColor.withOpacity(.5), // Usa el color aquí
                  size: 24,
                ),
                const SizedBox(
                  width: 16,
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: color ?? Constants.blackColor, // Usa el color aquí
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color ??
                  Constants.blackColor.withOpacity(.4), // Usa el color aquí
              size: 16,
            )
          ],
        ),
      ),
    );
  }
}
