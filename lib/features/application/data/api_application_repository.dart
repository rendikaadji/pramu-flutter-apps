import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/features/application/domain/application.dart';
import 'package:pramu_apps/features/application/domain/application_repository.dart';

class ApiApplicationRepository implements ApplicationRepository {
  ApiApplicationRepository(this._api);
  final ApiClient _api;

  List<Application> _list(Object? d) => [
    for (final a in d as List) Application.fromJson(a as Json),
  ];

  @override
  Future<Application> apply(String listingId, ApplyInput input) async =>
      Application.fromJson(
        await _api.post(
          '/listings/$listingId/applications',
          data: input.toJson(),
        ) as Json,
      );

  @override
  Future<List<Application>> mine() async =>
      _list(await _api.get('/me/applications'));

  @override
  Future<List<Application>> forListing(String listingId) async =>
      _list(await _api.get('/listings/$listingId/applications'));

  @override
  Future<Application> get(String id) async =>
      Application.fromJson(await _api.get('/applications/$id') as Json);

  @override
  Future<Application> act(
    String id,
    ApplicationAction action, {
    String? reason,
  }) async {
    final path = switch (action) {
      ApplicationAction.shortlist => 'shortlist',
      ApplicationAction.reject => 'reject',
      ApplicationAction.accept => 'accept',
      ApplicationAction.withdraw => 'withdraw',
      _ => throw ArgumentError(
        'Gunakan InterviewRepository/BookingRepository untuk $action',
      ),
    };
    return Application.fromJson(
      await _api.post('/applications/$id/$path', data: {'reason': ?reason})
          as Json,
    );
  }

  @override
  Future<void> invite({
    required String assistantId,
    required String listingId,
    String? message,
  }) => _api.post(
    '/assistants/$assistantId/invitations',
    data: {'listing_id': listingId, 'message': ?message},
  );

  @override
  Future<List<Invitation>> invitations() async => [
    for (final i in await _api.get('/me/invitations') as List)
      Invitation.fromJson(i as Json),
  ];
}
