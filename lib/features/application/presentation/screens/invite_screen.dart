import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/money.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/application/data/application_providers.dart';
import 'package:pramu_apps/features/application/presentation/state/application_state.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-32 Ajak asisten ke salah satu lowongan terbuka.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key, required this.assistantId});
  final String assistantId;

  @override
  ConsumerState<InviteScreen> createState() => _State();
}

class _State extends ConsumerState<InviteScreen> with ApiActionMixin {
  final _message = TextEditingController();
  final _invited = <String>{};
  String? _selected;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final id = _selected!;
    final ok = await act(
      () => ref
          .read(applicationRepositoryProvider)
          .invite(
            assistantId: widget.assistantId,
            listingId: id,
            message: _message.text.trim().isEmpty ? null : _message.text.trim(),
          ),
      onConflict: () => ref.invalidate(openOwnListingsProvider),
    );
    if (!mounted) return;
    if (ok || actionError?.code == 'INVITATION_DUPLICATE') {
      setState(() => _invited.add(id));
    }
    if (ok) {
      AppSnack.show(context, 'Ajakan sudah terkirim.', success: true);
      popOrGo(context, Routes.seekerHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(openOwnListingsProvider);
    final name = ref.watch(assistantProfileProvider(widget.assistantId)).value;
    final canSend =
        canAct && _selected != null && !_invited.contains(_selected);
    return AppScaffold(
      title: 'Ajak melamar',
      body: AsyncBody<List<Listing>>(
        value: async,
        onRetry: () => ref.invalidate(openOwnListingsProvider),
        data: (ctx, list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: LucideIcons.clipboardList,
              title: 'Belum ada lowongan yang tayang',
              message:
                  'Tayangkan satu lowongan dulu, lalu ajak pelamar yang cocok.',
              actionLabel: 'Buat lowongan',
              onAction: () => ctx.push(Routes.listingNew),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(
              top: AppSpace.s8,
              bottom: AppSpace.s24,
            ),
            children: [
              if (actionError != null) ActionErrorBox(error: actionError!),
              Text(
                name == null
                    ? 'Pilih lowongan untuk ajakan ini'
                    : 'Ajak ${name.name} melamar ke lowongan',
                style: context.text.h3,
              ),
              const SizedBox(height: AppSpace.s12),
              RadioGroup<String>(
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v),
                child: Column(
                  children: [
                    for (final l in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.s8),
                        child: Material(
                          key: K.inviteListing(l.id),
                          color: ctx.tokens.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.brMd,
                            side: BorderSide(color: ctx.tokens.borderSubtle),
                          ),
                          child: RadioListTile<String>(
                            value: l.id,
                            title: Text(l.title),
                            subtitle: Text(
                              _invited.contains(l.id)
                                  ? 'Sudah diajak untuk lowongan ini'
                                  : '${l.city} · ${formatRupiah(l.budgetMin)} - ${formatRupiah(l.budgetMax)}',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              AppTextField(
                key: K.inviteMessage,
                label: 'Pesan singkat (opsional)',
                controller: _message,
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: AppSpace.s16),
              AppButton(
                key: K.inviteSubmit,
                label: 'Kirim ajakan',
                large: true,
                loading: busy,
                onPressed: canSend ? _send : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
