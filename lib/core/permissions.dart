import '../models/app_user.dart';

/// Клиентская матрица прав. Нужна, чтобы спрятать недоступные кнопки
/// и закрыть маршруты. Настоящее решение всегда принимает сервер по JWT.
class Permissions {
  final Role? role;

  const Permissions(this.role);

  bool get isAuthenticated => role != null;

  bool hasAtLeast(Role minimum) =>
      role != null && role!.level >= minimum.level;

  bool get canViewCatalog => isAuthenticated;

  bool get canMutate => hasAtLeast(Role.manager);

  bool get canSell => hasAtLeast(Role.manager);

  bool get canSoftDelete => hasAtLeast(Role.manager);

  bool get canHardDelete => role == Role.admin;

  bool get canRestore => role == Role.admin;

  bool get canViewDeleted => role == Role.admin;

  bool get canManageUsers => role == Role.admin;

  bool get canViewStats => role == Role.admin;

  /// Уникальный экран менеджера: клиенты и карты лояльности.
  bool get canAccessCustomers => role == Role.manager;

  /// Уникальный экран покупателя: личный кабинет.
  bool get canAccessCabinet => role == Role.buyer;

  bool canOpen(String path) {
    if (path.startsWith('/login') || path.startsWith('/register') || path == '/forbidden') {
      return true;
    }
    if (!isAuthenticated) return false;
    if (path.startsWith('/cabinet')) return canAccessCabinet;
    if (path.startsWith('/customers')) return canAccessCustomers;
    if (path.startsWith('/admin/users')) return canManageUsers;
    if (path.startsWith('/admin/stats')) return canViewStats;
    if (_isMutationPath(path)) return canMutate;
    if (path.startsWith('/parts') ||
        path.startsWith('/brands') ||
        path.startsWith('/categories') ||
        path.startsWith('/cars')) {
      return canViewCatalog;
    }
    return isAuthenticated;
  }

  static bool _isMutationPath(String path) {
    return path.endsWith('/new') || path.endsWith('/edit');
  }
}
