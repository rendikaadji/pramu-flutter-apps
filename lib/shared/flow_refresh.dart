import 'package:flutter_riverpod/misc.dart';
import 'package:pramu_apps/features/application/presentation/state/application_state.dart';
import 'package:pramu_apps/features/booking/presentation/state/booking_state.dart';
import 'package:pramu_apps/features/chat/presentation/state/chat_state.dart';
import 'package:pramu_apps/features/home/presentation/state/home_state.dart';
import 'package:pramu_apps/features/listing/presentation/state/listing_state.dart';
import 'package:pramu_apps/features/wallet/presentation/state/wallet_state.dart';

/// Provider tab/daftar yang ikut berubah saat alur lowongan -> lamaran -> kontrak -> bayar maju.
/// Tab shell tetap terpasang (IndexedStack), jadi tanpa ini kartu "Langkah berikutnya"
/// dan daftar kontrak/lamaran memperlihatkan data lama sampai pengguna menarik untuk menyegarkan.
final List<ProviderOrFamily> flowProviders = [
  seekerHomeProvider,
  assistantHomeProvider,
  bookingsProvider,
  myApplicationsProvider,
  myListingsProvider,
  applicationProvider,
  myApplicationForListingProvider,
  listingBrowseProvider,
  conversationsProvider,
  walletProvider,
];

/// Pakai: `invalidateFlow(ref.invalidate)` setelah aksi yang berhasil.
void invalidateFlow(void Function(ProviderOrFamily) invalidate) {
  flowProviders.forEach(invalidate);
}
