class Enquiry {
  final int enquiryid;
  final String custname;
  final String custphoneno;
  final String custemailid;
  final String custaddress;
  final String latitude;
  final String longitude;
  final String entrytime;
  final String empname;
  final String dob;
  final String category; // Added category field

  Enquiry({
    required this.enquiryid,
    required this.custname,
    required this.custphoneno,
    required this.custemailid,
    required this.custaddress,
    required this.latitude,
    required this.longitude,
    required this.entrytime,
    required this.empname,
    required this.dob,
    required this.category, // Include category in constructor
  });

  factory Enquiry.fromJson(Map<String, dynamic> json) {
    return Enquiry(
      enquiryid: json['enquiryid'],
      custname: json['custname'],
      custphoneno: json['custphoneno'],
      custemailid: json['custemailid'],
      custaddress: json['custaddress'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      entrytime: json['entrytime'],
      empname: json['empname'],
      dob: json['DOB'],
      category: json['category'] ?? '', // Handle category
    );
  }

  // Add this method to convert Enquiry to JSON
  Map<String, dynamic> toJson() {
    return {
      'enquiryid': enquiryid,
      'custname': custname,
      'custphoneno': custphoneno,
      'custemailid': custemailid,
      'custaddress': custaddress,
      'latitude': latitude,
      'longitude': longitude,
      'entrytime': entrytime,
      'empname': empname,
      'dob': dob,
      'category': category, // Include category in JSON
    };
  }
}
