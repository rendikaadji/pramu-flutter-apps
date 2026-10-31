import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Tampilkan [AsyncValue]: kerangka saat memuat, [ErrorState] dengan pesan server saat gagal, lalu isi.
class Muat<T> extends StatelessWidget {
  const Muat({
    super.key,
    required this.nilai,
    required this.isi,
    this.onUlangi,
  });

  final AsyncValue<T> nilai;
  final Widget Function(T data) isi;
  final VoidCallback? onUlangi;

  @override
  Widget build(BuildContext context) => switch (nilai) {
    AsyncData(:final value) => isi(value),
    AsyncError(:final error) => Padding(
      padding: const EdgeInsets.all(AppSpace.s16),
      child: ErrorState(
        message: pesanGalat(error),
        code: error is ApiException ? error.code : null,
        onRetry: onUlangi,
      ),
    ),
    _ => const Padding(
      padding: EdgeInsets.all(AppSpace.s16),
      child: SkeletonScope(
        child: Column(
          children: [
            AppSkeleton(height: 72),
            SizedBox(height: AppSpace.s12),
            AppSkeleton(height: 72),
            SizedBox(height: AppSpace.s12),
            AppSkeleton(height: 72),
          ],
        ),
      ),
    ),
  };
}

/// Pesan yang aman ditampilkan: dari server bila ada, selain itu pesan bawaan.
String pesanGalat(Object e) => e is ApiException
    ? e.message
    : ApiException.defaultMessage(ApiException.network);
