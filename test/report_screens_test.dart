import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/router/routes.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/report/data/mock_report_repository.dart';
import 'package:pramu_apps/features/report/domain/report.dart';
import 'package:pramu_apps/features/report/presentation/report_routes.dart';
import 'package:pramu_apps/features/report/presentation/widgets/evidence_picker.dart';

import 'helpers/rnr_harness.dart';

class _FakePicker implements EvidencePicker {
  int calls = 0;

  @override
  Future<String?> pick({required bool camera}) async {
    calls++;
    return '/tmp/tidak-ada-${camera ? 'kamera' : 'galeri'}.jpg';
  }
}

GoRouter _router(String initial) =>
    GoRouter(initialLocation: initial, routes: reportRoutes);

void main() {
  late Rig rig;

  setUp(() async => rig = await Rig.login('Siti'));

  Future<Report> seedReport({bool share = false}) async {
    final repo = MockReportRepository(rig.backend);
    var r = await repo.submit(
      const ReportInput(
        type: ReportType.behavior,
        description: 'Pencari tidak sopan saat serah terima.',
      ),
    );
    if (share) {
      final c = rig.backend.conversations.values.firstWhere(
        (c) => c.assistantId == rig.meId,
      );
      r = await repo.shareConversation(r.id, conversationId: c.id);
    }
    return r;
  }

  testWidgets('M-95: validasi uraian lalu kirim -> ke status laporan', (
    t,
  ) async {
    await t.pumpWidget(
      rig.app(router: _router(Routes.reportNew), textScale: 1.3),
    );
    await t.pumpAndSettle();
    expect(find.byKey(K.reportType('fraud')), findsOneWidget);

    await t.ensureVisible(find.byKey(K.reportSubmit));
    await t.tap(find.byKey(K.reportSubmit));
    await t.pumpAndSettle();
    expect(
      find.text('Ceritakan sedikit lebih rinci, minimal 10 karakter.'),
      findsOneWidget,
    );
    expect(rig.backend.reports, isEmpty);

    await t.ensureVisible(find.byKey(K.reportType('fraud')));
    await t.tap(find.byKey(K.reportType('fraud')));
    await t.enterText(
      find.descendant(
        of: find.byKey(K.reportDescription),
        matching: find.byType(TextField),
      ),
      'Ada permintaan transfer di luar aplikasi.',
    );
    await t.ensureVisible(find.byKey(K.reportSubmit));
    await t.tap(find.byKey(K.reportSubmit));
    await t.pumpAndSettle();

    expect(rig.backend.reports, hasLength(1));
    expect(rig.backend.reports.values.first.$2.type, ReportType.fraud);
    expect(find.text('Status laporan'), findsOneWidget);
  });

  testWidgets('M-95: ?user= tampil sebagai konteks dan terkirim', (t) async {
    final yuni = rig.backend.userByName('Yuni');
    await t.pumpWidget(
      rig.app(router: _router('${Routes.reportNew}?user=${yuni.id}')),
    );
    await t.pumpAndSettle();
    expect(find.byKey(K.reportUser), findsOneWidget);
    expect(find.textContaining('Melaporkan:'), findsOneWidget);

    await t.enterText(
      find.descendant(
        of: find.byKey(K.reportDescription),
        matching: find.byType(TextField),
      ),
      'Pengguna ini meminta transfer di luar aplikasi.',
    );
    await t.ensureVisible(find.byKey(K.reportSubmit));
    await t.tap(find.byKey(K.reportSubmit));
    await t.pumpAndSettle();
    expect(rig.backend.reports, hasLength(1));
    expect(find.text('Status laporan'), findsOneWidget);
  });

  testWidgets(
    'M-95: lapor dari kontrak mengaitkan kontrak tanpa mengubah status',
    (t) async {
      final bk = rig.backend.bookings.values.firstWhere(
        (b) => b.assistant.id == rig.meId,
      );
      final r = await MockReportRepository(rig.backend).submit(
        ReportInput(
          type: ReportType.behavior,
          description: 'Pencari bersikap tidak pantas.',
          bookingId: bk.id,
        ),
      );
      expect(r.bookingId, bk.id);
      expect(rig.backend.bookings[bk.id]!.status, bk.status);
    },
  );

  testWidgets('M-96: consent eksplisit -> dibagikan 7 hari', (t) async {
    final r = await seedReport();
    final c = rig.backend.conversations.values.firstWhere(
      (c) => c.assistantId == rig.meId,
    );
    await t.pumpWidget(
      rig.app(router: _router('/reports/${r.id}/share?conversation=${c.id}')),
    );
    await t.pumpAndSettle();
    expect(find.textContaining('7 hari'), findsWidgets);
    expect(find.byKey(K.shareDecline), findsOneWidget);
    expect(rig.backend.reports[r.id]!.$2.share, isNull);

    await t.ensureVisible(find.byKey(K.shareConsent));
    await t.tap(find.byKey(K.shareConsent));
    await t.pumpAndSettle();
    expect(rig.backend.reports[r.id]!.$2.share, isNotNull);
    expect(find.textContaining('Dibagikan hingga'), findsOneWidget);
  });

  testWidgets('M-96: menolak tidak membagikan apa pun', (t) async {
    final r = await seedReport();
    final c = rig.backend.conversations.values.firstWhere(
      (c) => c.assistantId == rig.meId,
    );
    await t.pumpWidget(
      rig.app(router: _router('/reports/${r.id}/share?conversation=${c.id}')),
    );
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(K.shareDecline));
    await t.tap(find.byKey(K.shareDecline));
    await t.pumpAndSettle();
    expect(rig.backend.reports[r.id]!.$2.share, isNull);
  });

  testWidgets('M-97: cabut persetujuan (konfirmasi) + tambah bukti', (t) async {
    final r = await seedReport(share: true);
    final picker = _FakePicker();
    await t.pumpWidget(
      rig.app(
        router: _router(Routes.reportStatus(r.id)),
        overrides: [evidencePickerProvider.overrideWithValue(picker)],
        textScale: 1.3,
      ),
    );
    await t.pumpAndSettle();
    expect(find.textContaining('Dibagikan hingga'), findsOneWidget);

    await t.ensureVisible(find.byKey(K.reportAddEvidence));
    await t.tap(find.byKey(K.reportAddEvidence));
    await t.pumpAndSettle();
    await t.tap(find.text('Dari galeri'));
    await t.pumpAndSettle();
    expect(picker.calls, 1);
    expect(find.text('Bukti sudah ditambahkan.'), findsOneWidget);
    await t.pump(const Duration(seconds: 5)); // snackbar menutupi tombol
    await t.pumpAndSettle();

    await t.ensureVisible(find.byKey(K.reportRevokeShare));
    await t.tap(find.byKey(K.reportRevokeShare));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(TextButton, 'Cabut persetujuan'));
    await t.pumpAndSettle();
    expect(rig.backend.reports[r.id]!.$2.share!.revoked, isTrue);
    expect(find.text('Persetujuan sudah dicabut'), findsOneWidget);
    expect(find.byKey(K.reportRevokeShare), findsNothing);
  });

  testWidgets('M-97: laporan tidak ada -> pesan error server', (t) async {
    await t.pumpWidget(
      rig.app(router: _router('/reports/01ARZ3NDEKTSV4RRFFQ69G5FAV')),
    );
    await t.pumpAndSettle();
    expect(find.text('Laporan tidak ditemukan.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('M-25: riwayat laporan dan persetujuan', (t) async {
    await seedReport(share: true);
    await t.pumpWidget(rig.app(router: _router(Routes.privacy)));
    await t.pumpAndSettle();
    expect(find.text('Perilaku'), findsOneWidget);
    expect(find.textContaining('Dibagikan hingga'), findsOneWidget);
  });
}
