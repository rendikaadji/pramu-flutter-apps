import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/notification/data/api_notification_repository.dart';
import 'package:pramu_apps/features/notification/data/mock_notification_repository.dart';
import 'package:pramu_apps/features/notification/domain/notification_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => Env.useMock
      ? MockNotificationRepository(ref.watch(mockBackendProvider))
      : ApiNotificationRepository(ref.watch(apiClientProvider)),
);
