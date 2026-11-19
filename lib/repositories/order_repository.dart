import '../models/shop_order.dart';
import '../queries/order_query.dart';
import 'crud.dart';

abstract interface class OrderRepository
    implements CrudRepository<ShopOrder, OrderQuery> {
  Future<List<ShopOrder>> getAll({bool includeDeleted = false});
  Future<ShopOrder> create(ShopOrder order);
  Future<ShopOrder> update(ShopOrder order);
}
