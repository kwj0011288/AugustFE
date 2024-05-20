class Schedule {
  List<ScheduleList>? courses;

  Schedule({this.courses});

  Schedule.fromJson(List<dynamic> json) {
    courses = json
        .map((c) => ScheduleList.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  List<dynamic> toJson() {
    return this.courses?.map((c) => c.toJson()).toList() ?? [];
  }
}

class ScheduleList {
  int? id;
  String? name;
  List<String>? instructors;
  List<ScheduleMeeting>? meetings;
  String? courseCode;
  String? sectionCode;
  int? credits;
  int? seats;
  int? openSeats;
  int? waitlist;

  ScheduleList(
      {this.id,
      this.name,
      this.instructors,
      this.meetings,
      this.courseCode,
      this.sectionCode,
      this.credits,
      this.seats,
      this.openSeats,
      this.waitlist});

  ScheduleList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    courseCode = json['course_code'];
    sectionCode = json['section_code'];
    instructors = List<String>.from(json['instructors']);
    meetings = List<ScheduleMeeting>.from(
        json['meetings'].map((m) => ScheduleMeeting.fromJson(m)));

    credits = json['credits'];
    seats = json['seats'];
    openSeats = json['open_seats'];
    waitlist = json['waitlist'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['instructors'] = this.instructors;
    data['meetings'] = this.meetings?.map((m) => m.toJson()).toList();
    data['course_code'] = this.courseCode;
    data['section_code'] = this.sectionCode;
    data['credits'] = this.credits;
    data['seats'] = this.seats;
    data['open_seats'] = this.openSeats;
    data['waitlist'] = this.waitlist;
    return data;
  }
}

class ScheduleMeeting {
  String? building;
  String? room;
  String? days;
  String? startTime;
  String? endTime;

  ScheduleMeeting(
      {this.building, this.room, this.days, this.startTime, this.endTime});

  ScheduleMeeting.fromJson(Map<String, dynamic> json) {
    building = json['building'];
    room = json['room'];
    days = json['days'];
    startTime = json['start_time'];
    endTime = json['end_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['building'] = this.building;
    data['room'] = this.room;
    data['days'] = this.days;
    data['start_time'] = this.startTime;
    data['end_time'] = this.endTime;

    return data;
  }
}
