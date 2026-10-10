import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/features/rating/presentation/state/rating_state.dart';
import 'package:pramu_apps/features/rating/presentation/widgets/review_tile.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-91 Ulasan (hanya yang sudah `revealed`; `isAuto` berlabel "Otomatis").
class UserReviewsScreen extends ConsumerWidget {
  const UserReviewsScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(userReviewsProvider(userId));
    final n = ref.read(userReviewsProvider(userId).notifier);
    return AppScaffold(
      title: 'Ulasan',
      body: s.when(
        loading: () => Semantics(
          label: 'Memuat',
          child: const Column(
            children: [
              SizedBox(height: AppSpace.s16),
              AppSkeleton.box(96),
              SizedBox(height: AppSpace.s12),
              AppSkeleton.box(96),
            ],
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.only(top: AppSpace.s16),
          child: ApiErrorView(
            error: asApiException(e),
            onRetry: () => ref.invalidate(userReviewsProvider(userId)),
          ),
        ),
        data: (d) => d.items.isEmpty
            ? const EmptyState(
                icon: LucideIcons.star,
                title: 'Belum ada ulasan',
                message: 'Ulasan muncul setelah kontrak selesai dan dinilai.',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userReviewsProvider(userId));
                  await ref.read(userReviewsProvider(userId).future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
                  itemCount: d.items.length + (d.nextCursor == null ? 0 : 1),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpace.s12),
                  itemBuilder: (_, i) => i < d.items.length
                      ? ReviewTile(d.items[i])
                      : AppButton(
                          label: 'Muat lebih banyak',
                          variant: AppButtonVariant.secondary,
                          onPressed: n.loadMore,
                        ),
                ),
              ),
      ),
    );
  }
}
