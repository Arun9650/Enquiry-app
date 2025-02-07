import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For date formatting
import '../utils/constant.dart';
import './User.dart';
import './Enquiry.dart'; // Import your Enquiry model
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class AddEnquiryScreen extends StatefulWidget {
  final User user; // Pass empId to the screen

  AddEnquiryScreen({required this.user}); // Constructor

  @override
  _AddEnquiryScreenState createState() => _AddEnquiryScreenState();
}

class _AddEnquiryScreenState extends State<AddEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _selectedCategory; // Variable to hold the selected category

  bool _isLoadingLocation = false; // Separate loading state for location
  bool _isLoadingEnquiry = false; // Separate loading state for enquiry

  // Function to show the date picker for DOB
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

  // Function to get the current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true; // Set loading to true
    });

    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Location services are disabled.'),
      ));
      setState(() {
        _isLoadingLocation = false; // Reset loading state
      });
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Location permissions are denied.'),
        ));
        setState(() {
          _isLoadingLocation = false; // Reset loading state
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Location permissions are permanently denied.'),
      ));
      setState(() {
        _isLoadingLocation = false; // Reset loading state
      });
      return;
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Update latitude and longitude fields
    setState(() {
      _latitudeController.text = position.latitude.toString();
      _longitudeController.text = position.longitude.toString();
      _isLoadingLocation = false; // Reset loading state after getting location
    });
  }

  bool _validateDateFormat(String date) {
    try {
      final parsedDate = DateFormat('dd/MM/yyyy').parseStrict(date);
      print(parsedDate);
      return parsedDate
          .isBefore(DateTime.now()); // Ensure date is not in the future
    } catch (e) {
      return false; // Return false if parsing fails
    }
  }

  Future<void> _refetchEnquiries() async {
    final String apiUrl = '$backendBaseUrl/enquiries/${widget.user.empid}';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      List<Enquiry> updatedEnquiries = (jsonDecode(response.body) as List)
          .map((data) => Enquiry.fromJson(data))
          .toList();

      // Send back the updated enquiries to the previous screen
      Navigator.pop(context, updatedEnquiries);
    } else {
      _showErrorDialog('Error', 'Failed to refresh enquiries.');
    }
  }

  void _saveNewEnquiry() async {
    setState(() {
      _isLoadingEnquiry = true; // Set loading to true
    });

    final String apiUrl =
        '$backendBaseUrl/enquiry/${widget.user.empid}'; // Update URL to include empid

    try {
      // Validate the form first
      if (_formKey.currentState!.validate()) {
        // Convert the _dobController.text value to yyyy-MM-dd
        final dob = DateFormat('yyyy-MM-dd')
            .format(DateFormat('dd/MM/yyyy').parse(_dobController.text));
        // Prepare the new enquiry data
        final newEnquiry = {
          'custname': _nameController.text,
          'custphoneno': _phoneController.text,
          'custemailid': _emailController.text,
          'custaddress': _addressController.text,
          'latitude': _latitudeController.text,
          'longitude': _longitudeController.text,
          'entrytime': DateTime.now().toString(),
          'empname': widget.user.empname,
          'DOB': dob, // Send the DOB
          'category': _selectedCategory, // Include the selected category
        };

        // Check for null or empty values before sending
        for (var entry in newEnquiry.entries) {
          if (entry.value != null && entry.value!.isEmpty) { // Added null check
            // Updated condition
            _showErrorDialog('Error', '${entry.key} cannot be empty.');
            setState(() {
              _isLoadingEnquiry = false; // Reset loading state
            });
            return; // Exit the method if any field is empty
          }
        }

        // Debug print to check the values being sent
        print('New Enquiry Data: $newEnquiry');

        // Make the POST request
        final response = await http
            .post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(newEnquiry),
        )
            .timeout(Duration(seconds: 10), onTimeout: () {
          setState(() {
            _isLoadingEnquiry = false; // Reset loading state on timeout
          });
          return http.Response('Error', 408);
        });

        if (response.statusCode == 201) {
          await _refetchEnquiries(); // Refetch the enquiries after successful addition
        } else {
          _showErrorDialog('Error', 'Failed to add enquiry: ${response.body}');
        }
      }
    } catch (error) {
      print('Error: $error');
      _showErrorDialog('Error', 'An error occurred: $error');
    } finally {
      setState(() {
        _isLoadingEnquiry = false; // Reset loading state
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
        title: Text('Add New Enquiry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Customer Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a customer name';
                  }
                  return null;
                },
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
                              'Please enter a valid date in dd/MM/yyyy format.',
                              'invalid date format');
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
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Customer Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Customer Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Customer Address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _latitudeController,
                decoration: InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter latitude';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _longitudeController,
                decoration: InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter longitude';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoadingLocation
                    ? null
                    : _getCurrentLocation, // Disable button if loading
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingLocation)
                      CircularProgressIndicator()
                    else
                      Text('Get Current Location'),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoadingEnquiry
                    ? null
                    : _saveNewEnquiry, // Disable button if loading
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingEnquiry)
                      CircularProgressIndicator()
                    else
                      Text('Save Enquiry'),
                  ],
                ),
              ),
              // Add the category dropdown
             
            ],
          ),
        ),
      ),
    );
  }
}
