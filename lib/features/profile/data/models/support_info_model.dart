class SupportInfoModel {
  final String? email;
  final String? phone;
  final String? website;
  final String? facebook;
  final String? line;
  final String? whatsapp;
  final String? workingHours;

  const SupportInfoModel({
    this.email,
    this.phone,
    this.website,
    this.facebook,
    this.line,
    this.whatsapp,
    this.workingHours,
  });

  factory SupportInfoModel.fromJson(Map<String, dynamic> json) {
    return SupportInfoModel(
      email: (json['email'] as String?) ?? 'support@mytogether.org',
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      facebook: json['facebook'] as String?,
      line: json['line'] as String?,
      whatsapp: json['whatsapp'] as String?,
      workingHours: json['workingHours'] as String?,
    );
  }

  bool get hasAnyContact =>
      (email?.isNotEmpty ?? false) ||
      (phone?.isNotEmpty ?? false) ||
      (website?.isNotEmpty ?? false) ||
      (facebook?.isNotEmpty ?? false) ||
      (line?.isNotEmpty ?? false) ||
      (whatsapp?.isNotEmpty ?? false);
}
