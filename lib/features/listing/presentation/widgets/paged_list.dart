import 'package:flutter/material.dart';
import 'package:pramu_apps/features/listing/presentation/state/paged_notifier.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Daftar infinite scroll + pull-to-refresh + state L/E/X/offline.
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    this.onRetryMore,
    required this.itemBuilder,
    required this.empty,
    this.skeletonKind = SkeletonCardKind.listing,
  });

  final PagedState<T> state;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final VoidCallback? onRetryMore;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget empty;
  final SkeletonCardKind skeletonKind;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) widget.onLoadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    if (s.loading && s.items.isEmpty) {
      return SingleChildScrollView(
        child: ListSkeleton(kind: widget.skeletonKind),
      );
    }
    if (s.error != null && s.items.isEmpty) {
      return SingleChildScrollView(
        child: ApiErrorView(error: s.error!, onRetry: widget.onRefresh),
      );
    }
    if (s.items.isEmpty) return widget.empty;
    final offline = s.error != null && s.error!.isNetwork;
    final list = RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: AppSpace.s8, bottom: AppSpace.s24),
        itemCount: s.items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s12),
        itemBuilder: (ctx, i) {
          if (i < s.items.length) return widget.itemBuilder(ctx, s.items[i]);
          if (s.loadingMore) {
            return Semantics(
              label: 'Memuat lainnya',
              child: ExcludeSemantics(
                child: ListSkeleton(count: 1, kind: widget.skeletonKind),
              ),
            );
          }
          if (s.error != null) {
            return ApiErrorView(
              error: s.error!,
              onRetry: widget.onRetryMore ?? widget.onLoadMore,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
    return offline
        ? Column(
            children: [
              const OfflineBanner(),
              Expanded(child: list),
            ],
          )
        : list;
  }
}
