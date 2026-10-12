import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/domain/listing_repository.dart';

class MockListingRepository implements ListingRepository {
  MockListingRepository(this._b);
  final MockBackend _b;

  Listing _owned(String id) {
    final l =
        _b.listings[id] ??
        apiFail(404, 'NOT_FOUND', 'Lowongan tidak ditemukan.');
    if (l.owner.id != _b.me.id) {
      apiFail(404, 'NOT_FOUND', 'Lowongan tidak ditemukan.');
    }
    return l;
  }

  /// Kedaluwarsa + cek pembayaran (invoice `paid` pada pengecekan ke-2 setelah `pay`).
  Listing _fresh(Listing l) {
    var cur = l;
    if (cur.status == ListingStatus.awaitingPayment) {
      final inv = _b.invoices.values
          .where((i) => i.kind == 'listing' && i.targetId == l.id)
          .lastOrNull;
      if (inv != null && ++inv.checks >= 2) {
        cur = cur.copyWith(
          status: ListingStatus.open,
          expiresAt: _b.now().add(const Duration(days: 30)),
        );
      }
    }
    final exp = cur.expiresAt;
    if (cur.status == ListingStatus.open &&
        exp != null &&
        exp.isBefore(_b.now())) {
      cur = cur.copyWith(status: ListingStatus.expired);
    }
    return _b.listings[l.id] = cur;
  }

  Listing _view(Listing l) {
    final me = _b.currentUserId;
    final applied = _b.applications.values.any(
      (a) => a.listingId == l.id && a.assistant.id == me && a.status.isActive,
    );
    return _b.listingFor(
      l.withApplied(applied),
      asAssistant: _b.viewerIsAssistant && l.owner.id != me,
    );
  }

  @override
  Future<Paged<Listing>> browse(ListingFilter f, {String? cursor}) =>
      _b.run(() {
        _b.me;
        final q = f.query?.toLowerCase();
        final all = [
          for (final l in _b.listings.values.map(_fresh))
            if (l.status == ListingStatus.open &&
                (q == null || l.title.toLowerCase().contains(q)) &&
                (f.category == null || l.category == f.category) &&
                (f.city == null || l.city == f.city) &&
                (f.unit == null || l.unit == f.unit) &&
                (f.maxBudget == null || l.budgetMin <= f.maxBudget!))
              _view(l),
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return _b.page(all, cursor);
      });

  @override
  Future<List<Listing>> mine() => _b.run(
    () => [
      for (final l in _b.listings.values)
        if (l.owner.id == _b.me.id) _view(l),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  @override
  Future<Listing> get(String id) => _b.run(() {
    _b.me;
    final l =
        _b.listings[id] ??
        apiFail(404, 'NOT_FOUND', 'Lowongan tidak ditemukan.');
    return _view(_fresh(l));
  });

  @override
  Future<Listing> saveDraft(ListingInput i, {String? id}) => _b.run(() {
    final fields = <String, List<String>>{
      if (i.title.trim().isEmpty) 'title': ['Judul wajib diisi'],
      if (!kCategories.contains(i.category)) 'category': ['Pilih kategori'],
      if (i.city.isEmpty) 'city': ['Kota wajib diisi'],
      if (i.periodCount < 1) 'period_count': ['Minimal 1 periode'],
      if (i.budgetMin <= 0) 'budget_min': ['Budget harus lebih dari 0'],
      if (i.budgetMin > i.budgetMax)
        'budget_max': ['Budget maksimum harus lebih besar dari minimum'],
      if (i.screeningQuestions.length > 5)
        'screening_questions': ['Maksimal 5 pertanyaan'],
    };
    if (fields.isNotEmpty) {
      apiFail(422, 'VALIDATION_FAILED', 'Periksa kembali data Anda.', fields);
    }
    final me = _b.me;
    final old = id == null ? null : _owned(id);
    if (old != null && !old.status.canEdit) {
      apiFail(409, 'LISTING_INVALID_STATE', 'Lowongan tidak bisa diubah lagi.');
    }
    final l = Listing(
      id: old?.id ?? _b.newId(),
      owner: _b.card(me.id),
      title: i.title.trim(),
      category: i.category,
      description: i.description,
      city: i.city,
      unit: i.unit,
      periodCount: i.periodCount,
      startDate: i.startDate,
      budgetMin: i.budgetMin,
      budgetMax: i.budgetMax,
      status: ListingStatus.draft,
      createdAt: old?.createdAt ?? _b.now(),
      requireSkck: i.requireSkck,
      skipInterview: i.skipInterview,
      screeningQuestions: i.screeningQuestions,
    );
    return _b.listings[l.id] = l;
  });

  @override
  Future<Invoice> pay(String id, {required String idempotencyKey}) => _b.run(
    () {
      final l = _owned(id);
      _b.requireVerified();
      if (!l.status.canPay) {
        apiFail(409, 'LISTING_INVALID_STATE', 'Status lowongan sudah berubah.');
      }
      final inv = MockInvoice(_b.newId(), 'listing', id, l.postingFee);
      _b.invoices[inv.id] = inv;
      _b.listings[id] = l.copyWith(status: ListingStatus.awaitingPayment);
      return Invoice(
        id: inv.id,
        url: 'https://checkout.xendit.co/web/${inv.id}',
        amount: inv.amount,
        expiresAt: _b.now().add(const Duration(hours: 24)),
      );
    },
  );

  @override
  Future<Listing> close(String id) => _b.run(() {
    final l = _owned(id);
    if (!l.status.canClose) {
      apiFail(409, 'LISTING_INVALID_STATE', 'Status lowongan sudah berubah.');
    }
    for (final a in _b.applications.values.where(
      (a) => a.listingId == id && a.status == ApplicationStatus.pending,
    )) {
      _b.applications[a.id] = a.copyWith(status: ApplicationStatus.rejected);
    }
    return _view(_b.listings[id] = l.copyWith(status: ListingStatus.closed));
  });
}
