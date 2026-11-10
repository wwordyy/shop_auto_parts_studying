class CarModelQuery {
  final String search;
  final String? maker;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const CarModelQuery({
    this.search = '',
    this.maker,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  CarModelQuery copyWith({
    String? search,
    Object? maker = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return CarModelQuery(
      search: search ?? this.search,
      maker: maker == _unset ? this.maker : maker as String?,
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
    if (maker != null && maker!.isNotEmpty) params['maker'] = maker!;
    if (sortField != 'name' || !sortAscending) {
      params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['includeDeleted'] = 'true';
    return params;
  }

  factory CarModelQuery.fromParams(Map<String, String> params) {
    final sort = (params['sort'] ?? 'name,asc').split(',');
    final maker = params['maker'];
    return CarModelQuery(
      search: params['search'] ?? '',
      maker: (maker == null || maker.isEmpty) ? null : maker,
      sortField: sort.first.isEmpty ? 'name' : sort.first,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == 'true',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CarModelQuery &&
      search == other.search &&
      maker == other.maker &&
      sortField == other.sortField &&
      sortAscending == other.sortAscending &&
      page == other.page &&
      size == other.size &&
      includeDeleted == other.includeDeleted;

  @override
  int get hashCode => Object.hash(search, maker, sortField, sortAscending, page, size, includeDeleted);

  static const _unset = Object();
}
