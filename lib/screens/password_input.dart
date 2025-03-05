import 'package:flutter/material.dart';


class PasswordInputField extends StatefulWidget {
  final TextEditingController controller;

  const PasswordInputField({super.key, required this.controller, required String hintText});

  @override
  _PasswordInputFieldState createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());

  @override
  void initState() {
    super.initState();
    for (var controller in _controllers) {
      controller.addListener(() {
        _onTextChanged();
      });
    }
  }

  void _onTextChanged() {
    // Check if all boxes are filled
    if (_controllers.every((controller) => controller.text.isNotEmpty)) {
      // Combine the text from all controllers into a single string
      String password = _controllers.map((controller) => controller.text).join();
      widget.controller.text = password; // Update the main controller
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter PIN",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey, // You can change this color as needed
          ),
        ),
        SizedBox(height: 10), // Add some space between the label and the input boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _controllers[index],
                textAlign: TextAlign.center,
                maxLength: 1,
                obscureText: true, // Hide the input
                style: TextStyle(color: Colors.red), // Set the text color to red
                decoration: InputDecoration(
                  border: InputBorder.none,
                  counterText: '', // Hide the character counter
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.length == 1) {
                    // Move to the next box if the current box is filled
                    if (index < 3) {
                      FocusScope.of(context).nextFocus();
                    }
                  } else if (value.isEmpty && index > 0) {
                    // Move to the previous box if the current box is empty
                    FocusScope.of(context).previousFocus();
                  }
                },
              ),
            );
          }),
        ),
      ],
    );
  }
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}