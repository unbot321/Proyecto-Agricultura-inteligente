import 'package:app_semestre/utils/constanst.dart';
import 'package:flutter/material.dart';

class CustomTextfield extends StatefulWidget {
  final TextEditingController controller;
  final bool notSpaces;
  final bool obscureText;
  final IconData icon;
  final String hintText;

  const CustomTextfield({
    Key? key,
    required this.controller,
    this.notSpaces = false,
    required this.obscureText,
    required this.icon,
    required this.hintText,
  }) : super(key: key);

  @override
  _CustomTextfieldState createState() => _CustomTextfieldState();
}

class _CustomTextfieldState extends State<CustomTextfield> {
  bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.obscureText ? obscureText : false,
      onChanged: (value) {
        if (widget.notSpaces) {
          widget.controller.text = value.replaceAll(' ', '').trim();
        }
      },
      style: TextStyle(
        color: Constants.blackColor,
      ),
      decoration: InputDecoration(
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    obscureText = !obscureText;
                  });
                },
              )
            : null,
        border: InputBorder.none,
        prefixIcon: Icon(
          widget.icon,
          color: Constants.blackColor.withOpacity(.3),
        ),
        hintText: widget.hintText,
      ),
      cursorColor: Constants.blackColor.withOpacity(.5),
    );
  }
}
