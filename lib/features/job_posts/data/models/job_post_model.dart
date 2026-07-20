enum JobType { fullTime, partTime }

enum JobPostStatus { active, inactive }

JobType jobTypeFromApi(String? value) {
  switch (value?.toUpperCase()) {
    case 'PART_TIME':
      return JobType.partTime;
    case 'FULL_TIME':
    default:
      return JobType.fullTime;
  }
}

String jobTypeToApi(JobType type) =>
    type == JobType.partTime ? 'PART_TIME' : 'FULL_TIME';

JobPostStatus jobPostStatusFromApi(String? value) =>
    value?.toUpperCase() == 'INACTIVE'
        ? JobPostStatus.inactive
        : JobPostStatus.active;

String jobPostStatusToApi(JobPostStatus status) =>
    status == JobPostStatus.inactive ? 'INACTIVE' : 'ACTIVE';

class JobPostModel {
  final int id;
  final int shopId;
  final String title;
  final String description;
  final JobType jobType;
  final bool salaryNegotiable;
  final int? salaryMin;
  final int? salaryMax;
  final String? applyLink;
  final String? contactPhone;
  final JobPostStatus status;
  final DateTime? closingDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const JobPostModel({
    required this.id,
    required this.shopId,
    required this.title,
    required this.description,
    required this.jobType,
    required this.salaryNegotiable,
    this.salaryMin,
    this.salaryMax,
    this.applyLink,
    this.contactPhone,
    required this.status,
    this.closingDate,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == JobPostStatus.active;

  JobPostModel copyWith({
    String? title,
    String? description,
    JobType? jobType,
    bool? salaryNegotiable,
    int? salaryMin,
    int? salaryMax,
    String? applyLink,
    String? contactPhone,
    JobPostStatus? status,
    DateTime? closingDate,
  }) {
    return JobPostModel(
      id: id,
      shopId: shopId,
      title: title ?? this.title,
      description: description ?? this.description,
      jobType: jobType ?? this.jobType,
      salaryNegotiable: salaryNegotiable ?? this.salaryNegotiable,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      applyLink: applyLink ?? this.applyLink,
      contactPhone: contactPhone ?? this.contactPhone,
      status: status ?? this.status,
      closingDate: closingDate ?? this.closingDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory JobPostModel.fromJson(Map<String, dynamic> json) {
    return JobPostModel(
      id: (json['id'] as num).toInt(),
      shopId: (json['shopId'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      jobType: jobTypeFromApi(json['jobType']?.toString()),
      salaryNegotiable: json['salaryNegotiable'] == true,
      salaryMin: (json['salaryMin'] as num?)?.toInt(),
      salaryMax: (json['salaryMax'] as num?)?.toInt(),
      applyLink: json['applyLink']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      status: jobPostStatusFromApi(json['status']?.toString()),
      closingDate: _parseDate(json['closingDate']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'jobType': jobTypeToApi(jobType),
      'salaryNegotiable': salaryNegotiable,
      if (salaryMin != null) 'salaryMin': salaryMin,
      if (salaryMax != null) 'salaryMax': salaryMax,
      if (applyLink != null && applyLink!.trim().isNotEmpty)
        'applyLink': applyLink!.trim(),
      if (contactPhone != null && contactPhone!.trim().isNotEmpty)
        'contactPhone': contactPhone!.trim(),
      'status': jobPostStatusToApi(status),
      'closingDate': closingDate?.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'jobType': jobTypeToApi(jobType),
      'salaryNegotiable': salaryNegotiable,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'applyLink': applyLink?.trim().isEmpty == true ? null : applyLink?.trim(),
      'contactPhone':
          contactPhone?.trim().isEmpty == true ? null : contactPhone?.trim(),
      'status': jobPostStatusToApi(status),
      'closingDate': closingDate?.toUtc().toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class JobPostListResult {
  final List<JobPostModel> items;
  final int total;
  final int page;
  final bool hasMore;

  const JobPostListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
  });
}
