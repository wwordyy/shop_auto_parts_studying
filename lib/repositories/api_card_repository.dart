import 'package:dio/dio.dart';

import '../core/api_support.dart';
import '../models/loyalty_card.dart';
import '../queries/card_query.dart';
import '../utils/page_result.dart';
import 'card_repository.dart';

class ApiCardRepository implements CardRepository {
  ApiCardRepository(Dio dio)
      : _api = ApiResource<LoyaltyCard>(
          dio: dio,
          path: '/cards',
          fromJson: LoyaltyCard.fromJson,
        );

  final ApiResource<LoyaltyCard> _api;

  Map<String, dynamic> _query(CardQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.customerId != null) 'customerId': query.customerId,
        if (query.active != null) 'active': query.active,
        if (query.minDiscount != null) 'minDiscount': query.minDiscount,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': true,
      };

  Map<String, dynamic> _body(LoyaltyCard card) => {
        'customerId': card.customerId,
        'number': card.number,
        'issuedAt': card.issuedAt.toIso8601String(),
        'discountPercent': card.discountPercent,
        'active': card.active,
      };

  @override
  Future<PageResult<LoyaltyCard>> find(CardQuery query) =>
      _api.find(_query(query));

  @override
  Future<List<LoyaltyCard>> getAll({bool includeDeleted = false}) =>
      _api.getAll(includeDeleted: includeDeleted);

  @override
  Future<LoyaltyCard?> findById(int id) => _api.findById(id);

  @override
  Future<LoyaltyCard> create(LoyaltyCard card) => _api.create(_body(card));

  @override
  Future<LoyaltyCard> update(LoyaltyCard card) =>
      _api.update(card.id, _body(card));

  @override
  Future<void> softDelete(int id) => _api.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _api.hardDelete(id);

  @override
  Future<void> restore(int id) => _api.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _api.deleteMany(ids);
}
