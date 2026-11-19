import 'package:dio/dio.dart';

import '../core/api_support.dart';
import '../models/shop_order.dart';
import '../queries/order_query.dart';
import '../utils/page_result.dart';
import 'order_repository.dart';

class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(Dio dio)
      : _api = ApiResource<ShopOrder>(
          dio: dio,
          path: '/orders',
          fromJson: ShopOrder.fromJson,
        );

  final ApiResource<ShopOrder> _api;

  Map<String, dynamic> _query(OrderQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.customerId != null) 'customerId': query.customerId,
        if (query.status != null && query.status!.isNotEmpty)
          'status': query.status,
        if (query.minTotal != null) 'minTotal': query.minTotal,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': true,
      };

  Map<String, dynamic> _body(ShopOrder order) => {
        'customerId': order.customerId,
        'status': order.status,
        'items': order.items
            .map((item) => {
                  'partId': item.partId,
                  'quantity': item.quantity,
                })
            .toList(),
      };

  @override
  Future<PageResult<ShopOrder>> find(OrderQuery query) =>
      _api.find(_query(query));

  @override
  Future<List<ShopOrder>> getAll({bool includeDeleted = false}) =>
      _api.getAll(includeDeleted: includeDeleted);

  @override
  Future<ShopOrder?> findById(int id) => _api.findById(id);

  @override
  Future<ShopOrder> create(ShopOrder order) => _api.create(_body(order));

  @override
  Future<ShopOrder> update(ShopOrder order) =>
      _api.update(order.id, _body(order));

  @override
  Future<void> softDelete(int id) => _api.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _api.hardDelete(id);

  @override
  Future<void> restore(int id) => _api.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _api.deleteMany(ids);
}
