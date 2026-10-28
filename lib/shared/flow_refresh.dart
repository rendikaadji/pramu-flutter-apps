import 'package:flutter_riverpod/misc.dart';
import 'package:pramu_apps/features/application/presentation/state/application_state.dart';
import 'package:pramu_apps/features/booking/presentation/state/booking_state.dart';
import 'package:pramu_apps/features/chat/presentation/state/chat_state.dart';
import 'package:pramu_apps/features/home/presentation/state/home_state.dart';
import 'package:pramu_apps/features/listing/presentation/state/listing_state.dart';

/// Inti alur lowongan -> lamaran -> kontrak -> bayar: beranda, daftar kontrak/lamaran/lowongan, detail lamaran.
/// Tab shell tetap terpasang (IndexedStack), jadi tanpa ini kartu "Langkah berikutnya" dan daftar
/// memperlihatkan data lama sampai pengguna menarik untuk menyegarkan.
final List<ProviderOrFamily> _flowCore = [
  seekerHomeProvider,
  assistantHomeProvider,
  bookingsProvider,
  myApplicationsProvider,
  myListingsProvider,
  applicationProvider,
  myApplicationForListingProvider,
];

/// Semua provider yang bisa tersentuh [invalidateFlow] (untuk tes).
final List<ProviderOrFamily> flowProviders = [
  ..._flowCore,
  listingBrowseProvider,
  conversationsProvider,
];

/// Pakai: `invalidateFlow(ref.invalidate)` setelah aksi yang berhasil. Tab lain hanya disegarkan bila aksinya
/// memang menyentuhnya, supaya mis. daftar Jelajah tidak kembali ke halaman 1 tanpa sebab:
/// [browse] bila status "sudah melamar" pada daftar berubah, [chat] bila percakapan baru/berubah.
void invalidateFlow(
  void Function(ProviderOrFamily) invalidate, {
  bool browse = false,
  bool chat = false,
}) {
  _flowCore.forEach(invalidate);
  if (browse) invalidate(listingBrowseProvider);
  if (chat) invalidate(conversationsProvider);
}
