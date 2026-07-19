class Subject {
  final String id;
  final String name;
  final int dayOfWeek; // 0 = Monday ... 6 = Sunday
  final String startTime; // e.g. "09:00"
  final String endTime; // e.g. "10:30"
  final String? location;
  final int colorValue;

  Subject({
    required this.id,
    required this.name,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.colorValue,
  });

  // Converts a Subject into a Map for writing to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'colorValue': colorValue,
    };
  }

  // Builds a Subject from Firestore document data.
  factory Subject.fromMap(String id, Map<String, dynamic> map) {
    return Subject(
      id: id,
      name: map['name'] as String,
      dayOfWeek: map['dayOfWeek'] as int,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      location: map['location'] as String?,
      colorValue: map['colorValue'] as int,
    );
  }
}