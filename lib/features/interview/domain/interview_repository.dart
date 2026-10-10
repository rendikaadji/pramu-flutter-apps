import 'package:pramu_apps/features/interview/domain/interview.dart';

abstract interface class InterviewRepository {
  /// Pencari mengajukan 1-3 slot (UTC; slot lampau -> 422).
  Future<Interview> propose(
    String applicationId,
    List<DateTime> slots, {
    String? note,
  });

  Future<Interview> get(String id);

  /// Null bila belum ada wawancara untuk lamaran ini.
  Future<Interview?> byApplication(String applicationId);

  /// Asisten konfirmasi satu slot. 502 `MEET_CREATE_FAILED`: status tetap `proposed`, boleh coba lagi.
  Future<Interview> confirm(String id, DateTime slot);

  Future<Interview> reschedule(String id, List<DateTime> slots);
  Future<Interview> cancel(String id);

  /// Menyimpan catatan privat pencari; wawancara jadi `done`, lamaran `interviewed`.
  Future<void> evaluate(String id, InterviewEvaluation evaluation);
  Future<InterviewEvaluation?> evaluation(String id);
}
