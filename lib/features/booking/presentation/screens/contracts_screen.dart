import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/session/session_controller.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/booking/presentation/state/booking_state.dart';
import 'package:pramu_apps/features/booking/presentation/widgets/booking_widgets.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-72 Daftar kontrak. Tab Semua / Berjalan / Selesai hanya menyaring tampilan.
class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _State();
}

class _State extends ConsumerState<ContractsScreen> {
  int _tab = 0;

  static bool _closed(Booking b) =>
      b.status == BookingStatus.completed ||
      b.status == BookingStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final role =
        ref.watch(sessionProvider.select((s) => s.activeRole)) ?? Role.seeker;
    return AppScaffold(
      title: 'Kontrak',
      glow: true,
      body: AsyncBody(
        value: ref.watch(bookingsProvider),
        onRetry: () => ref.invalidate(bookingsProvider),
        data: (context, all) {
          final list = switch (_tab) {
            1 => all.where((b) => !_closed(b)).toList(),
            2 => all.where(_closed).toList(),
            _ => all,
          };
          return RefreshIndicator(
            onRefresh: () => ref.refresh(bookingsProvider.future),
            child: all.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: AppSpace.s24),
                      EmptyState(
                        title: 'Belum ada kontrak',
                        message: 'Kontrak muncul setelah kedua pihak menyetujui kesepakatan.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.s12),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return SegmentedTabs(
                          labels: const ['Semua', 'Berjalan', 'Selesai'],
                          index: _tab,
                          onChanged: (v) => setState(() => _tab = v),
                        );
                      }
                      final b = list[i - 1];
                      return BookingCard(
                        key: K.contractCard(b.id),
                        booking: b,
                        role: role,
                        onTap: () async {
                          await context.push(Routes.bookingDetail(b.id));
                          ref.invalidate(bookingsProvider);
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
