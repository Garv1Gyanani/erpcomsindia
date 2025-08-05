import 'dart:convert';

import 'package:coms_india/features/shift/models/site_shift_model.dart';

// Helper to parse the API response which has a 'data' key
List<Employee> employeeListFromJson(String str) {
  final jsonData = json.decode(str);
  return List<Employee>.from(jsonData['data'].map((x) => Employee.fromJson(x)));
}

List<Site> siteListFromJson(String str) =>
    List<Site>.from(json.decode(str)['data'].map((x) => Site.fromJson(x)));
List<SiteGroup> siteGroupListFromJson(String str) => List<SiteGroup>.from(
    json.decode(str)['data'].map((x) => SiteGroup.fromJson(x)));

class SiteGroup {
  final String site;
  final List<WeekendEmployee> employees;
  SiteGroup({required this.site, required this.employees});
  factory SiteGroup.fromJson(Map<String, dynamic> json) => SiteGroup(
      site: json["site"],
      employees: List<WeekendEmployee>.from(
          json["employees"].map((x) => WeekendEmployee.fromJson(x))));
}

class WeekendEmployee {
  final String name;
  final String phone;
  final List<String> shifts;
  final List<String> weekendDays;
  WeekendEmployee(
      {required this.name,
      required this.phone,
      required this.shifts,
      required this.weekendDays});
  factory WeekendEmployee.fromJson(Map<String, dynamic> json) =>
      WeekendEmployee(
          name: json["name"],
          phone: json["phone"],
          shifts: List<String>.from(json["shifts"].map((x) => x)),
          weekendDays: List<String>.from(json["weekend_days"].map((x) => x)));
}

class Employee {
  final int userId;

  final String name;
  final String phone;
  // This will hold the weekend days selected in the UI.
  // Using a Set prevents duplicate days and is efficient for lookups.
  Set<String> selectedDays;

  Employee({
    required this.userId,
    required this.name,
    required this.phone,
    required List<String> initialWeekendDays,
  }) : selectedDays = Set<String>.from(
            initialWeekendDays); // Initialize the Set from the list

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        userId: json["user_id"] ?? 0,

        name: json["name"],
        phone: json["phone"],
        // The API returns a list, which we use for initial setup
        initialWeekendDays:
            List<String>.from(json["weekend_days"].map((x) => x)),
      );

  // It's good practice to add these for object comparison if needed later
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          runtimeType == other.runtimeType &&
          phone == other.phone;

  @override
  int get hashCode => phone.hashCode;
}
