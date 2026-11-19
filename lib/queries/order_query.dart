class OrderQuery {
  final String search;
  final int? customerId;
  final String? status;
  final int? minTotal;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const OrderQuery({
    this.search = '',
    this.customerId,
    this.status,
    this.minTotal,
    this.sortField = 'id',
    this.sortAscending = false,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  OrderQuery copyWith({
    String? search,
    Object? customerId = _unset,
    Object? status = _unset,
    Object? minTotal = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return OrderQuery(
      search: search ?? this.search,
      customerId: customerId == _unset ? this.customerId : customerId as int?,
      status: status == _unset ? this.status : status as String?,
      minTotal: minTotal == _unset ? this.minTotal : minTotal as int?,
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
    if (status != null && status!.isNotEmpty) params['status'] = status!;
    if (minTotal != null) params['minTotal'] = '$minTotal';
    if (sortField != 'id' || sortAscending) {
      params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['includeDeleted'] = 'true';
    return params;
  }

  factory OrderQuery.fromParams(Map<String, String> params) {
    final sort = (params['sort'] ?? 'id,desc').split(',');
    final status = params['status'];
    return OrderQuery(
      search: params['search'] ?? '',
      customerId: int.tryParse(params['customerId'] ?? ''),
      status: (status == null || status.isEmpty) ? null : status,
      minTotal: int.tryParse(params['minTotal'] ?? ''),
      sortField: sort.first.isEmpty ? 'id' : sort.first,
      sortAscending: sort.length >= 2 && sort[1] == 'asc',
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == 'true',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OrderQuery &&
      search == other.search &&
      customerId == other.customerId &&
      status == other.status &&
      minTotal == other.minTotal &&
      sortField == other.sortField &&
      sortAscending == other.sortAscending &&
      page == other.page &&
      size == other.size &&
      includeDeleted == other.includeDeleted;

  @override
  int get hashCode => Object.hash(
        search,
        customerId,
        status,
        minTotal,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );

  static const _unset = Object();
}
