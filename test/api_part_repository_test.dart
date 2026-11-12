import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_auto_parts/core/api_client.dart';
import 'package:shop_auto_parts/core/api_exceptions.dart';
import 'package:shop_auto_parts/models/auto_part.dart';
import 'package:shop_auto_parts/queries/part_query.dart';
import 'package:shop_auto_parts/repositories/api_part_repository.dart';

import 'support/scripted_adapter.dart';

Dio dioWith(Future<ResponseBody> Function(RequestOptions options) handler) {
  final dio = buildDio();
  dio.httpClientAdapter = ScriptedAdapter(handler);
  return dio;
}

void main() {
  test('find разбирает страницу с сервера', () async {
    final repo = ApiPartRepository(
      dioWith((options) async {
        expect(options.method, 'GET');
        expect(options.path, '/parts');
        expect(options.queryParameters['page'], 1);
        return jsonResponse({
          'items': [
            {
              'id': 1,
              'name': 'Свеча Bosch',
              'sku': 'FR7DC+',
              'year': 2022,
              'price': 390,
              'brand': {'id': 1, 'name': 'Bosch'},
              'categories': [
                {'id': 1, 'name': 'Двигатель'}
              ],
              'carModels': [
                {'id': 6, 'name': 'Solaris', 'maker': 'Hyundai'}
              ],
              'stockTotal': 40,
              'stockAvailable': 28,
            }
          ],
          'page': 1,
          'size': 10,
          'total': 1,
          'totalPages': 1,
        });
      }),
    );

    final page = await repo.find(const PartQuery());
    expect(page.total, 1);
    expect(page.items.single.name, 'Свеча Bosch');
    expect(page.items.single.brandId, 1);
    expect(page.items.single.categoryIds, [1]);
    expect(page.items.single.carModelIds, [6]);
  });

  test('create превращает 422 в ValidationException', () async {
    final repo = ApiPartRepository(
      dioWith((options) async {
        return jsonResponse({
          'message': 'Ошибка валидации',
          'errors': {'sku': 'Артикул уже используется'},
        }, 422);
      }),
    );

    expect(
      () => repo.create(
        const AutoPart(
          id: 0,
          name: 'Свеча',
          sku: 'FR7DC+',
          year: 2022,
          price: 390,
          brandId: 1,
          categoryIds: [1],
          carModelIds: [6],
          stockTotal: 10,
          stockAvailable: 10,
        ),
      ),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.errors['sku'],
          'sku',
          'Артикул уже используется',
        ),
      ),
    );
  });

  test('недоступность сервера превращается в NetworkException', () async {
    final repo = ApiPartRepository(
      dioWith((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }),
    );

    expect(repo.find(const PartQuery()), throwsA(isA<NetworkException>()));
  });

  test('продажа без остатка даёт ConflictException', () async {
    final repo = ApiPartRepository(
      dioWith((options) async {
        expect(options.path, '/parts/1/sell');
        return jsonResponse({'message': 'Нет доступного остатка для продажи'}, 409);
      }),
    );

    expect(repo.sell(1), throwsA(isA<ConflictException>()));
  });

  test('findById при 404 возвращает null', () async {
    final repo = ApiPartRepository(
      dioWith((options) async {
        return jsonResponse({'message': 'Объект не найден'}, 404);
      }),
    );

    expect(await repo.findById(99), isNull);
  });
}
