import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/listing/domain/listing.dart';
import 'package:pramu_apps/features/listing/domain/listing_repository.dart';

class ApiListingRepository implements ListingRepository {
  ApiListingRepository(this._api);
  final ApiClient _api;

  @override
  Future<Paged<Listing>> browse(ListingFilter f, {String? cursor}) =>
      _api.getPage(
        '/listings',
        Listing.fromJson,
        query: {...f.toQuery(), 'cursor': ?cursor},
      );

  @override
  Future<List<Listing>> mine() async => [
    for (final l in await _api.get('/me/listings') as List)
      Listing.fromJson(l as Json),
  ];

  @override
  Future<Listing> get(String id) async =>
      Listing.fromJson(await _api.get('/listings/$id') as Json);

  @override
  Future<Listing> saveDraft(ListingInput input, {String? id}) async {
    final d = id == null
        ? await _api.post('/listings', data: input.toJson())
        : await _api.put('/listings/$id', data: input.toJson());
    return Listing.fromJson(d as Json);
  }

  @override
  Future<Invoice> pay(String id, {required String idempotencyKey}) async =>
      Invoice.fromJson(
        await _api.post(
          '/listings/$id/pay',
          options: ApiClient.idempotent(idempotencyKey),
        ) as Json,
      );

  @override
  Future<Listing> close(String id) async =>
      Listing.fromJson(await _api.post('/listings/$id/close') as Json);
}
