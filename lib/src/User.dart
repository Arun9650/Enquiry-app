class User {
  int empid;
  String empname;
  String status;
  String empphoneno;
  String empusername;
  String emppassword;
  String empemailid;

  User({
    required this.empid,
    required this.empname,
    required this.status,
    required this.empphoneno,
    required this.empusername,
    required this.emppassword,
    required this.empemailid,
  });

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
