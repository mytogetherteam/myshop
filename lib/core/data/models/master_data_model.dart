class MasterDataModel {
  final int id;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;

  MasterDataModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
  });

  factory MasterDataModel.fromJson(Map<String, dynamic> json) {
    return MasterDataModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
    );
  }

  String get displayName => nameEn ?? nameMm ?? nameTh ?? '';

  // override equality to compare by id for dropdowns
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MasterDataModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
