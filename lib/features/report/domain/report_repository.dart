import 'package:pramu_apps/features/report/domain/report.dart';

abstract interface class ReportRepository {
  Future<Report> submit(ReportInput input);
  Future<List<Report>> mine();
  Future<Report> get(String id);
  Future<Report> addEvidence(String id, List<String> paths);

  /// Persetujuan eksplisit berbagi percakapan ke admin (7 hari, dapat dicabut).
  Future<Report> shareConversation(
    String reportId, {
    required String conversationId,
  });
  Future<Report> revokeShare(String reportId);
}
