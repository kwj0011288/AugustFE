class UserDetails {
  final int id;
  final String email;
  final String name;
  final Institution? institution; // Make nullable
  final Department? department; // Make nullable
  final String profileImage;
  final String yearInSchool;
  final String dateJoined;

  UserDetails({
    required this.id,
    required this.email,
    required this.name,
    this.institution, // Updated to be nullable
    this.department, // Updated to be nullable
    required this.profileImage,
    required this.yearInSchool,
    required this.dateJoined,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      institution: json['institution'] != null
          ? Institution.fromJson(json['institution'])
          : null,
      department: json['department'] != null
          ? Department.fromJson(json['department'])
          : null,
      profileImage: json['profile_image'],
      yearInSchool: json['year_in_school'],
      dateJoined: json['date_joined'],
    );
  }
}

class Institution {
  final int id;
  final String fullName;
  final String nickname;

  Institution(
      {required this.id, required this.fullName, required this.nickname});

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'],
      fullName: json['full_name'],
      nickname: json['nickname'],
    );
  }
}

class Department {
  final int id;
  final String fullName;
  final String nickname;
  final int institutionId;

  Department(
      {required this.id,
      required this.fullName,
      required this.nickname,
      required this.institutionId});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      fullName: json['full_name'],
      nickname: json['nickname'],
      institutionId: json['institution'],
    );
  }
}
