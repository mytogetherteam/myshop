class MenuCategoryModel {
  final int id;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final int? displayOrder;
  final bool isActive;
  final String? imageUrl;
  final int itemCount;
  final int? masterCategoryId;
  final String? pendingStatus;
  final String? publishStatus;
  final String? rejectReason;

  MenuCategoryModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    this.displayOrder,
    this.isActive = true,
    this.imageUrl,
    this.itemCount = 0,
    this.masterCategoryId,
    this.pendingStatus,
    this.publishStatus,
    this.rejectReason,
  });

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    return MenuCategoryModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      displayOrder: json['displayOrder'],
      isActive: json['isActive'] ?? true,
      imageUrl: json['imageUrl'],
      itemCount: json['itemCount'] ?? 0,
      masterCategoryId: json['masterCategoryId'],
      pendingStatus: json['pendingStatus'],
      publishStatus: json['publishStatus'],
      rejectReason: json['rejectReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameMm': nameMm,
      'nameTh': nameTh,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'masterCategoryId': masterCategoryId,
      'pendingStatus': pendingStatus,
      'publishStatus': publishStatus,
      'rejectReason': rejectReason,
    };
  }

  MenuCategoryModel copyWith({
    int? id,
    String? nameEn,
    String? nameMm,
    String? nameTh,
    int? displayOrder,
    bool? isActive,
    String? imageUrl,
    int? itemCount,
    int? masterCategoryId,
    String? pendingStatus,
    String? publishStatus,
    String? rejectReason,
  }) {
    return MenuCategoryModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameMm: nameMm ?? this.nameMm,
      nameTh: nameTh ?? this.nameTh,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      itemCount: itemCount ?? this.itemCount,
      masterCategoryId: masterCategoryId ?? this.masterCategoryId,
      pendingStatus: pendingStatus ?? this.pendingStatus,
      publishStatus: publishStatus ?? this.publishStatus,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }


  String get displayName => nameEn ?? nameMm ?? nameTh ?? '';
}

