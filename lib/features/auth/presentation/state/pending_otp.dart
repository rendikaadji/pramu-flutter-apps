import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nomor HP kanonik yang sedang menunggu OTP. Hanya di memori (bukan URL, MOB-SEC-13).
class PendingOtp extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? phone) => state = phone;
}

final pendingOtpProvider = NotifierProvider<PendingOtp, String?>(
  PendingOtp.new,
);
