import 'package:flutter_test/flutter_test.dart';
import 'package:shop_auto_parts/core/permissions.dart';
import 'package:shop_auto_parts/models/app_user.dart';
import 'package:shop_auto_parts/validation/validators.dart';

void main() {
  group('разграничение прав по ролям', () {
    test('покупатель видит каталог и кабинет, но не может менять данные', () {
      const perms = Permissions(Role.buyer);
      expect(perms.canViewCatalog, isTrue);
      expect(perms.canAccessCabinet, isTrue);
      expect(perms.canMutate, isFalse);
      expect(perms.canSell, isFalse);
      expect(perms.canOpen('/cabinet'), isTrue);
      expect(perms.canOpen('/parts'), isTrue);
      expect(perms.canOpen('/parts/new'), isFalse);
      expect(perms.canOpen('/customers'), isFalse);
      expect(perms.canOpen('/admin/users'), isFalse);
    });

    test('менеджер управляет каталогом и клиентами, но не удаляет навсегда', () {
      const perms = Permissions(Role.manager);
      expect(perms.canMutate, isTrue);
      expect(perms.canSell, isTrue);
      expect(perms.canSoftDelete, isTrue);
      expect(perms.canAccessCustomers, isTrue);
      expect(perms.canHardDelete, isFalse);
      expect(perms.canRestore, isFalse);
      expect(perms.canManageUsers, isFalse);
      expect(perms.canAccessCabinet, isFalse);
      expect(perms.canOpen('/customers/new'), isTrue);
      expect(perms.canOpen('/admin/stats'), isFalse);
      expect(perms.canOpen('/cabinet'), isFalse);
    });

    test('администратор восстанавливает записи и видит пользователей', () {
      const perms = Permissions(Role.admin);
      expect(perms.canHardDelete, isTrue);
      expect(perms.canRestore, isTrue);
      expect(perms.canViewDeleted, isTrue);
      expect(perms.canManageUsers, isTrue);
      expect(perms.canViewStats, isTrue);
      expect(perms.canAccessCustomers, isFalse);
      expect(perms.canOpen('/admin/users'), isTrue);
      expect(perms.canOpen('/admin/stats'), isTrue);
      expect(perms.canOpen('/parts/1/edit'), isTrue);
    });

    test('покупатель не открывает чужие адреса', () {
      const perms = Permissions(Role.buyer);
      expect(perms.canOpen('/admin/users'), isFalse);
      expect(perms.canOpen('/admin/stats'), isFalse);
      expect(perms.canOpen('/brands/2/edit'), isFalse);
      expect(perms.canOpen('/categories/new'), isFalse);
    });

    test('неаутентифицированный пользователь не открывает внутренние экраны', () {
      const perms = Permissions(null);
      expect(perms.canViewCatalog, isFalse);
      expect(perms.canOpen('/parts'), isFalse);
      expect(perms.canOpen('/login'), isTrue);
      expect(perms.canOpen('/register'), isTrue);
    });

    test('hasAtLeast учитывает иерархию ролей', () {
      expect(const Permissions(Role.admin).hasAtLeast(Role.manager), isTrue);
      expect(const Permissions(Role.manager).hasAtLeast(Role.buyer), isTrue);
      expect(const Permissions(Role.buyer).hasAtLeast(Role.manager), isFalse);
    });
  });

  group('пароль при регистрации', () {
    test('требует длину, цифру и спецсимвол по мере ввода', () {
      expect(Validators.passwordHasMinLength('short'), isFalse);
      expect(Validators.passwordHasMinLength('longpass'), isTrue);
      expect(Validators.passwordHasDigit('password'), isFalse);
      expect(Validators.passwordHasDigit('password1'), isTrue);
      expect(Validators.passwordHasSpecial('password1'), isFalse);
      expect(Validators.passwordHasSpecial('password1!'), isTrue);
      expect(Validators.passwordIsStrong('password1!'), isTrue);
      expect(Validators.password('abc'), isNotNull);
      expect(Validators.password('password1!'), isNull);
    });
  });
}
