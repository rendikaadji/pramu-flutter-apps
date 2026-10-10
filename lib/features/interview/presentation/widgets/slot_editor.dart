import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/core/time.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';
import 'package:pramu_apps/shared/app_ui/wib_picker.dart';

const maxInterviewSlots = 3;

/// Daftar slot wawancara (maks 3, WIB). Slot lampau & duplikat ditolak.
class SlotEditor extends StatefulWidget {
  const SlotEditor({
    super.key,
    required this.slots,
    required this.onChanged,
    this.error,
  });

  final List<DateTime> slots;
  final ValueChanged<List<DateTime>> onChanged;
  final String? error;

  @override
  State<SlotEditor> createState() => _SlotEditorState();
}

class _SlotEditorState extends State<SlotEditor> {
  String? _local;

  Future<void> _add() async {
    final s = await pickWibDateTime(context);
    if (s == null) return;
    if (!s.isAfter(DateTime.now().toUtc())) {
      setState(
        () => _local = 'Waktu ini sudah lewat. Pilih waktu yang akan datang.',
      );
      return;
    }
    if (widget.slots.contains(s)) {
      setState(() => _local = 'Waktu ini sudah Anda pilih. Pilih waktu lain.');
      return;
    }
    setState(() => _local = null);
    widget.onChanged([...widget.slots, s]..sort());
  }

  @override
  Widget build(BuildContext context) {
    final err = _local ?? widget.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.slots.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s8),
            child: AppCard(
              key: K.interviewSlot(i),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s16,
                vertical: AppSpace.s4,
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendarClock),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Text(
                      formatDateTime(widget.slots[i]),
                      style: context.text.body,
                    ),
                  ),
                  AppIconButton(
                    icon: LucideIcons.trash2,
                    label: 'Hapus pilihan waktu ${i + 1}',
                    onPressed: () => widget.onChanged([
                      for (var j = 0; j < widget.slots.length; j++)
                        if (j != i) widget.slots[j],
                    ]),
                  ),
                ],
              ),
            ),
          ),
        if (widget.slots.length < maxInterviewSlots)
          AppButton(
            key: K.interviewSlotAdd,
            label: widget.slots.isEmpty
                ? 'Pilih waktu'
                : 'Tambah pilihan waktu',
            icon: LucideIcons.plus,
            variant: AppButtonVariant.secondary,
            expand: false,
            onPressed: _add,
          ),
        if (err != null) ...[
          const SizedBox(height: AppSpace.s8),
          FieldErrorText(err),
        ],
        const SizedBox(height: AppSpace.s4),
        Text(
          'Waktu dalam WIB. Maksimal $maxInterviewSlots pilihan.',
          style: context.text.bodySm,
        ),
      ],
    );
  }
}

/// Sheet usul jadwal baru. Mengembalikan true bila terkirim.
Future<bool> showRescheduleSheet(
  BuildContext context, {
  required Future<void> Function(List<DateTime> slots) onSubmit,
}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RescheduleSheet(onSubmit: onSubmit),
  );
  return r ?? false;
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({required this.onSubmit});
  final Future<void> Function(List<DateTime>) onSubmit;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet>
    with ApiActionMixin {
  List<DateTime> _slots = [];

  Future<void> _send() async {
    final ok = await act(() => widget.onSubmit(_slots));
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.s16,
        0,
        AppSpace.s16,
        AppSpace.s16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Usulkan waktu lain', style: context.text.h2),
          const SizedBox(height: AppSpace.s4),
          Text(
            'Pihak lain akan memilih salah satunya.',
            style: context.text.body.copyWith(color: context.tokens.textMuted),
          ),
          const SizedBox(height: AppSpace.s16),
          if (actionError != null) ActionErrorBox(error: actionError!),
          SlotEditor(
            slots: _slots,
            error: fieldError('slots'),
            onChanged: (s) => setState(() => _slots = s),
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            key: K.interviewSubmit,
            label: 'Kirim usulan waktu',
            loading: busy,
            onPressed: canAct && _slots.isNotEmpty ? _send : null,
          ),
        ],
      ),
    ),
  );
}
