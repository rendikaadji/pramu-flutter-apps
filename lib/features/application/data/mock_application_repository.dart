import 'package:pramu_apps/core/mock/mock_backend.dart';
import 'package:pramu_apps/core/mock/mock_flows.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/application/domain/application_repository.dart';
import 'package:pramu_apps/features/auth/domain/auth.dart';
import 'package:pramu_apps/features/chat/domain/chat.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/notification/domain/notification.dart';
import 'package:pramu_apps/features/verification/domain/verification.dart';

class MockApplicationRepository implements ApplicationRepository {
  MockApplicationRepository(this._b);
  final MockBackend _b;

  Application _party(String id) {
    final uid = _b.me.id;
    final a = _b.applications[id];
    if (a == null || (a.seeker.id != uid && a.assistant.id != uid)) {
      apiFail(404, 'NOT_FOUND', 'Lamaran tidak ditemukan.');
    }
    _b.reactApplication(id);
    return _b.applications[id]!;
  }

  Application _out(Application a) => a;

  @override
  Future<Application> apply(String listingId, ApplyInput input) => _b.run(() {
    final me = _b.me;
    _b.requireVerified();
    final l =
        _b.listings[listingId] ??
        apiFail(404, 'NOT_FOUND', 'Lowongan tidak ditemukan.');
    if (!l.status.acceptsApplications) {
      apiFail(409, 'LISTING_INVALID_STATE', 'Lowongan sudah ditutup.');
    }
    if (_b.applications.values.any(
      (a) =>
          a.listingId == listingId &&
          a.assistant.id == me.id &&
          a.status.isActive,
    )) {
      apiFail(409, 'APPLICATION_DUPLICATE', 'Anda sudah melamar lowongan ini.');
    }
    if (l.requireSkck && me.skck.status != VerificationStatus.verified) {
      apiFail(403, 'SKCK_REQUIRED', 'Lowongan ini mewajibkan SKCK.');
    }
    final fields = <String, List<String>>{
      if (input.message.trim().isEmpty) 'message': ['Pesan wajib diisi'],
      if (input.proposedRate <= 0)
        'proposed_rate': ['Tarif harus lebih dari 0'],
    };
    if (fields.isNotEmpty) {
      apiFail(422, 'VALIDATION_FAILED', 'Periksa kembali data Anda.', fields);
    }
    final convId = _b.newId();
    final app = Application(
      id: _b.newId(),
      listingId: l.id,
      listingTitle: l.title,
      seeker: l.owner,
      assistant: _b.card(me.id),
      message: input.message.trim(),
      proposedRate: input.proposedRate,
      status: ApplicationStatus.pending,
      createdAt: _b.now(),
      answers: input.answers,
      skckVerified: me.skck.status.isVerified,
      conversationId: convId,
    );
    _b.applications[app.id] = app;
    _b.conversations[convId] = MockConversation(
      convId,
      app.id,
      l.owner.id,
      me.id,
    );
    _b.messages[convId] = [
      ChatMessage(
        id: _b.newId(),
        conversationId: convId,
        senderId: me.id,
        text: MockBackend.maskContacts(app.message),
        createdAt: _b.now(),
      ),
    ];
    _b.listings[l.id] = l.copyWith(applicantCount: l.applicantCount + 1);
    _b.notify(
      l.owner.id,
      NotificationType.application,
      'Pelamar baru',
      '${me.name} melamar "${l.title}".',
      app.id,
    );
    return _out(app);
  });

  @override
  Future<List<Application>> mine() => _b.run(() {
    final uid = _b.me.id;
    final ids = [
      for (final a in _b.applications.values)
        if (a.assistant.id == uid) a.id,
    ];
    ids.forEach(_b.reactApplication);
    return [for (final id in ids) _out(_b.applications[id]!)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<List<Application>> forListing(String listingId) => _b.run(() {
    final l = _b.listings[listingId];
    if (l == null || l.owner.id != _b.me.id) {
      apiFail(404, 'NOT_FOUND', 'Lowongan tidak ditemukan.');
    }
    final ids = [
      for (final a in _b.applications.values)
        if (a.listingId == listingId) a.id,
    ];
    ids.forEach(_b.reactApplication);
    return [for (final id in ids) _b.applications[id]!]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<Application> get(String id) => _b.run(() => _out(_party(id)));

  @override
  Future<Application> act(
    String id,
    ApplicationAction action, {
    String? reason,
  }) => _b.run(() {
    final app = _party(id);
    final role = app.seeker.id == _b.me.id ? Role.seeker : Role.assistant;
    final l = _b.listings[app.listingId]!;
    final allowed =
        app.status.allowedActions(role).contains(action) &&
        (action != ApplicationAction.accept ||
            app.status != ApplicationStatus.shortlisted ||
            l.skipInterview);
    if (!allowed) {
      apiFail(
        409,
        'APPLICATION_INVALID_STATE',
        'Status lamaran sudah berubah.',
      );
    }
    final next = switch (action) {
      ApplicationAction.shortlist => ApplicationStatus.shortlisted,
      ApplicationAction.reject => ApplicationStatus.rejected,
      ApplicationAction.accept => ApplicationStatus.accepted,
      ApplicationAction.withdraw => ApplicationStatus.withdrawn,
      _ => throw ArgumentError(
        'Gunakan InterviewRepository/BookingRepository untuk $action',
      ),
    };
    final other = role == Role.seeker ? app.assistant.id : app.seeker.id;
    _b.notify(
      other,
      NotificationType.application,
      'Status lamaran: ${next.label}',
      app.listingTitle,
      id,
    );
    return _out(_b.applications[id] = app.copyWith(status: next));
  });

  @override
  Future<void> invite({
    required String assistantId,
    required String listingId,
    String? message,
  }) => _b.run(() {
    final me = _b.me;
    final l = _b.listings[listingId];
    if (l == null || l.owner.id != me.id) {
      apiFail(404, 'NOT_FOUND', 'Lowongan tidak ditemukan.');
    }
    if (!_b.profiles.containsKey(assistantId)) {
      apiFail(404, 'NOT_FOUND', 'Asisten tidak ditemukan.');
    }
    if (l.status != ListingStatus.open) {
      apiFail(409, 'LISTING_INVALID_STATE', 'Lowongan belum tayang.');
    }
    if (_b.invitations.any(
      (e) => e.$1 == assistantId && e.$2.listingId == listingId,
    )) {
      apiFail(409, 'INVITATION_DUPLICATE', 'Asisten ini sudah diajak.');
    }
    _b.invitations.add((
      assistantId,
      Invitation(
        id: _b.newId(),
        listingId: l.id,
        listingTitle: l.title,
        seeker: l.owner,
        createdAt: _b.now(),
        message: message,
      ),
    ));
    _b.notify(
      assistantId,
      NotificationType.application,
      'Anda diajak melamar',
      l.title,
      listingId,
    );
  });

  @override
  Future<List<Invitation>> invitations() => _b.run(
    () => [
      for (final (aid, inv) in _b.invitations)
        if (aid == _b.me.id) inv,
    ],
  );
}
