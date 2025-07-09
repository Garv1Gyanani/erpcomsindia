class SiteModel {
  final int id;
  final String siteName;

  SiteModel({
    required this.id,
    required this.siteName,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'] ?? 0,
      siteName: json['site_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_name': siteName,
    };
  }

  @override
  String toString() {
    return 'SiteModel(id: $id, siteName: $siteName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SiteModel && other.id == id && other.siteName == siteName;
  }

  @override
  int get hashCode => id.hashCode ^ siteName.hashCode;
}

class SiteListResponse {
  final bool status;
  final String message;
  final List<SiteModel> data;

  SiteListResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SiteListResponse.fromJson(Map<String, dynamic> json) {
    return SiteListResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
              .map((site) => SiteModel.fromJson(site))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((site) => site.toJson()).toList(),
    };
  }
}
