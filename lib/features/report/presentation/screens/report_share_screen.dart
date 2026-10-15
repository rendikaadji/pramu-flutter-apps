import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:pramu_apps/features/report/presentation/state/report_state.dart';
import 'package:pramu_apps/features/report/presentation/widgets/share_consent.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-96 sebagai rute `/reports/:id/share[?conversation=<ulid>]` (consent yang sama dengan bottom sheet).
class ReportShareScreen extends ConsumerWidget {
  const ReportShareScreen({
    super.key,
    required this.reportId,
    this.conversationId,
  });
  final String reportId;
  final String? conversationId;

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.reportStatus(reportId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final given = isUlid(conversationId) ? conversationId : null;
    final target = given != null
        ? AsyncData<String?>(given)
        : ref.watch(shareTargetProvider(reportId));
    return AppScaffold(
      title: 'Bagikan percakapan',
      scrollable: true,
      body: target.when(
        loading: () => const DetailSkeleton(),
        error: (e, _) => ApiErrorView(
          error: asApiException(e),
          onRetry: () => ref.invalidate(shareTargetProvider(reportId)),
        ),
        data: (c) => c == null
            ? const EmptyState(
                title: 'Tidak ada percakapan',
                message: 'Laporan ini tidak terhubung ke percakapan yang bisa dibagikan.',
              )
            : ShareConsentBody(
                reportId: reportId,
                conversationId: c,
                onDone: (_) => _close(context),
              ),
      ),
    );
  }
}
