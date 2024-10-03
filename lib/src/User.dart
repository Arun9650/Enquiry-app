class User {
  final int empid;
  final String empname;
  final String status;
  final String empphoneno;
  final String empusername;
  final String emppassword;
  final String empemailid;

  User({
    required this.empid,
    required this.empname,
    required this.status,
    required this.empphoneno,
    required this.empusername,
    required this.emppassword,
    required this.empemailid,
  });

  // Method to convert User object to JSON
  Map<String, dynamic> toJson() {
    return {
      'empid': empid,
      'empname': empname,
      'status': status,
      'empphoneno': empphoneno,
      'empusername': empusername,
      'emppassword': emppassword,
      'empemailid': empemailid,
    };
  }

  // Factory method to create a User from JSON, handling null values
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      empid: json['empid'] ?? 0, // Default value for integers
      empname: json['empname'] ?? '', // Default value for strings
      status: json['status'] ?? '',
      empphoneno: json['empphoneno'] ?? '',
      empusername: json['empusername'] ?? '',
      emppassword: json['emppassword'] ?? '',
      empemailid: json['empemailid'] ?? '',
    );
  }
}
