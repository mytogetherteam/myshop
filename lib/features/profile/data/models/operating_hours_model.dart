class TimeModel {
  final int hour;
  final int minute;

  TimeModel({required this.hour, required this.minute});

  factory TimeModel.fromJson(Map<String, dynamic> json) {
    return TimeModel(
      hour: json['hour'] ?? 0,
      minute: json['minute'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'second': 0,
      'nano': 0,
    };
  }

  // Display helper
  String formatTime() {
    final ap = hour < 12 ? 'AM' : 'PM';
    int displayHour = hour;
    if (hour == 0) displayHour = 12;
    if (hour > 12) displayHour = hour - 12;
    final displayMin = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMin $ap';
  }
}

class OperatingHoursModel {
  final int dayOfWeek; // 0=Sun, 1=Mon...6=Sat
  final TimeModel openingTime;
  final TimeModel closingTime;
  final bool isClosed;

  OperatingHoursModel({
    required this.dayOfWeek,
    required this.openingTime,
    required this.closingTime,
    required this.isClosed,
  });

  factory OperatingHoursModel.fromJson(Map<String, dynamic> json) {
    return OperatingHoursModel(
      dayOfWeek: json['dayOfWeek'] ?? 0,
      openingTime: json['openTime'] != null
          ? TimeModel.fromJson(json['openTime'])
          : json['openingTime'] != null 
              ? TimeModel.fromJson(json['openingTime'])
              : TimeModel(hour: 0, minute: 0),
      closingTime: json['closeTime'] != null
          ? TimeModel.fromJson(json['closeTime'])
          : json['closingTime'] != null
              ? TimeModel.fromJson(json['closingTime'])
              : TimeModel(hour: 0, minute: 0),
      isClosed: json['isClosed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'openTime': openingTime.toJson(),
      'closeTime': closingTime.toJson(),
      'isClosed': isClosed,
    };
  }

  // Helper method for getting a display string of the day
  String get dayName {
    switch (dayOfWeek) {
      case 0: return 'Sunday';
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      default: return 'Unknown';
    }
  }
}
