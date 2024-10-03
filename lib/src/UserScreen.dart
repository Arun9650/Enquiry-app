import 'package:flutter/material.dart';
import 'User.dart';
import 'Enquiry.dart';
import 'EnquiryDetailsScreen.dart'; // Import the details screen
import 'AddEnquiryScreen.dart'; // Import the add enquiry screen
import 'package:maps_launcher/maps_launcher.dart'; // Import the maps launcher package
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for managing logged-in status

class UsersScreen extends StatefulWidget {
  final User user;
  final List<Enquiry> enquiries;

  UsersScreen({required this.user, required this.enquiries});

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // Function to add new enquiry
  void _addNewEnquiry() async {
    final newEnquiry = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEnquiryScreen(),
      ),
    );

    if (newEnquiry != null) {
      setState(() {
        // Add the new enquiry to the list
        widget.enquiries.add(
          Enquiry(
            enquiryid: widget.enquiries.length + 1,
            custname: newEnquiry['custname'],
            custphoneno: newEnquiry['custphoneno'],
            custemailid: newEnquiry['custemailid'],
            custaddress: newEnquiry['custaddress'],
            latitude: newEnquiry['latitude'],
            longitude: newEnquiry['longitude'],
            entrytime: newEnquiry['entrytime'],
            empname: widget.user.empname,
            dob: "", // Add if needed
          ),
        );
      });
    }
  }

  // Function to log out the user
  void _logOut() async {
    // Clear the logged-in state
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    // Navigate back to the login page
    Navigator.pushReplacementNamed(context, '/login');
  }

  String _formatEntryTime(String entryTime) {
    try {
      final DateTime parsedTime = DateTime.parse(entryTime);
      return DateFormat('MMMM dd, yyyy – hh:mm a').format(parsedTime);
    } catch (e) {
      return entryTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User: ${widget.user.empname}'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logOut, // Call logout function
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.user.empname}'),
            Text('Phone: ${widget.user.empphoneno}'),
            Text('Email: ${widget.user.empemailid}'),
            SizedBox(height: 20),
            Text(
              'Enquiries:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.enquiries.length,
                itemBuilder: (context, index) {
                  final enquiry = widget.enquiries[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${enquiry.custemailid}'),
                          Text('Phone: ${enquiry.custphoneno}'),
                          Text('DOB: ${_formatEntryTime(enquiry.dob)}'),
                          Text(
                              'Entry Time: ${_formatEntryTime(enquiry.entrytime)}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.map),
                        onPressed: () {
                          if (enquiry.latitude != null &&
                              enquiry.longitude != null) {
                            MapsLauncher.launchCoordinates(
                              double.parse(enquiry.latitude),
                              double.parse(enquiry.longitude),
                              enquiry.custaddress,
                            );
                          } else {
                            print('Invalid coordinates');
                          }
                        },
                      ),
                      onTap: () async {
                        final updatedEnquiry = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EnquiryDetailsScreen(enquiry: enquiry),
                          ),
                        );

                        if (updatedEnquiry != null) {
                          setState(() {
                            widget.enquiries[index] = updatedEnquiry;
                          });
                        }
                      },
                      title: Text(enquiry.custname),
                    ),
                  );
                },
              ),
            ),
            Text(
              "Total Enquiries: ${widget.enquiries.length}",
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewEnquiry,
        child: Icon(Icons.add),
        tooltip: 'Add New Enquiry',
      ),
    );
  }
}
