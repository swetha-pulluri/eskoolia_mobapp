import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/fees_feed_item.dart';
import '../../domain/models/fees_payment.dart';
import '../../domain/models/fees_student_ref.dart';
import '../../domain/repositories/fees_repository.dart';
import '../utils/fees_format.dart';
import 'fees_home_state.dart';

class _SimPerson {
  final String initials;
  final String name;
  final Color bg;
  const _SimPerson(this.initials, this.name, this.bg);
}

/// Mirrors FeesPaymentsPanel.tsx's `SIM_POOL` — also reused (by index) to
/// colour the avatar of *real* fetched payments, exactly like the web
/// component's `SIM_POOL[p.id % SIM_POOL.length].bg`.
const _simPool = [
  _SimPerson('RN', 'Riaan Nair', Color(0xFF3B82F6)),
  _SimPerson('SN', 'Sia Nair', Color(0xFF7C3AED)),
  _SimPerson('KN', 'Kiara Nair', Color(0xFF0E7490)),
  _SimPerson('AN', 'Atharv Nair', Color(0xFF9333EA)),
  _SimPerson('RS', 'Rohan Sharma', Color(0xFF6D28D9)),
  _SimPerson('PS', 'Priya Singh', Color(0xFF0F766E)),
  _SimPerson('AK', 'Arjun Kumar', Color(0xFFD97706)),
  _SimPerson('VR', 'Vihaan Reddy', Color(0xFF16A34A)),
];
const _simAmounts = [5500, 7200, 8800, 9100, 10200, 11500, 12300, 13700, 14200, 15800];
const _simMethods = ['Cash', 'Online', 'Wallet', 'Bank Transfer', 'Cheque'];

/// Drives the Fees Home screen — matches FeesPaymentsPanel.tsx's state and
/// effects: loads the assignments summary + (broken) home dashboard on
/// mount, fetches the payments feed (resolving payer names against the
/// student list), and supports the "Simulate Incoming Payment" button and
/// the "Auto-refresh" toggle (5s poll of the payments feed).
class FeesHomeNotifier extends StateNotifier<FeesHomeState> {
  final FeesRepository _repository;
  final Random _random = Random();

  Map<int, FeesStudentRef> _students = {};
  Timer? _autoRefreshTimer;
  Timer? _toastTimer;
  int _simCounter = 100;
  bool _disposed = false;

  FeesHomeNotifier(this._repository) : super(const FeesHomeState()) {
    _load();
  }

  /// Mirrors FeesPaymentsPanel.tsx's three independent mount-time fetches —
  /// each handles its own failure (`.catch(console.error)`) rather than one
  /// failing all three, then the payments feed loads once students resolve.
  Future<void> _load() async {
    state = state.copyWith(loading: true);

    unawaited(_repository.fetchAssignmentsSummary().then((summary) {
      if (_disposed) return;
      state = state.copyWith(summary: summary);
    }).catchError((_) {}));

    unawaited(_repository.fetchHomeDashboard().then((homeData) {
      if (_disposed) return;
      state = state.copyWith(homeData: homeData);
    }).catchError((_) {}));

    try {
      final students = await _repository.fetchStudents();
      if (_disposed) return;
      _students = {for (final s in students) s.id: s};
    } catch (_) {
      // Keep name resolution best-effort — feed still renders with
      // "Student #<id>" fallbacks, matching the web component.
    }
    if (_disposed) return;
    state = state.copyWith(loading: false);
    await _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    try {
      final payments = await _repository.fetchPayments();
      if (_disposed) return;
      state = state.copyWith(feed: payments.map(_toFeedItem).toList());
    } catch (_) {
      // Keep whatever feed is already shown — matches the web component,
      // which never surfaces this failure to the user either.
    }
  }

  FeesFeedItem _toFeedItem(FeesPayment p) {
    final student = _students[p.student];
    final firstName = student?.firstName ?? '';
    final lastName = student?.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    final initials = firstName.isNotEmpty
        ? (firstName.substring(0, 1) + (lastName.isNotEmpty ? lastName.substring(0, 1) : ''))
        : '?';
    return FeesFeedItem(
      id: p.id.toString(),
      initials: initials,
      name: fullName.isNotEmpty ? fullName : 'Student #${p.student}',
      amount: feesFormatAmountFromString(p.amountPaid),
      method: p.method,
      time: feesFormatTime(p.paidAt),
      status: 'Posted',
      bg: _simPool[p.id % _simPool.length].bg,
      isNew: false,
    );
  }

  void toggleAutoRefresh() {
    final next = !state.autoRefresh;
    state = state.copyWith(autoRefresh: next);
    _autoRefreshTimer?.cancel();
    if (next) {
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchFeed());
    }
  }

  void simulatePayment() {
    final person = _simPool[_random.nextInt(_simPool.length)];
    final amount = _simAmounts[_random.nextInt(_simAmounts.length)];
    final method = _simMethods[_random.nextInt(_simMethods.length)];
    final status = _random.nextDouble() > 0.3 ? 'Verified' : 'Posted';
    final id = 'sim-${++_simCounter}';

    final item = FeesFeedItem(
      id: id,
      initials: person.initials,
      name: person.name,
      amount: feesFormatAmount(amount),
      method: method,
      time: feesNowTime(),
      status: status,
      bg: person.bg,
      isNew: true,
    );

    final updatedFeed = [item, ...state.feed.take(19)];
    state = state.copyWith(feed: updatedFeed);
    _showToast('Payment received: Rs. ${feesFormatAmount(amount)} from ${person.name} via $method.');

    Future.delayed(const Duration(milliseconds: 800), () {
      if (_disposed) return;
      state = state.copyWith(
        feed: state.feed.map((f) => f.id == id ? f.copyWith(isNew: false) : f).toList(),
      );
    });
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    state = state.copyWith(toast: message);
    _toastTimer = Timer(const Duration(milliseconds: 3500), () {
      if (_disposed) return;
      state = state.copyWith(clearToast: true);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _autoRefreshTimer?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }
}
