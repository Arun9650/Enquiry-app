import 'package:flutter/material.dart';
import 'Enquiry.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // Import geolocator package
import '../utils/constant.dart';

class EnquiryDetailsScreen extends StatefulWidget {
  final Enquiry enquiry;

  EnquiryDetailsScreen({required this.enquiry});

  @override
  _EnquiryDetailsScreenState createState() => _EnquiryDetailsScreenState();
}

class _EnquiryDetailsScreenState extends State<EnquiryDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _empnameController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  bool _isLoading = false; // Loading state flag

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.enquiry.custname);
    _phoneController = TextEditingController(text: widget.enquiry.custphoneno);
    _emailController = TextEditingController(text: widget.enquiry.custemailid);
    _addressController =
        TextEditingController(text: widget.enquiry.custaddress);
    _empnameController = TextEditingController(text: widget.enquiry.empname);
    _latitudeController = TextEditingController(text: widget.enquiry.latitude);
    _longitudeController =
        TextEditingController(text: widget.enquiry.longitude);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _empnameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  // Function to get current location (latitude and longitude)
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog(
          'Location services are disabled. Please enable the services.');
      return;
    }

    // Check for location permission and request if not granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog(
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    // Get the current position (latitude and longitude)
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _latitudeController.text = position.latitude.toString();
      _longitudeController.text = position.longitude.toString();
    });
  }

  // Function to save the edited enquiry details
  Future<void> _saveEnquiryDetails() async {
    setState(() {
      _isLoading = true; // Start loading state
    });

    final String apiUrl =
        '$backendBaseUrl/enquiries/${widget.enquiry.enquiryid}';

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'empname': _empnameController.text,
          'custname': _nameController.text,
          'custphoneno': _phoneController.text,
          'custemailid': _emailController.text,
          'custaddress': _addressController.text,
          'latitude': _latitudeController.text,
          'longitude': _longitudeController.text,
        }),
      );

      if (response.statusCode == 200) {
        final updatedEnquiry = Enquiry(
          enquiryid: widget.enquiry.enquiryid,
          custname: _nameController.text,
          custphoneno: _phoneController.text,
          custemailid: _emailController.text,
          custaddress: _addressController.text,
          latitude: widget.enquiry.latitude,
          longitude: widget.enquiry.longitude,
          entrytime: widget.enquiry.entrytime,
          empname: _empnameController.text,
          dob: widget.enquiry.dob,
        );
        Navigator.pop(context, updatedEnquiry);
      } else {
        _showErrorDialog('Failed to save changes. Please try again later.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred while saving the changes.');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading state
      });
    }
  }

  // Function to show an error dialog
  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
        title: Text('Edit Enquiry'),
      ),
      body: SingleChildScrollView(
        // Wrap with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _empnameController,
                decoration: InputDecoration(labelText: 'Employee Name'),
              ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Customer Name'),
              ),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Customer Phone'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Customer Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Customer Address'),
              ),
              TextField(
                controller: _latitudeController,
                decoration: InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: _longitudeController,
                decoration: InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 20),
              // Button for Get Current Location
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _getCurrentLocation,
                  child: Text('Get Current Location'),
                ),
              ),
              SizedBox(height: 20),
              // Display loading spinner if saving, otherwise show Save Changes button
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveEnquiryDetails,
                        child: Text('Save Changes'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
