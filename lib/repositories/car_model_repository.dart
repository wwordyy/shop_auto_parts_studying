import '../models/car_model.dart';
import '../queries/car_model_query.dart';
import 'crud.dart';

abstract interface class CarModelRepository implements CrudRepository<CarModel, CarModelQuery> {
  Future<List<CarModel>> getAll({bool includeDeleted = false});
  Future<CarModel> create(CarModel model);
  Future<CarModel> update(CarModel model);
}
