class PartQuery {
  final String search;
  final int? categoryId;
  final int? brandId;
  final int? carModelId;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const PartQuery({
    this.search = '',
    this.categoryId,
    this.brandId,
    this.carModelId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  PartQuery copyWith({
    String? search,
    Object? categoryId = _unset,
    Object? brandId = _unset,
    Object? carModelId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return PartQuery(
      search: search ?? this.search,
      categoryId: categoryId == _unset ? this.categoryId : categoryId as int?,
      brandId: brandId == _unset ? this.brandId : brandId as int?,
      carModelId: carModelId == _unset ? this.carModelId : carModelId as int?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
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
    if (categoryId != null) params['categoryId'] = '$categoryId';
    if (brandId != null) params['brandId'] = '$brandId';
    if (carModelId != null) params['carModelId'] = '$carModelId';
    if (yearFrom != null) params['yearFrom'] = '$yearFrom';
    if (yearTo != null) params['yearTo'] = '$yearTo';
    if (sortField != 'name' || !sortAscending) {
      params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['includeDeleted'] = 'true';
    return params;
  }

  factory PartQuery.fromParams(Map<String, String> params) {
    final sort = (params['sort'] ?? 'name,asc').split(',');
    return PartQuery(
      search: params['search'] ?? '',
      categoryId: int.tryParse(params['categoryId'] ?? ''),
      brandId: int.tryParse(params['brandId'] ?? ''),
      carModelId: int.tryParse(params['carModelId'] ?? ''),
      yearFrom: int.tryParse(params['yearFrom'] ?? ''),
      yearTo: int.tryParse(params['yearTo'] ?? ''),
      sortField: sort.first.isEmpty ? 'name' : sort.first,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == 'true',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PartQuery &&
      search == other.search &&
      categoryId == other.categoryId &&
      brandId == other.brandId &&
      carModelId == other.carModelId &&
      yearFrom == other.yearFrom &&
      yearTo == other.yearTo &&
      sortField == other.sortField &&
      sortAscending == other.sortAscending &&
      page == other.page &&
      size == other.size &&
      includeDeleted == other.includeDeleted;

  @override
  int get hashCode => Object.hash(
        search,
        categoryId,
        brandId,
        carModelId,
        yearFrom,
        yearTo,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );

  static const _unset = Object();
}
