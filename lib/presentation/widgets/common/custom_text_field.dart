import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({super.key, required this.controller, required this.label, this.hint, this.helperText, this.validator, this.obscureText = false, this.keyboardType, this.prefixIcon, this.suffixIcon, this.onChanged, this.readOnly = false});
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      minLines: 1,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
