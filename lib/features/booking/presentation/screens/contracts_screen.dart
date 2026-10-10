import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/presentation/state/booking_state.dart';
import 'package:pramu_apps/features/booking/presentation/widgets/booking_widgets.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-72 Daftar kontrak.
class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role =
        ref.watch(sessionProvider.select((s) => s.activeRole)) ?? Role.seeker;
    return AppScaffold(
      title: 'Kontrak',
      body: AsyncBody(
        value: ref.watch(bookingsProvider),
        onRetry: () => ref.invalidate(bookingsProvider),
        data: (context, list) => RefreshIndicator(
          onRefresh: () => ref.refresh(bookingsProvider.future),
          child: list.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: AppSpace.s48),
                    EmptyState(
                      icon: LucideIcons.fileText,
                      title: 'Belum ada kontrak',
                      message: 'Kontrak muncul setelah kedua pihak menyetujui kesepakatan.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpace.s12),
                  itemBuilder: (context, i) => BookingCard(
                    key: K.contractCard(list[i].id),
                    booking: list[i],
                    role: role,
                    onTap: () async {
                      await context.push(Routes.bookingDetail(list[i].id));
                      ref.invalidate(bookingsProvider);
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
