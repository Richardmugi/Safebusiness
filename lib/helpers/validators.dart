

String? isPinValid(String? value) {
  // Regular expression to match a 5-digit PIN
  final pinRegex = RegExp(r'^\d{5}$');

  // Check if the PIN matches the regular expression
  String? pinCheck = pinRegex.hasMatch(value ?? "")
      ? null
      : "PIN must be exactly 5 digits long";

  if (value == null || value.isEmpty) {
    return 'Field is required';
  }
  return pinCheck;
}

class Validators {
  // Validate if the designation is not empty and has a minimum length
  String? validateDesignation(String? value) {
    if (value!.isEmpty) {
      return 'Designation is required';
    }
    if (value.length < 2) {
      return 'Designation must be at least 2 characters';
    }
    return null; // Return null if the input is valid
  }

  // Validate if the company ID is not empty and has a minimum length
  String? validateCompanyId(String? value) {
    if (value!.isEmpty) {
      return 'Company ID is required';
    }
    if (value.length < 2) {
      return 'Company ID must be at least 2 characters';
    }
    return null; // Return null if the input is valid
  }

  // Validate if the name is not empty and has a minimum length
  String? validateName(String? value) {
    if (value!.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null; // Return null if the input is valid
  }

  // Validate if the phone number is not empty and matches the pattern
  String? validatePhoneNumber(String? value) {
    String p = r'(^(?:[+0]9)?[0-9]{10,12}$)';
    if (value!.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(p).hasMatch(value)) {
      return 'Invalid phone number';
    }
    return null; // Return null if the input is valid
  }

  // Validate if the confirm PIN matches the original PIN
  static String? validateConfirmPin(String? value, String? pin) {
    if (value == null || value.isEmpty) {
      return 'Confirm PIN is required';
    }
    if (value.length != 5) {
      return 'Confirm PIN must be exactly 5 digits';
    }
    if (value != pin) {
      return 'Confirm PIN must match the original PIN';
    }
    return null; // Return null if the input is valid
  }
}