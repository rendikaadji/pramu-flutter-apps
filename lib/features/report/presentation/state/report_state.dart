import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/booking/data/booking_providers.dart';
import 'package:pramu_apps/features/report/data/report_providers.dart';
import 'package:pramu_apps/features/report/domain/report.dart';

class ReportListNotifier extends AsyncNotifier<List<Report>> {
  @override
  Future<List<Report>> build() {
    ref.watch(sessionProvider.select((s) => s.user?.id));
    return ref.read(reportRepositoryProvider).mine();
  }
}

final reportListProvider =
    AsyncNotifierProvider.autoDispose<ReportListNotifier, List<Report>>(
      ReportListNotifier.new,
    );

class ReportNotifier extends AsyncNotifier<Report> {
  ReportNotifier(this.reportId);
  final String reportId;

  @override
  Future<Report> build() {
    ref.watch(sessionProvider.select((s) => s.user?.id));
    return ref.read(reportRepositoryProvider).get(reportId);
  }

  void _set(Report r) {
    state = AsyncData(r);
    ref.invalidate(reportListProvider);
  }

  Future<void> addEvidence(List<String> paths) async => _set(
    await ref.read(reportRepositoryProvider).addEvidence(reportId, paths),
  );

  Future<void> share(String conversationId) async => _set(
    await ref
        .read(reportRepositoryProvider)
        .shareConversation(reportId, conversationId: conversationId),
  );

  Future<void> revokeShare() async =>
      _set(await ref.read(reportRepositoryProvider).revokeShare(reportId));
}

final reportProvider = AsyncNotifierProvider.autoDispose
    .family<ReportNotifier, Report, String>(ReportNotifier.new);

/// Percakapan yang bisa dibagikan untuk laporan ini (dari booking terkait). Null bila tak ada.
final shareTargetProvider = FutureProvider.autoDispose.family<String?, String>((
  ref,
  reportId,
) async {
  final r = await ref.watch(reportProvider(reportId).future);
  final b = r.bookingId;
  if (!isUlid(b)) return null;
  return (await ref.read(bookingRepositoryProvider).booking(b!)).conversationId;
});
