/// Parses a time string like "09:00:00" into hour/minute components.
TimeModel _parseTimeString(String? timeStr, {int defaultHour = 0}) {
  if (timeStr == null || timeStr.isEmpty) return TimeModel(hour: defaultHour, minute: 0);
  final parts = timeStr.split(':');
  if (parts.length < 2) return TimeModel(hour: defaultHour, minute: 0);
  return TimeModel(
    hour: int.tryParse(parts[0]) ?? defaultHour,
    minute: int.tryParse(parts[1]) ?? 0,
  );
}

class TimeModel {
  final int hour;
  final int minute;

  TimeModel({required this.hour, required this.minute});

  factory TimeModel.fromJson(dynamic value) {
    // Handle string format like "09:00:00"
    if (value is String) return _parseTimeString(value);
    // Handle map format like {"hour": 9, "minute": 0}
    if (value is Map<String, dynamic>) {
      return TimeModel(
        hour: value['hour'] ?? 0,
        minute: value['minute'] ?? 0,
      );
    }
    return TimeModel(hour: 0, minute: 0);
  }

  /// Returns time as "HH:mm:ss" string for API payload
  String toTimeString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m:00';
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
  /// dayOfWeek as returned from both APIs:
  /// - dedicated /api/shop/operating-hours  → 1-based (1=Mon … 7=Sun)
  /// - shop profile operatingHours          → 0-based (0=Sun … 6=Sat)
  final int dayOfWeek;
  final TimeModel openingTime;
  final TimeModel closingTime;
  final bool isClosed;

  OperatingHoursModel({
    required this.dayOfWeek,
    required this.openingTime,
    required this.closingTime,
    required this.isClosed,
  });

  /// Parses from the dedicated GET /api/shop/operating-hours response
  /// where openTime/closeTime are strings and dayOfWeek is 1-based.
  factory OperatingHoursModel.fromActiveHoursJson(Map<String, dynamic> json) {
    TimeModel openingTime;
    if (json['openTimeHour'] != null) {
      openingTime = TimeModel(
        hour: json['openTimeHour'] as int,
        minute: (json['openTimeMin'] ?? 0) as int,
      );
    } else {
      openingTime = _parseTimeString(json['openTime'] as String?, defaultHour: 9);
    }

    TimeModel closingTime;
    if (json['closeTimeHour'] != null) {
      closingTime = TimeModel(
        hour: json['closeTimeHour'] as int,
        minute: (json['closeTimeMin'] ?? 0) as int,
      );
    } else {
      closingTime = _parseTimeString(json['closeTime'] as String?, defaultHour: 21);
    }

    return OperatingHoursModel(
      dayOfWeek: json['dayOfWeek'] ?? 1,
      openingTime: openingTime,
      closingTime: closingTime,
      isClosed: json['isClosed'] ?? false,
    );
  }

  factory OperatingHoursModel.fromJson(Map<String, dynamic> json) {
    final openVal = json['openTime'] ?? json['openingTime'];
    final closeVal = json['closeTime'] ?? json['closingTime'];
    return OperatingHoursModel(
      dayOfWeek: json['dayOfWeek'] ?? 0,
      openingTime: openVal != null
          ? TimeModel.fromJson(openVal)
          : TimeModel(
              hour: json['openTimeHour'] ?? 9,
              minute: json['openTimeMin'] ?? 0,
            ),
      closingTime: closeVal != null
          ? TimeModel.fromJson(closeVal)
          : TimeModel(
              hour: json['closeTimeHour'] ?? 21,
              minute: json['closeTimeMin'] ?? 0,
            ),
      isClosed: json['isClosed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'openTime': openingTime.toJson(),
      'closeTime': closingTime.toJson(),
      'openTimeHour': openingTime.hour,
      'openTimeMin': openingTime.minute,
      'closeTimeHour': closingTime.hour,
      'closeTimeMin': closingTime.minute,
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
      case 7: return 'Sunday'; // 1-based Sunday
      default: return 'Unknown';
    }
  }
}
