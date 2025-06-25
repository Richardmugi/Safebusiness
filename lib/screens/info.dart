import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safebusiness/widgets/action_button.dart';

class UserInfoFormPage extends StatefulWidget {
  const UserInfoFormPage({super.key});

  @override
  State<UserInfoFormPage> createState() => _UserInfoFormPageState();
}

class _UserInfoFormPageState extends State<UserInfoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final contact = _contactController.text.trim();
      final address = _addressController.text.trim();

      // Process or send the info here
      print('Name: $name');
      print('Contact: $contact');
      print('Address: $address');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Info submitted successfully!')),
      );

      // Optionally clear the form
      _formKey.currentState!.reset();
      _nameController.clear();
      _contactController.clear();
      _addressController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_outlined, size: 20, color: Colors.white),
        ),
        title: Text(
          'Add your Info',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF4B0000),
      ),
      backgroundColor: Colors.transparent, // Let the container handle the color
    body: Container(
  width: double.infinity,
  height: MediaQuery.of(context).size.height,
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF4B0000), // Deep Burgundy
        Color(0xFFF80101), // Dark Red
        Color(0xFF8B0000),
      ],
    ),
  ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Please fill in your details:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(
      color: Colors.white, // 🔸 Set your desired color here
      fontWeight: FontWeight.w500,
    ),
                  border: OutlineInputBorder(borderSide: BorderSide(
        color: Colors.white, // your desired border color
        width: 2.0,         // optional: border thickness
      ),),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  labelStyle: TextStyle(
      color: Colors.white, // 🔸 Set your desired color here
      fontWeight: FontWeight.w500,
    ),
                  border: OutlineInputBorder(borderSide: BorderSide(
        color: Colors.white, // your desired border color
        width: 2.0,         // optional: border thickness
      ),),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a valid contact' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(
      color: Colors.white, // 🔸 Set your desired color here
      fontWeight: FontWeight.w500,
    ),
                  border: OutlineInputBorder(borderSide: BorderSide(
        color: Colors.white, // your desired border color
        width: 2.0,         // optional: border thickness
      ),),
                ),
                maxLines: 2,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter your address' : null,
              ),
              const SizedBox(height: 30),
              ActionButton(
                            onPressed: () {
                              _submitForm(
                              );
                            },
                            actionText: "Submit",
                          ),
              /*ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Submit', style: TextStyle(fontSize: 16)),
              ),*/
            ],
          ),
        ),
      ),
    ),
    );
  }
}
