import 'package:flutter_test/flutter_test.dart';
import 'package:shop_auto_parts/core/api_client.dart';

void main() {
  test('запросы /auth/login и /auth/refresh не идут на обновление токена', () {
    expect(isAuthPath('/auth/login'), isTrue);
    expect(isAuthPath('/auth/register'), isTrue);
    expect(isAuthPath('/auth/refresh'), isTrue);
    expect(isAuthPath('/auth/logout'), isTrue);
    expect(isAuthPath('/auth/me'), isFalse);
    expect(isAuthPath('/parts'), isFalse);
  });
}
