import 'package:flutter/material.dart';
import 'package:pramu_apps/shared/app_ui/app_ui.dart';

/// Baris label di kiri dan nilai di kanan, untuk rincian ajuan dan pekerjaan.
class BarisInfo extends StatelessWidget {
  const BarisInfo(this.label, this.nilai, {super.key});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: context.text.bodySm)),
        Flexible(
          child: Text(
            nilai,
            style: context.text.label,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );
}
