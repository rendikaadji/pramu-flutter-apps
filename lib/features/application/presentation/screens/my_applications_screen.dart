import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/models/wire.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/application/presentation/state/application_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-44 Pekerjaan > Lamaran (tab Asisten) + undangan masuk.
class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(myApplicationsProvider);
    final invites = ref.watch(myInvitationsProvider).value ?? const [];
    Future<void> refresh() async {
      ref.invalidate(myApplicationsProvider);
      ref.invalidate(myInvitationsProvider);
      await ref
          .read(myApplicationsProvider.future)
          .catchError((_) => <Application>[]);
    }

    return AppScaffold(
      title: 'Lamaran saya',
      body: AsyncBody<List<Application>>(
        value: apps,
        onRetry: () => ref.invalidate(myApplicationsProvider),
        data: (ctx, list) {
          if (list.isEmpty && invites.isEmpty) {
            return EmptyState(
              icon: LucideIcons.fileText,
              title: 'Belum ada lamaran',
              message:
                  'Cari lowongan yang cocok lalu kirim lamaran pertama Anda.',
              actionLabel: 'Cari lowongan',
              onAction: () => ctx.go(Routes.assistantListings),
            );
          }
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: AppSpace.s8,
                bottom: AppSpace.s24,
              ),
              children: [
                if (invites.isNotEmpty) ...[
                  const SectionHeader('Undangan'),
                  const SizedBox(height: AppSpace.s8),
                  for (final i in invites)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.s12),
                      child: AppCard(
                        key: K.invitationCard(i.id),
                        onTap: () =>
                            ctx.push(Routes.listingDetail(i.listingId)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i.listingTitle, style: ctx.text.h3),
                            Text(
                              'Diajak oleh ${i.seeker.name}',
                              style: ctx.text.bodySm,
                            ),
                            if (i.message != null && i.message!.isNotEmpty)
                              Text(i.message!, style: ctx.text.body),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpace.s8),
                ],
                const SectionHeader('Lamaran'),
                const SizedBox(height: AppSpace.s8),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpace.s16),
                    child: Text(
                      'Belum ada lamaran. Cari lowongan.',
                      style: ctx.text.body,
                    ),
                  ),
                for (final a in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s12),
                    child: AppCard(
                      key: K.applicationCard(a.id),
                      onTap: () => ctx
                          .push(Routes.applicationDetail(a.id))
                          .then((_) => ref.invalidate(myApplicationsProvider)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.listingTitle, style: ctx.text.h3),
                          const SizedBox(height: AppSpace.s4),
                          Text(
                            '${a.seeker.name} - usulan ${formatRupiah(a.proposedRate)}',
                            style: ctx.text.bodySm,
                          ),
                          Text(
                            'Dilamar ${formatDate(a.createdAt)}',
                            style: ctx.text.bodySm,
                          ),
                          const SizedBox(height: AppSpace.s8),
                          StatusChip.of(
                            StatusDomain.application,
                            wire(a.status),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
