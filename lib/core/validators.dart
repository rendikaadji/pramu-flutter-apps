// Validator form lokal (String? = pesan error Indonesia, null = valid) + allowlist URL/ID.

final _phoneRe = RegExp(r'^(08\d{8,11}|\+628\d{8,11})$');
final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _ulidRe = RegExp(r'^[0-7][0-9A-HJKMNP-TV-Z]{25}$');

String _compactPhone(String s) => s.replaceAll(RegExp(r'[\s-]'), '');

bool isValidPhone(String s) => _phoneRe.hasMatch(_compactPhone(s));

/// 08xx / +628xx -> +628xx (bentuk kanonik yang dikirim ke API).
String normalizePhone(String s) {
  final p = _compactPhone(s);
  return p.startsWith('0') ? '+62${p.substring(1)}' : p;
}

bool isUlid(String? s) => s != null && _ulidRe.hasMatch(s);

String? validateRequired(String? v, [String label = 'Kolom ini']) =>
    (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

String? validatePhone(String? v) {
  if (v == null || v.trim().isEmpty) return 'Nomor HP wajib diisi';
  return isValidPhone(v) ? null : 'Nomor HP diawali 08 atau +62';
}

String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
  return _emailRe.hasMatch(v.trim())
      ? null
      : 'Alamat email belum benar. Contoh: nama@email.com';
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
  return v.length >= 8 ? null : 'Kata sandi minimal 8 karakter';
}

String? validateNik(String? v) {
  if (v == null || v.isEmpty) return 'Nomor KTP wajib diisi';
  return RegExp(r'^\d{16}$').hasMatch(v) ? null : 'Nomor KTP harus 16 digit';
}

const meetingHosts = {'meet.google.com'};
const invoiceHosts = {'checkout.xendit.co', 'checkout-staging.xendit.co'};

/// https + host persis di allowlist, tanpa userinfo, port default.
bool isAllowedUrl(String? url, Set<String> hosts) {
  final u = url == null ? null : Uri.tryParse(url.trim());
  return u != null &&
      u.scheme == 'https' &&
      u.userInfo.isEmpty &&
      (!u.hasPort || u.port == 443) &&
      hosts.contains(u.host.toLowerCase());
}

bool isAllowedMeetingUrl(String? url) => isAllowedUrl(url, meetingHosts);

bool isAllowedInvoiceUrl(String? url) => isAllowedUrl(url, invoiceHosts);
