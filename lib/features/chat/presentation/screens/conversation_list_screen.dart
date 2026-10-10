import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/features/chat/presentation/state/chat_state.dart';
import 'package:pramu_apps/features/chat/presentation/widgets/conversation_tile.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-60 Daftar percakapan (tab root kedua peran).
class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(conversationsProvider);
    final n = ref.read(conversationsProvider.notifier);
    return AppScaffold(
      title: 'Pesan',
      body: AsyncBody(
        value: value,
        onRetry: () => ref.invalidate(conversationsProvider),
        data: (context, list) => RefreshIndicator(
          onRefresh: n.refresh,
          child: list.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: AppSpace.s48),
                    EmptyState(
                      icon: LucideIcons.messageCircle,
                      title: 'Belum ada percakapan',
                      message: 'Percakapan dimulai setelah ada lamaran.',
                    ),
                  ],
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 60),
                  itemBuilder: (context, i) => ConversationTile(
                    c: list[i],
                    onTap: () async {
                      await context.push(Routes.chatRoom(list[i].id));
                      n.refresh();
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
