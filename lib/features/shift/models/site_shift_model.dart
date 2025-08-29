import 'dart:convert';

List<Site> siteListFromJson(String str) {
  final jsonData = json.decode(str);
  return List<Site>.from(jsonData['data'].map((x) => Site.fromJson(x)));
}

class Site {
  final int siteId;
  final String siteName;
  final List<Shift> shifts;

  Site({
    required this.siteId,
    required this.siteName,
    required this.shifts,
  });

  factory Site.fromJson(Map<String, dynamic> json) => Site(
        siteId: json["site_id"],
        siteName: json["site_name"],
        shifts: List<Shift>.from(json["shifts"].map((x) => Shift.fromJson(x))),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Site &&
          runtimeType == other.runtimeType &&
          siteId == other.siteId;

  @override
  int get hashCode => siteId.hashCode;
}

class Shift {
  final int shiftId;
  final String shiftName;
  final String startTime; // Add this
  final String endTime; // Add this

  Shift({
    required this.shiftId,
    required this.shiftName,
    required this.startTime, // Add this
    required this.endTime, // Add this
  });

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        shiftId: json["shift_id"],
        shiftName: json["shift_name"],
        startTime: json["start_time"] ?? '', // Add this and handle nulls
        endTime: json["end_time"] ?? '', // Add this and handle nulls
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shift &&
          runtimeType == other.runtimeType &&
          shiftId == other.shiftId;

  @override
  int get hashCode => shiftId.hashCode;
}
