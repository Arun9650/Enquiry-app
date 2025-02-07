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
        builder: (context) =>
            AddEnquiryScreen(user: widget.user), // Pass the User object
      ),
    );

    if (newEnquiry != null) {
      setState(() {
        widget.enquiries.clear(); // Clear the old list
        widget.enquiries.addAll(newEnquiry); // Add the updated enquiries
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
      // Parse the entryTime string
      final DateTime parsedTime = DateTime.parse(entryTime);

      // Format the time to 'MMMM dd, yyyy – hh:mm a' in 12-hour format
      return DateFormat('dd/MM/yyyy – hh:mm a').format(parsedTime);
    } catch (e) {
      return entryTime; // In case of error, return the original string
    }
  }

  String _formatDOB(String dob) {
    try {
      // Parse the dob as DateTime in the local timezone
      final DateTime parsedDOB = DateTime.parse(dob).toLocal();
      return DateFormat('dd/MM/yyyy')
          .format(parsedDOB); // Format as 'Oct 03, 2024'
    } catch (e) {
      return dob; // In case of error, return the original string
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
            // User Information Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${widget.user.empname}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Phone: ${widget.user.empphoneno}',
                      style: TextStyle(fontSize: 16)),
                  Text('Email: ${widget.user.empemailid}',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Enquiries:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.enquiries.length,
                itemBuilder: (context, index) {
                  final enquiry = widget.enquiries[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(enquiry.custname,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${enquiry.custemailid}'),
                          Text('Phone: ${enquiry.custphoneno}'),
                          Text('DOB: ${_formatDOB(enquiry.dob)}'), // Format DOB
                          Text(
                              'Entry Time: ${_formatEntryTime(enquiry.entrytime)}'),
                          Text('Category: ${enquiry.category}'), // Added category
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
                    ),
                  );
                },
              ),
            ),
            Text(
              "Total Enquiries: ${widget.enquiries.length}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewEnquiry,
        child: Icon(Icons.add),
        tooltip: 'Add New Enquiry',
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
