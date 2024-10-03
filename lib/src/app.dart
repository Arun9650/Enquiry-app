import 'dart:convert';
import 'package:flutter/material.dart';

import 'UserScreen.dart'; // Import the UsersScreen
import 'User.dart';
import 'Enquiry.dart';
import 'LoginScreen.dart'; // Import the new LoginScreen
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false; // Check login status

  User? user; // Declare a User variable
  List<Enquiry> enquiries = []; // Declare a list for enquiries

  if (isLoggedIn) {
    // If logged in, retrieve user data from SharedPreferences
    String? userJson = prefs.getString('user'); // Get user data as JSON string
    if (userJson != null) {
      user = User.fromJson(jsonDecode(userJson)); // Parse user data
      // You may also want to retrieve enquiries if needed
      // For example, you could store them in SharedPreferences as well
    }
  }

  runApp(MyApp(
      isLoggedIn: isLoggedIn,
      user: user,
      enquiries: enquiries)); // Pass login status, user, and enquiries to MyApp
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn; // Add a field for login status
  final User? user; // Add a field for user
  final List<Enquiry> enquiries; // Add a field for enquiries

  MyApp(
      {required this.isLoggedIn,
      this.user,
      required this.enquiries}); // Constructor to accept login status, user, and enquiries

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      home: isLoggedIn
          ? UsersScreen(user: user!, enquiries: enquiries)
          : LoginScreen(),
      routes: {
        '/login': (context) =>
            LoginScreen(), // Define the route for LoginScreen
      }, // Show UsersScreen if logged in
    );
  }
}
