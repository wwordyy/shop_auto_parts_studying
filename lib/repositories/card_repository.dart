import '../models/loyalty_card.dart';
import '../queries/card_query.dart';
import 'crud.dart';

abstract interface class CardRepository
    implements CrudRepository<LoyaltyCard, CardQuery> {
  Future<List<LoyaltyCard>> getAll({bool includeDeleted = false});
  Future<LoyaltyCard> create(LoyaltyCard card);
  Future<LoyaltyCard> update(LoyaltyCard card);
}
