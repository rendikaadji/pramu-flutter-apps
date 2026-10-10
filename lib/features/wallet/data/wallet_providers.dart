import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/wallet/data/api_wallet_repository.dart';
import 'package:pramu_apps/features/wallet/data/mock_wallet_repository.dart';
import 'package:pramu_apps/features/wallet/domain/wallet_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => Env.useMock
      ? MockWalletRepository(ref.watch(mockBackendProvider))
      : ApiWalletRepository(ref.watch(apiClientProvider)),
);
