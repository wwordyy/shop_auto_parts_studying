class CardQuery {
  final String search;
  final int? customerId;
  final bool? active;
  final int? minDiscount;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const CardQuery({
    this.search = '',
    this.customerId,
    this.active,
    this.minDiscount,
    this.sortField = 'number',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  CardQuery copyWith({
    String? search,
    Object? customerId = _unset,
    Object? active = _unset,
    Object? minDiscount = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return CardQuery(
      search: search ?? this.search,
      customerId: customerId == _unset ? this.customerId : customerId as int?,
      active: active == _unset ? this.active : active as bool?,
      minDiscount:
          minDiscount == _unset ? this.minDiscount : minDiscount as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  Map<String, String> toParams() {
    final params = <String, String>{};
    if (search.isNotEmpty) params['search'] = search;
    if (customerId != null) params['customerId'] = '$customerId';
    if (active != null) params['active'] = '$active';
    if (minDiscount != null) params['minDiscount'] = '$minDiscount';
    if (sortField != 'number' || !sortAscending) {
      params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['includeDeleted'] = 'true';
    return params;
  }

  factory CardQuery.fromParams(Map<String, String> params) {
    final sort = (params['sort'] ?? 'number,asc').split(',');
    final active = params['active'];
    return CardQuery(
      search: params['search'] ?? '',
      customerId: int.tryParse(params['customerId'] ?? ''),
      active: active == null
          ? null
          : active == 'true'
              ? true
              : active == 'false'
                  ? false
                  : null,
      minDiscount: int.tryParse(params['minDiscount'] ?? ''),
      sortField: sort.first.isEmpty ? 'number' : sort.first,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == 'true',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CardQuery &&
      search == other.search &&
      customerId == other.customerId &&
      active == other.active &&
      minDiscount == other.minDiscount &&
      sortField == other.sortField &&
      sortAscending == other.sortAscending &&
      page == other.page &&
      size == other.size &&
      includeDeleted == other.includeDeleted;

  @override
  int get hashCode => Object.hash(
        search,
        customerId,
        active,
        minDiscount,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );

  static const _unset = Object();
}
