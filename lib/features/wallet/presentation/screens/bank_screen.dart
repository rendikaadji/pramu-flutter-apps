import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pramu_apps/core/platform/secure_screen.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/wallet/data/wallet_providers.dart';
import 'package:pramu_apps/features/wallet/domain/wallet.dart';
import 'package:pramu_apps/features/wallet/presentation/state/wallet_state.dart';
import 'package:pramu_apps/shared/app_ui/api_error_view.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

const _banks = ['BCA', 'BNI', 'BRI', 'Mandiri', 'BSI', 'CIMB Niaga', 'Permata'];

/// M-82 Rekening bank. Nomor penuh tidak pernah ditampilkan ulang setelah disimpan.
class BankScreen extends ConsumerStatefulWidget {
  const BankScreen({super.key});

  @override
  ConsumerState<BankScreen> createState() => _State();
}

class _State extends ConsumerState<BankScreen> with ApiActionMixin {
  final _number = TextEditingController();
  final _holder = TextEditingController();
  String? _bank;
  bool _editing = false;
  Map<String, String> _local = {};

  @override
  void dispose() {
    _number.dispose();
    _holder.dispose();
    super.dispose();
  }

  Future<void> _save(bool replacing) async {
    final number = _number.text.trim();
    final holder = _holder.text.trim();
    final errs = {
      if (_bank == null) 'bank': 'Pilih bank',
      if (!RegExp(r'^\d{8,16}$').hasMatch(number))
        'number': 'Nomor rekening 8 sampai 16 digit',
      if (holder.isEmpty) 'holder_name': 'Nama pemilik wajib diisi',
    };
    setState(() => _local = errs);
    if (errs.isNotEmpty) return;
    final ok = await ConfirmDialog.show(
      context,
      title: replacing ? 'Ganti rekening?' : 'Simpan rekening?',
      message: replacing
          ? 'Rekening tujuan penarikan diganti ke $_bank. Penarikan dapat '
                'tertunda sementara demi keamanan.'
          : 'Penarikan akan dikirim ke $_bank a.n. $holder. Pastikan nomor benar.',
      confirmLabel: 'Simpan',
    );
    if (!ok || !mounted) return;
    final done = await act(
      () => ref
          .read(walletRepositoryProvider)
          .saveBankAccount(bank: _bank!, number: number, holderName: holder),
    );
    if (!mounted || !done) return;
    _number.clear();
    _holder.clear();
    ref.invalidate(bankAccountProvider);
    ref.invalidate(walletProvider);
    setState(() => _editing = false);
    AppSnack.show(context, 'Rekening disimpan.', success: true);
  }

  String? _err(String key) => _local[key] ?? fieldError(key);

  @override
  Widget build(BuildContext context) {
    final bank = ref.watch(bankAccountProvider);
    return SecureScreenGuard(
      child: AppScaffold(
        title: 'Rekening bank',
        body: AsyncBody<BankAccount?>(
          value: bank,
          onRetry: () => ref.invalidate(bankAccountProvider),
          data: (context, b) => SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpace.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PrivacyNote(
                  'Nomor rekening disimpan terenkripsi dan hanya tampil tersamar.',
                ),
                const SizedBox(height: AppSpace.s16),
                if (b != null && !_editing) ...[
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(LucideIcons.landmark),
                        const SizedBox(width: AppSpace.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.bank, style: context.text.h3),
                              MoneyText(b.maskedNumber),
                              Text(b.holderName, style: context.text.bodySm),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.s16),
                  AppButton(
                    key: K.bankEdit,
                    label: 'Ganti rekening',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => setState(() => _editing = true),
                  ),
                ] else ...[
                  if (actionError != null) ActionErrorBox(error: actionError!),
                  Text('Bank', style: context.text.label),
                  const SizedBox(height: AppSpace.s8),
                  Semantics(
                    label: 'Bank',
                    child: DropdownButtonFormField<String>(
                      key: K.bankName,
                      initialValue: _bank,
                      hint: const Text('Pilih bank'),
                      items: [
                        for (final n in _banks)
                          DropdownMenuItem(value: n, child: Text(n)),
                      ],
                      onChanged: (v) => setState(() => _bank = v),
                    ),
                  ),
                  if (_err('bank') != null) FieldErrorText(_err('bank')!),
                  const SizedBox(height: AppSpace.s16),
                  AppTextField(
                    key: K.bankNumber,
                    controller: _number,
                    label: 'Nomor rekening',
                    sensitive: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 16,
                    errorText: _err('number'),
                  ),
                  const SizedBox(height: AppSpace.s16),
                  AppTextField(
                    key: K.bankHolder,
                    controller: _holder,
                    label: 'Nama pemilik rekening',
                    sensitive: true,
                    textInputAction: TextInputAction.done,
                    errorText: _err('holder_name'),
                  ),
                  const SizedBox(height: AppSpace.s24),
                  AppButton(
                    key: K.bankSave,
                    label: 'Simpan rekening',
                    large: true,
                    loading: busy,
                    onPressed: canAct ? () => _save(b != null) : null,
                  ),
                  if (b != null) ...[
                    const SizedBox(height: AppSpace.s8),
                    AppButton(
                      label: 'Batal',
                      variant: AppButtonVariant.text,
                      onPressed: () => setState(() => _editing = false),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
