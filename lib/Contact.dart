import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
part 'Contact.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class Contact {
  @HiveField(0)
  final String licensePlate;

  @HiveField(1)
  final String phoneNumber;

  Contact({required this.licensePlate, required this.phoneNumber});

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);

  Map<String, dynamic> toJson() => _$ContactToJson(this);

  // Factory constructor to create a Contact from a CSV row
  factory Contact.fromCsv(List<dynamic> csvRow) {
    return Contact(
      licensePlate: _cleanCsvField(csvRow[0]),
      phoneNumber: _cleanCsvField(csvRow[1]),
    );
  }
  // Helper method to remove quotes and trim spaces
  static String _cleanCsvField(dynamic field) {
    String str = field.toString();
    str = str.replaceAll('"', ''); // Remove quotes
    str = str.trim(); // Trim whitespace
    return str;
  }
  @override
  String toString() {
    return 'Contact(licensePlate: $licensePlate, phoneNumber: $phoneNumber)';
  }
}
