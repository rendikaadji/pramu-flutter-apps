import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/features/application/data/application_providers.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/interview/data/interview_providers.dart';
import 'package:pramu_apps/features/interview/domain/interview.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';

/// Wawancara + lamarannya (untuk tahu peran saya, judul, dan pihak lain).
class InterviewContext {
  const InterviewContext(this.interview, this.application, this.meId);
  final Interview interview;
  final Application application;
  final String meId;

  bool get isSeeker => application.seeker.id == meId;
  String get otherName =>
      isSeeker ? application.assistant.name : application.seeker.name;
}

final interviewContextProvider = FutureProvider.autoDispose
    .family<InterviewContext, String>((ref, id) async {
      final me = ref.watch(sessionProvider.select((s) => s.user?.id)) ?? '';
      final iv = await ref.watch(interviewRepositoryProvider).get(id);
      final app = await ref
          .watch(applicationRepositoryProvider)
          .get(iv.applicationId);
      return InterviewContext(iv, app, me);
    }, retry: noRetry);

/// Lamaran target pengajuan slot (M-50).
final proposeTargetProvider = FutureProvider.autoDispose
    .family<Application, String>((ref, applicationId) {
      ref.watch(sessionProvider.select((s) => s.user?.id));
      return ref.watch(applicationRepositoryProvider).get(applicationId);
    }, retry: noRetry);

/// Catatan privat (null bila belum ada / bukan pencari).
final evaluationProvider = FutureProvider.autoDispose
    .family<InterviewEvaluation?, String>((ref, id) {
      ref.watch(sessionProvider.select((s) => s.user?.id));
      return ref.watch(interviewRepositoryProvider).evaluation(id);
    }, retry: noRetry);
