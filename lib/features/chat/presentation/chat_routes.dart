import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:pramu_apps/features/chat/presentation/screens/conversation_list_screen.dart';

/// Layar chat: M-60 (tab root kedua peran), M-61.
final List<RouteBase> chatRoutes = [
  GoRoute(
    path: Routes.seekerChat,
    builder: (context, state) => const ConversationListScreen(),
  ),
  GoRoute(
    path: Routes.assistantChat,
    builder: (context, state) => const ConversationListScreen(),
  ),
  GoRoute(
    path: Routes.chatRoomT,
    builder: (context, state) =>
        ChatRoomScreen(conversationId: state.pathParameters['id']!),
  ),
];
