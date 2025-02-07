import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'Enquiry.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // Import geolocator package
import '../utils/constant.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

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
  late TextEditingController _dobController;
  String? _selectedCategory;

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

    _selectedCategory = widget.enquiry.category;

    print(widget.enquiry.dob);

    try {
      String dob = widget.enquiry.dob;
      DateTime parsedDate;

      if (dob.contains('/')) {
        // Parse as dd/MM/yyyy
        parsedDate = DateFormat('dd/MM/yyyy').parse(dob);
      } else if (dob.contains('-')) {
        // Parse as yyyy-MM-dd
        parsedDate = DateFormat('yyyy-MM-dd').parse(dob);
      } else {
        throw FormatException("Unknown date format: $dob");
      }

      _dobController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(parsedDate),
      );
    } catch (e) {
      print("Error parsing DOB: ${widget.enquiry.dob}, $e");
      _dobController = TextEditingController(); // Set to empty if parsing fails
    }
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
    _dobController.dispose();
    super.dispose();
  }

  // Function to show the date picker for DOB
  Future<void> _selectDate(BuildContext context) async {
    final List<DateTime?>? pickedDates = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      ),
      dialogSize: const Size(300, 400),
    );

    if (pickedDates != null &&
        pickedDates.isNotEmpty &&
        pickedDates[0] != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(pickedDates[0]!);
      });
    }
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

    final dob = _dobController.text;
    if (dob.length != 10) {
      _showErrorDialog('Please enter a complete date in dd/MM/yyyy format.');
      return; // Stop execution if the date is incomplete
    }

    final formattedDob =
        DateFormat('yyyy-MM-dd').format(DateFormat('dd/MM/yyyy').parse(dob));

    print(_dobController.text);
    print(formattedDob);

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'empname': _empnameController.text,
          'custname': _nameController.text,
          'category': _selectedCategory ??
              'Other', // {{ edit_1 }} Provide a default value for 'category'
          'custphoneno': _phoneController.text,
          'custemailid': _emailController.text,
          'custaddress': _addressController.text,
          'latitude': _latitudeController.text,
          'longitude': _longitudeController.text,
          'DOB': formattedDob,
        }),
      );

      if (response.statusCode == 200) {
        final updatedEnquiry = Enquiry(
          enquiryid: widget.enquiry.enquiryid,
          custname: _nameController.text,
          category: _selectedCategory ??
              'Other', // {{ edit_1 }} Add the required 'category' parameter
          custphoneno: _phoneController.text,
          custemailid: _emailController.text,
          custaddress: _addressController.text,
          latitude: widget.enquiry.latitude,
          longitude: widget.enquiry.longitude,
          entrytime: widget.enquiry.entrytime,
          empname: _empnameController.text,
          dob: _dobController.text,
        );
        Navigator.pop(context, updatedEnquiry);
      } else {
        _showErrorDialog('Failed to save changes. Please try again later.');
      }
    } catch (e) {
      print(e);
      _showErrorDialog('An error occurred while saving the changes.');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading state
      });
    }
  }

  Future<void> launchPhoneDialer(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showErrorDialog('Could not open the dialer.');
    }
  }

  bool _validateDateFormat(String date) {
    if (date.length != 10) {
      return false; // Immediately return false if length is incorrect
    }

    try {
      final parsedDate = DateFormat('dd/MM/yyyy').parseStrict(date);
      return parsedDate
          .isBefore(DateTime.now()); // Ensure date is not in the future
    } catch (e) {
      return false; // Return false if parsing fails
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
                readOnly: true,
              ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Customer Name'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dobController,
                      decoration:
                          InputDecoration(labelText: 'Customer Date of Birth'),
                      keyboardType: TextInputType.datetime,
                      onEditingComplete: () {
                        final value = _dobController.text;
                        // Validate the entered date format after user finishes editing
                        final bool isValidDate = _validateDateFormat(value);
                        if (!isValidDate && value.isNotEmpty) {
                          _showErrorDialog(
                              'Please enter a valid date in dd/MM/yyyy format.');
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a customer Date of Birth';
                        }
                        if (!_validateDateFormat(value)) {
                          return 'Invalid Date of Birth';
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      await _selectDate(
                          context); // Open the date picker dialog when the icon is pressed
                    },
                  ),
                ],
              ),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: 'Category'),
                items: <String>['Cable TV', 'Internet', 'Other']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue; // Update selected category
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Customer Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.phone),
                    onPressed: () {
                      final phoneNumber = _phoneController.text;
                      if (phoneNumber.isNotEmpty) {
                        launchPhoneDialer(phoneNumber);
                      } else {
                        _showErrorDialog('Please enter a phone number.');
                      }
                    },
                  ),
                ],
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
