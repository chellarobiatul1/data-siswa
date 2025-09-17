import 'package:flutter/material.dart';

Widget buildTextField({
  required String label,
  required String keyName,
  TextInputType inputType = TextInputType.text,
  bool requiredField = true,
  TextEditingController? controller,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF6C5B7B),
          fontWeight: FontWeight.bold,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF6C5B7B), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFEBEBEB), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (requiredField && (value == null || value.isEmpty)) {
          return 'Field $label wajib diisi';
        }
        return null;
      },
    ),
  );
}
