import 'package:dio/dio.dart';
import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/features/report/domain/report.dart';
import 'package:pramu_apps/features/report/domain/report_repository.dart';

class ApiReportRepository implements ReportRepository {
  ApiReportRepository(this._api);
  final ApiClient _api;

  Future<List<MultipartFile>> _files(List<String> paths) async => [
    for (final p in paths) await MultipartFile.fromFile(p),
  ];

  @override
  Future<Report> submit(ReportInput i) async {
    final form = FormData.fromMap({
      'type': wire(i.type),
      'description': i.description,
      'booking_id': ?i.bookingId,
      'period_id': ?i.periodId,
      // Opsional: kontrak M-95 belum mendefinisikan field ini; server mengabaikan bila belum ada.
      'reported_user_id': ?i.userId,
      'evidence[]': await _files(i.evidencePaths),
    });
    return Report.fromJson(
      await _api.post('/reports', data: form, options: ApiClient.upload)
          as Json,
    );
  }

  @override
  Future<List<Report>> mine() async => [
    for (final r in await _api.get('/reports') as List)
      Report.fromJson(r as Json),
  ];

  @override
  Future<Report> get(String id) async =>
      Report.fromJson(await _api.get('/reports/$id') as Json);

  @override
  Future<Report> addEvidence(String id, List<String> paths) async =>
      Report.fromJson(
        await _api.post(
          '/reports/$id/evidence',
          data: FormData.fromMap({'evidence[]': await _files(paths)}),
          options: ApiClient.upload,
        ) as Json,
      );

  @override
  Future<Report> shareConversation(
    String reportId, {
    required String conversationId,
  }) async => Report.fromJson(
    await _api.post(
      '/reports/$reportId/share-conversation',
      data: {'conversation_id': conversationId},
    ) as Json,
  );

  @override
  Future<Report> revokeShare(String reportId) async => Report.fromJson(
    await _api.delete('/reports/$reportId/share-conversation') as Json,
  );
}
