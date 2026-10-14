import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus {
  pending('Pendente'),
  reviewed('Em análise'),
  dismissed('Descartada'),
  actionTaken('Anúncio Removido');

  final String label;
  const ReportStatus(this.label);

  static ReportStatus fromString(String? val) {
    switch (val) {
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'dismissed':
        return ReportStatus.dismissed;
      case 'action_taken':
        return ReportStatus.actionTaken;
      case 'pending':
      default:
        return ReportStatus.pending;
    }
  }

  String toDbValue() {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.reviewed:
        return 'reviewed';
      case ReportStatus.dismissed:
        return 'dismissed';
      case ReportStatus.actionTaken:
        return 'action_taken';
    }
  }
}

class ReportModel {
  final String id;
  final String adId;
  final String adTitle;
  final String reportedUserId;
  final String reporterUserId;
  final String reporterEmail;
  final String reason;
  final String details;
  final ReportStatus status;
  final DateTime createdAt;
  final String? adminNotes;

  const ReportModel({
    required this.id,
    required this.adId,
    required this.adTitle,
    required this.reportedUserId,
    required this.reporterUserId,
    required this.reporterEmail,
    required this.reason,
    required this.details,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.adminNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adId': adId,
      'adTitle': adTitle,
      'reportedUserId': reportedUserId,
      'reporterUserId': reporterUserId,
      'reporterEmail': reporterEmail,
      'reason': reason,
      'details': details,
      'status': status.toDbValue(),
      'createdAt': Timestamp.fromDate(createdAt),
      'adminNotes': adminNotes,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ReportModel(
      id: id ?? map['id'] ?? '',
      adId: map['adId'] ?? '',
      adTitle: map['adTitle'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reporterUserId: map['reporterUserId'] ?? '',
      reporterEmail: map['reporterEmail'] ?? '',
      reason: map['reason'] ?? 'Motivo não especificado',
      details: map['details'] ?? '',
      status: ReportStatus.fromString(map['status']),
      createdAt: parseDate(map['createdAt']),
      adminNotes: map['adminNotes'],
    );
  }
}
