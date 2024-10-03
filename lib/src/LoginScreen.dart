import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'UserScreen.dart'; // Import the UsersScreen
import 'User.dart';
import 'Enquiry.dart';
import '../utils/constant.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final String apiUrl = '$backendBaseUrl/login'; // Replace with your API URL

    try {
      final payload = {
        'username': _usernameController.text,
        'password': _passwordController.text,
      };

      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(payload),
      )
          .timeout(Duration(seconds: 10), onTimeout: () {
        setState(() {
          _isLoading = false;
        });
        return http.Response('Error', 408);
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        User user = User.fromJson(data['user']); // Parse the user
        List<Enquiry> enquiries = (data['enquiries'] as List)
            .map((e) => Enquiry.fromJson(e))
            .toList(); // Parse the list of enquiries

        // Save login status and user data
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('user', jsonEncode(user.toJson())); // Save user data as JSON string
        // Optionally save enquiries if needed
        // await prefs.setString('enquiries', jsonEncode(enquiries.map((e) => e.toJson()).toList()));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UsersScreen(user: user, enquiries: enquiries),
          ),
        );
      } else {
        _showErrorDialog('Login Failed', 'Invalid username or password');
      }
    } catch (error) {
      print('An error occurred: $error');
      _showErrorDialog('Error', 'An error occurred: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}