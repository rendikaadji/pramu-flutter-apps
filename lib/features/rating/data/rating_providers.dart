import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/rating/data/api_rating_repository.dart';
import 'package:pramu_apps/features/rating/data/mock_rating_repository.dart';
import 'package:pramu_apps/features/rating/domain/rating_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final ratingRepositoryProvider = Provider<RatingRepository>(
  (ref) => Env.useMock
      ? MockRatingRepository(ref.watch(mockBackendProvider))
      : ApiRatingRepository(ref.watch(apiClientProvider)),
);
