import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      glow: true,
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
                      illustration: ChatIllustration(),
                      title: 'Belum ada percakapan',
                      message: 'Percakapan dimulai setelah ada lamaran.',
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
                  children: [
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, c) in list.indexed) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: AppSpace.s16 + 48 + AppSpace.s12,
                                color: context.tokens.borderSubtle,
                              ),
                            ConversationTile(
                              c: c,
                              onTap: () async {
                                await context.push(Routes.chatRoom(c.id));
                                n.refresh();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
