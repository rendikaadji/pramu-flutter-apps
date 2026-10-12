import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pramu_apps/core/test_keys.dart';
import 'package:pramu_apps/features/booking/domain/booking.dart';
import 'package:pramu_apps/features/rating/presentation/screens/rating_screen.dart';
import 'package:pramu_apps/features/rating/presentation/screens/user_reviews_screen.dart';
import 'package:pramu_apps/features/report/presentation/report_routes.dart';

import 'helpers/rnr_harness.dart';

Finder _star(int i) => find
    .descendant(
      of: find.byKey(K.ratingStars),
      matching: find.byType(InkResponse),
    )
    .at(i);

void main() {
  late Rig rig;
  late String bookingId;

  setUp(() async {
    rig = await Rig.login('Bu Rina');
    final b = rig.backend;
    bookingId = b.bookings.values.firstWhere((x) => x.seeker.id == rig.meId).id;
    b.bookings[bookingId] = b.bookings[bookingId]!.copyWith(
      status: BookingStatus.completed,
    );
    b.completedAt[bookingId] = b.now();
  });

  testWidgets('M-90: bintang + konfirmasi + kirim -> ringkasan', (t) async {
    await t.pumpWidget(
      rig.app(home: RatingScreen(bookingId: bookingId), textScale: 1.3),
    );
    await t.pumpAndSettle();
    expect(find.byKey(K.ratingStars), findsOneWidget);
    expect(find.textContaining('Sisa waktu'), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.tap(_star(3));
    await t.pump();
    await t.ensureVisible(find.byKey(K.ratingSubmit));
    await t.tap(find.byKey(K.ratingSubmit));
    await t.pumpAndSettle();
    expect(find.text('Ulasan tidak bisa diubah setelah dikirim.'), findsOne);
    await t.tap(find.widgetWithText(TextButton, 'Kirim ulasan'));
    await t.pumpAndSettle();

    expect(find.text('Ulasan Anda'), findsOneWidget);
    expect(
      rig.backend.reviews.where((r) => r.review.bookingId == bookingId),
      hasLength(1),
    );
    expect(find.byKey(K.ratingSubmit), findsNothing);
  });

  testWidgets('M-90: bintang 1 -> tawaran lapor, ketuk membuka form', (
    t,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => RatingScreen(bookingId: bookingId),
        ),
        ...reportRoutes,
      ],
    );
    await t.pumpWidget(rig.app(router: router));
    await t.pumpAndSettle();
    expect(find.byKey(K.ratingReport), findsNothing);

    await t.tap(_star(0));
    await t.pump();
    expect(find.byKey(K.ratingReport), findsOneWidget);
    await t.ensureVisible(find.byKey(K.ratingReport));
    await t.tap(find.byKey(K.ratingReport));
    await t.pumpAndSettle();
    expect(find.byKey(K.reportDescription), findsOneWidget);
  });

  testWidgets('M-90: bintang 5 -> tanpa tawaran lapor', (t) async {
    await t.pumpWidget(rig.app(home: RatingScreen(bookingId: bookingId)));
    await t.pumpAndSettle();
    await t.tap(_star(4));
    await t.pump();
    expect(find.byKey(K.ratingReport), findsNothing);
  });

  testWidgets('M-90: tanpa bintang -> error field, tidak mengirim', (t) async {
    await t.pumpWidget(rig.app(home: RatingScreen(bookingId: bookingId)));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(K.ratingSubmit));
    await t.tap(find.byKey(K.ratingSubmit));
    await t.pumpAndSettle();
    expect(find.text('Pilih jumlah bintang, 1 sampai 5.'), findsOneWidget);
    expect(
      rig.backend.reviews.where((r) => r.review.bookingId == bookingId),
      isEmpty,
    );
  });

  testWidgets('M-90: 409 saat kirim -> dialog Data sudah berubah', (t) async {
    await t.pumpWidget(rig.app(home: RatingScreen(bookingId: bookingId)));
    await t.pumpAndSettle();
    final b = rig.backend;
    b.bookings[bookingId] = b.bookings[bookingId]!.copyWith(
      status: BookingStatus.cancelled,
    );
    await t.tap(_star(4));
    await t.pump();
    await t.ensureVisible(find.byKey(K.ratingSubmit));
    await t.tap(find.byKey(K.ratingSubmit));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(TextButton, 'Kirim ulasan'));
    await t.pumpAndSettle();
    expect(find.text('Data baru saja berubah'), findsOneWidget);
  });

  testWidgets('M-90: lewat 7 hari -> info penilaian otomatis', (t) async {
    rig.backend.completedAt[bookingId] = rig.backend.now().subtract(
      const Duration(days: 8),
    );
    await t.pumpWidget(rig.app(home: RatingScreen(bookingId: bookingId)));
    await t.pumpAndSettle();
    expect(find.text('Ulasan bintang 5 diberikan otomatis.'), findsOneWidget);
    expect(find.byKey(K.ratingSubmit), findsNothing);
  });

  testWidgets('M-91: ulasan revealed, label Otomatis; kosong', (t) async {
    final yuni = rig.backend.userByName('Yuni').id;
    await t.pumpWidget(rig.app(home: UserReviewsScreen(userId: yuni)));
    await t.pumpAndSettle();
    expect(find.text('Otomatis'), findsOneWidget);

    final ani = rig.backend.userByName('Lestari').id;
    await t.pumpWidget(rig.app(home: UserReviewsScreen(userId: ani)));
    await t.pumpAndSettle();
    expect(find.text('Belum ada ulasan'), findsOneWidget);
  });
}
