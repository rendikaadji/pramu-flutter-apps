import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pramu_apps/core/env.dart';
import 'package:pramu_apps/core/providers.dart';
import 'package:pramu_apps/features/chat/data/api_chat_repository.dart';
import 'package:pramu_apps/features/chat/data/mock_chat_repository.dart';
import 'package:pramu_apps/features/chat/domain/chat_repository.dart';

/// Mock atau API dipilih dari `Env.useMock` (--dart-define=USE_MOCK=false untuk API nyata).
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => Env.useMock
      ? MockChatRepository(ref.watch(mockBackendProvider))
      : ApiChatRepository(ref.watch(apiClientProvider)),
);
