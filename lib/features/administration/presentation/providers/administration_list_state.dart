import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/paginated_result.dart';

/// Mirrors the web's `getErrorMessage(err, fallback)` — a short, clean
/// message, never Dio's full technical exception dump. Shared so screens
/// that call the repository directly (bulk actions) can surface the same
/// clean message the generic list notifier does.
String adminErrorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) return 'You are not authorized to do this.';
    if (status != null) return 'Request failed (HTTP $status).';
    return 'Unable to connect to the server.';
  }
  return 'Something went wrong. Please try again.';
}

/// Generic list state for an Administration CRUD screen (Visitor Book,
/// Complaints, Phone Calls, Admin Setup, ...): server-side pagination +
/// client-side quick-search over the currently loaded page, matching the
/// web panels' own behavior (none of them send `search` to the API).
class AdminListState<T> {
  final List<T> items;
  final bool isLoading;
  final String? error;
  final int page;
  final int pageSize;
  final int totalCount;
  final String search;
  final int? savingId;
  final int? deletingId;

  const AdminListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
    this.search = '',
    this.savingId,
    this.deletingId,
  });

  int get totalPages => totalCount == 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);

  AdminListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? page,
    int? pageSize,
    int? totalCount,
    String? search,
    int? savingId,
    bool clearSavingId = false,
    int? deletingId,
    bool clearDeletingId = false,
  }) {
    return AdminListState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      search: search ?? this.search,
      savingId: clearSavingId ? null : (savingId ?? this.savingId),
      deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
    );
  }
}

/// Generic notifier driving a paginated Administration list with
/// create/update/delete, reused across Visitor Book, Complaints, Phone
/// Calls and Admin Setup so the CRUD wiring isn't duplicated per screen.
class AdminListNotifier<T> extends StateNotifier<AdminListState<T>> {
  final Future<PaginatedResult<T>> Function({required int page, required int pageSize}) fetchPage;
  final Future<T> Function(T item) createItem;
  final Future<T> Function(int id, T item) updateItem;
  final Future<void> Function(int id) deleteItem;
  final int Function(T item) idOf;

  AdminListNotifier({
    required this.fetchPage,
    required this.createItem,
    required this.updateItem,
    required this.deleteItem,
    required this.idOf,
    int pageSize = 10,
  }) : super(AdminListState<T>(pageSize: pageSize)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await fetchPage(page: state.page, pageSize: state.pageSize);
      state = state.copyWith(items: result.results, totalCount: result.count, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
  }

  Future<void> setPage(int page) async {
    if (page < 1 || page > state.totalPages || page == state.page) return;
    state = state.copyWith(page: page);
    await load();
  }

  Future<void> setPageSize(int pageSize) async {
    state = state.copyWith(pageSize: pageSize, page: 1);
    await load();
  }

  /// Client-side quick-search over the currently loaded page — matches the
  /// web panels, which filter in-memory rather than querying the server.
  /// Always returns a fresh list (safe to sort) — never the state's own list.
  List<T> filtered(bool Function(T item, String query) matches) {
    if (state.search.trim().isEmpty) return List.of(state.items);
    final q = state.search.trim().toLowerCase();
    return state.items.where((item) => matches(item, q)).toList();
  }

  Future<bool> add(T item) async {
    state = state.copyWith(savingId: -1);
    try {
      await createItem(item);
      state = state.copyWith(clearSavingId: true, page: 1);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(clearSavingId: true, error: _errorMessage(e));
      return false;
    }
  }

  Future<bool> edit(int id, T item) async {
    state = state.copyWith(savingId: id);
    try {
      await updateItem(id, item);
      state = state.copyWith(clearSavingId: true);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(clearSavingId: true, error: _errorMessage(e));
      return false;
    }
  }

  Future<bool> remove(int id) async {
    state = state.copyWith(deletingId: id);
    try {
      await deleteItem(id);
      // Deleting the last remaining item on a page beyond page 1 shrinks
      // the real page count out from under the still-held page number —
      // reloading with that same `page` then asks the server for a page
      // that no longer exists, which DRF's pagination correctly rejects
      // with a 404 ("Invalid page."). Step back a page first so the
      // reload always targets a page that still exists.
      final page = (state.page > 1 && state.items.length <= 1) ? state.page - 1 : state.page;
      state = state.copyWith(clearDeletingId: true, page: page);
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(clearDeletingId: true, error: _errorMessage(e));
      return false;
    }
  }

  String _errorMessage(Object e) => adminErrorMessage(e);
}
