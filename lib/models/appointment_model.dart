import 'package:intl/intl.dart';

class AppointmentModel {
  final String id;
  final String treatmentName;
  final String doctorName;
  final DateTime date;
  final String status;

  AppointmentModel({
    required this.id,
    required this.treatmentName,
    required this.doctorName,
    required this.date,
    required this.status,
  });

  String get formattedDate {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      treatmentName: json['treatmentName']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date'].toString()) 
          : DateTime.now(),
      status: json['status']?.toString() ?? 'Programada',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'treatmentName': treatmentName,
      'doctorName': doctorName,
      'date': date.toIso8601String(),
      'status': status,
    };
  }
}
