import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/validators.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UrlLauncher = Future<bool> Function(Uri uri, LaunchMode mode);

/// Dapat di-override di test. Jangan panggil `launchUrl` langsung di layar.
final urlLauncherProvider = Provider<UrlLauncher>(
  (ref) => (uri, mode) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  },
);

/// Membuka URL hanya bila lolos allowlist (MOB-SEC-18). false = ditolak/gagal.
Future<bool> _open(
  UrlLauncher launcher,
  String? url,
  bool Function(String?) allowed,
  LaunchMode mode,
) async {
  if (!allowed(url)) return false;
  return launcher(Uri.parse(url!.trim()), mode);
}

/// Tautan Google Meet: https + meet.google.com, aplikasi eksternal.
Future<bool> openMeetingUrl(UrlLauncher launcher, String? url) =>
    _open(launcher, url, isAllowedMeetingUrl, LaunchMode.externalApplication);

/// Invoice Xendit: host allowlist, browser dalam aplikasi.
Future<bool> openInvoiceUrl(UrlLauncher launcher, String? url) =>
    _open(launcher, url, isAllowedInvoiceUrl, LaunchMode.inAppBrowserView);
