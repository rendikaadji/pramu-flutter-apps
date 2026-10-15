import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/router/routes.dart';

import '../../core/theme/app_theme.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'offline_banner.dart';
import 'skeletons/skeletons.dart';

export 'skeletons/skeletons.dart' show ListSkeleton;

/// Kembali; bila tak ada halaman sebelumnya (mis. deep link) ke [fallback].
void popOrGo(BuildContext context, String fallback) =>
    context.canPop() ? context.pop() : context.go(fallback);

/// Riverpod 3 mengulang provider gagal otomatis; UI kita menampilkan error + "Coba lagi".
Duration? noRetry(int retryCount, Object error) => null;

ApiException asApiException(Object e) => e is ApiException
    ? e
    : ApiException(
        status: 500,
        code: 'UNKNOWN',
        message: ApiException.defaultMessage(500),
      );

bool isVerificationRequired(ApiException e) =>
    e.status == 403 && e.code == 'VERIFICATION_REQUIRED';

/// Error muat: 403 verifikasi -> arahkan ke gerbang; selain itu kartu error + Coba lagi.
class ApiErrorView extends StatelessWidget {
  const ApiErrorView({super.key, required this.error, this.onRetry});
  final ApiException error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isVerificationRequired(error)) {
      return EmptyState(
        icon: LucideIcons.lock,
        title: 'Verifikasi dulu',
        message: 'Selesaikan verifikasi dulu agar fitur ini bisa dipakai.',
        actionLabel: 'Mulai verifikasi',
        onAction: () => context.push(Routes.verificationGate),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
      child: ErrorState(
        message: error.message,
        code: error.isNetwork ? null : error.code,
        onRetry: onRetry,
      ),
    );
  }
}

/// Pembungkus `AsyncValue`: skeleton / error / data (+ banner offline bila data lama masih ada).
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.onRetry,
    required this.data,
    this.skeleton,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T data) data;
  final Widget? skeleton;

  @override
  Widget build(BuildContext context) {
    // Satu tahap = satu key: loading -> data memudar 200 ms, sedangkan
    // data -> data (refresh) tidak memicu transisi maupun mount ulang.
    final (stage, child) = _content(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(stage), child: child),
    );
  }

  (String, Widget) _content(BuildContext context) {
    if (value.hasValue) {
      final child = data(context, value.requireValue);
      final err = value.hasError ? asApiException(value.error!) : null;
      if (err == null || !err.isNetwork) return ('data', child);
      return (
        'data',
        Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child),
          ],
        ),
      );
    }
    if (value.hasError) {
      return (
        'error',
        SingleChildScrollView(
          child: ApiErrorView(
            error: asApiException(value.error!),
            onRetry: onRetry,
          ),
        ),
      );
    }
    return (
      'loading',
      SingleChildScrollView(child: skeleton ?? const ListSkeleton()),
    );
  }
}

/// Kotak error untuk aksi tulis (kirim/simpan). 422 berfield tidak ditampilkan di sini
/// (field menampilkan sendiri); 403 verifikasi/SKCK diberi tombol tujuan.
class ActionErrorBox extends StatelessWidget {
  const ActionErrorBox({super.key, required this.error, this.skckListingId});
  final ApiException error;
  final String? skckListingId;

  @override
  Widget build(BuildContext context) {
    if (error.isValidation && error.fields.isNotEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.tokens;
    final skck = error.status == 403 && error.code == 'SKCK_REQUIRED';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s16),
      child: AppCard(
        color: t.dangerContainer,
        borderColor: t.danger.withValues(alpha: .4),
        child: Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.circleAlert, color: t.danger),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(error.message, style: context.text.body),
                        if (!error.isNetwork) ...[
                          const SizedBox(height: AppSpace.s4),
                          Text(
                            'Kode: ${error.code}',
                            style: context.text.caption.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (isVerificationRequired(error)) ...[
                const SizedBox(height: AppSpace.s12),
                AppButton(
                  label: 'Mulai verifikasi',
                  variant: AppButtonVariant.secondary,
                  expand: false,
                  onPressed: () => context.push(Routes.verificationGate),
                ),
              ],
              if (skck && skckListingId != null) ...[
                const SizedBox(height: AppSpace.s12),
                AppButton(
                  label: 'Unggah SKCK',
                  variant: AppButtonVariant.secondary,
                  expand: false,
                  onPressed: () =>
                      context.push('${Routes.skck}?listing=$skckListingId'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Mixin aksi tulis untuk State layar: `busy` (cegah ketuk ganda), error terakhir,
/// 409 -> dialog "Muat ulang", 429 -> tombol nonaktif sementara.
mixin ApiActionMixin<T extends StatefulWidget> on State<T> {
  bool busy = false;
  ApiException? actionError;
  bool _cooling = false;
  Timer? _coolTimer;

  bool get canAct => !busy && !_cooling;

  String? fieldError(String key) {
    final f = actionError?.fields[key];
    return f == null || f.isEmpty ? null : f.first;
  }

  void clearActionError() => actionError = null;

  /// true bila sukses. [onConflict] dipanggil setelah pengguna menekan "Muat ulang".
  Future<bool> act(
    Future<void> Function() action, {
    VoidCallback? onConflict,
  }) async {
    setState(() {
      busy = true;
      actionError = null;
    });
    try {
      await action();
      if (mounted) setState(() => busy = false);
      return true;
    } catch (e) {
      final err = asApiException(e);
      if (!mounted) return false;
      final conflict = err.isConflict && onConflict != null;
      setState(() {
        busy = false;
        actionError = conflict ? null : err;
        if (err.isRateLimited) {
          _cooling = true;
          _coolTimer?.cancel();
          _coolTimer = Timer(err.retryAfter ?? const Duration(seconds: 15), () {
            if (mounted) setState(() => _cooling = false);
          });
        }
      });
      if (conflict) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Data sudah berubah'),
            content: Text(err.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Muat ulang'),
              ),
            ],
          ),
        );
        if (!mounted) return false;
        onConflict();
      }
      return false;
    }
  }

  @override
  void dispose() {
    _coolTimer?.cancel();
    super.dispose();
  }
}
