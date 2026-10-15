import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/features/interview/domain/interview_repository.dart';

class ApiInterviewRepository implements InterviewRepository {
  ApiInterviewRepository(this._api);
  final ApiClient _api;

  List<String> _slots(List<DateTime> s) => [for (final t in s) toApiTime(t)];

  @override
  Future<Interview> propose(
    String applicationId,
    List<DateTime> slots, {
    String? note,
  }) async => Interview.fromJson(
    await _api.post(
      '/applications/$applicationId/interviews',
      data: {'slots': _slots(slots), 'note': ?note},
    ) as Json,
  );

  @override
  Future<Interview> get(String id) async =>
      Interview.fromJson(await _api.get('/interviews/$id') as Json);

  @override
  Future<Interview?> byApplication(String applicationId) async {
    final d = await _api.get('/applications/$applicationId/interview');
    return d == null ? null : Interview.fromJson(d as Json);
  }

  @override
  Future<Interview> confirm(String id, DateTime slot) async =>
      Interview.fromJson(
        await _api.post(
          '/interviews/$id/confirm',
          data: {'slot': toApiTime(slot)},
        ) as Json,
      );

  @override
  Future<Interview> reschedule(String id, List<DateTime> slots) async =>
      Interview.fromJson(
        await _api.post(
          '/interviews/$id/reschedule',
          data: {'slots': _slots(slots)},
        ) as Json,
      );

  @override
  Future<Interview> cancel(String id) async =>
      Interview.fromJson(await _api.post('/interviews/$id/cancel') as Json);

  @override
  Future<void> evaluate(String id, InterviewEvaluation e) =>
      _api.put('/interviews/$id/evaluation', data: e.toJson());

  @override
  Future<InterviewEvaluation?> evaluation(String id) async {
    try {
      return InterviewEvaluation.fromJson(
        await _api.get('/interviews/$id/evaluation') as Json,
      );
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }
}
