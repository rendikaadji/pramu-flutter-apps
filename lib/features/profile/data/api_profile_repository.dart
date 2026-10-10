import 'package:pramu_apps/core/api/api_client.dart';
import 'package:pramu_apps/core/api/api_exception.dart';
import 'package:pramu_apps/core/models/shared.dart';
import 'package:pramu_apps/features/profile/domain/profile.dart';
import 'package:pramu_apps/features/profile/domain/profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._api);
  final ApiClient _api;

  @override
  Future<AssistantProfile?> myProfile() async {
    try {
      return AssistantProfile.fromJson(
        await _api.get('/me/assistant-profile') as Json,
      );
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<AssistantProfile> saveProfile(AssistantProfile p) async =>
      AssistantProfile.fromJson(
        await _api.put('/me/assistant-profile', data: p.toJson()) as Json,
      );

  @override
  Future<Paged<AssistantProfile>> search(AssistantFilter f, {String? cursor}) =>
      _api.getPage(
        '/assistants',
        AssistantProfile.fromJson,
        query: {...f.toQuery(), 'cursor': ?cursor},
      );

  @override
  Future<AssistantProfile> assistant(String userId) async =>
      AssistantProfile.fromJson(await _api.get('/assistants/$userId') as Json);
}
