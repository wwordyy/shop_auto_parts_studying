class SupplierQuery {
  final String search;
  final String? country;
  final int? minRating;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const SupplierQuery({
    this.search = '',
    this.country,
    this.minRating,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  SupplierQuery copyWith({
    String? search,
    Object? country = _unset,
    Object? minRating = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return SupplierQuery(
      search: search ?? this.search,
      country: country == _unset ? this.country : country as String?,
      minRating: minRating == _unset ? this.minRating : minRating as int?,
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
    if (country != null && country!.isNotEmpty) params['country'] = country!;
    if (minRating != null) params['minRating'] = '$minRating';
    if (sortField != 'name' || !sortAscending) {
      params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['includeDeleted'] = 'true';
    return params;
  }

  factory SupplierQuery.fromParams(Map<String, String> params) {
    final sort = (params['sort'] ?? 'name,asc').split(',');
    final country = params['country'];
    return SupplierQuery(
      search: params['search'] ?? '',
      country: (country == null || country.isEmpty) ? null : country,
      minRating: int.tryParse(params['minRating'] ?? ''),
      sortField: sort.first.isEmpty ? 'name' : sort.first,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == 'true',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SupplierQuery &&
      search == other.search &&
      country == other.country &&
      minRating == other.minRating &&
      sortField == other.sortField &&
      sortAscending == other.sortAscending &&
      page == other.page &&
      size == other.size &&
      includeDeleted == other.includeDeleted;

  @override
  int get hashCode => Object.hash(
        search,
        country,
        minRating,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );

  static const _unset = Object();
}
