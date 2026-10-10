import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/interview/data/interview_providers.dart';
import 'package:pramu_apps/features/interview/presentation/state/interview_state.dart';
import 'package:pramu_apps/features/interview/presentation/widgets/slot_editor.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// M-50 Ajukan slot wawancara (pencari).
class ProposeScreen extends ConsumerStatefulWidget {
  const ProposeScreen({super.key, required this.applicationId});
  final String applicationId;

  @override
  ConsumerState<ProposeScreen> createState() => _State();
}

class _State extends ConsumerState<ProposeScreen> with ApiActionMixin {
  final _note = TextEditingController();
  List<DateTime> _slots = [];
  String? _localError;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_slots.isEmpty) {
      setState(() => _localError = 'Pilih minimal 1 waktu');
      return;
    }
    String? id;
    final ok = await act(
      () async {
        final iv = await ref
            .read(interviewRepositoryProvider)
            .propose(
              widget.applicationId,
              _slots,
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            );
        id = iv.id;
      },
      onConflict: () =>
          ref.invalidate(proposeTargetProvider(widget.applicationId)),
    );
    if (!ok || !mounted) return;
    AppSnack.show(context, 'Jadwal wawancara terkirim', success: true);
    context.pushReplacement(Routes.interviewDetail(id!));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(proposeTargetProvider(widget.applicationId));
    return AppScaffold(
      title: 'Ajukan wawancara',
      body: AsyncBody<Application>(
        value: async,
        onRetry: () =>
            ref.invalidate(proposeTargetProvider(widget.applicationId)),
        data: (ctx, app) => ListView(
          padding: const EdgeInsets.only(
            top: AppSpace.s8,
            bottom: AppSpace.s24,
          ),
          children: [
            if (actionError != null) ActionErrorBox(error: actionError!),
            Text('Wawancara dengan ${app.assistant.name}', style: ctx.text.h3),
            Text(app.listingTitle, style: ctx.text.bodySm),
            const SizedBox(height: AppSpace.s16),
            SlotEditor(
              slots: _slots,
              error: _localError ?? fieldError('slots'),
              onChanged: (s) => setState(() {
                _slots = s;
                _localError = null;
              }),
            ),
            const SizedBox(height: AppSpace.s16),
            AppTextField(
              key: K.interviewNote,
              label: 'Catatan singkat (opsional)',
              controller: _note,
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: AppSpace.s24),
            AppButton(
              key: K.interviewSubmit,
              label: 'Kirim jadwal',
              large: true,
              loading: busy,
              onPressed: canAct ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
