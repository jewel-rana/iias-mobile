import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../mock/mock_data.dart';
import '../models/models.dart';
import 'api_app_repository.dart';
import 'payment_allocator.dart';

abstract class AppRepository {
  Future<AppUser?> login(String phone, String password);
  Future<void> logout();
  AppUser? get currentUser;
  Future<DashboardStats> getDashboard();
  Future<List<Member>> getMembers({String query = '', MemberPaymentStatus? status});
  Future<Member?> getMember(String id);
  Future<Member> createMember({
    required String name,
    required String phone,
    required int monthlyAmount,
    String? collectorName,
  });
  Future<List<MonthlyDue>> getMemberDues(String memberId);
  Future<PaymentRecord> createPayment({
    required String memberId,
    required int amount,
    required PaymentMethod method,
    required List<PaymentAllocation> allocations,
  });
  Future<List<FundraisingEvent>> getEvents({bool activeOnly = false});
  Future<EventDonation> createEventDonation({
    required String eventId,
    required DonorType donorType,
    required String donorName,
    required String donorPhone,
    required int amount,
    required PaymentMethod method,
    String? referredByMemberId,
  });
  Future<ReportSummary> getReport();
  Future<List<PaymentRecord>> getRecentPayments();
}

class MockAppRepository implements AppRepository {
  AppUser? _user;
  final _uuid = const Uuid();
  final _payments = [...MockData.payments];
  final _donations = [...MockData.eventDonations];
  late final _events = [...MockData.events];
  late final _members = [...MockData.members];

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser?> login(String phone, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.endsWith('2222') || password == 'member') {
      _user = MockData.memberUser;
    } else {
      _user = MockData.admin;
    }
    return _user;
  }

  @override
  Future<void> logout() async {
    _user = null;
  }

  @override
  Future<DashboardStats> getDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockData.dashboard;
  }

  @override
  Future<List<Member>> getMembers({
    String query = '',
    MemberPaymentStatus? status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _members.where((m) {
      final q = query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.memberCode.toLowerCase().contains(q) ||
          m.phone.contains(q);
      final matchesStatus = status == null || m.status == status;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  Future<Member?> getMember(String id) async {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Member> createMember({
    required String name,
    required String phone,
    required int monthlyAmount,
    String? collectorName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final next = _members.length + 1024;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final member = Member(
      id: _uuid.v4(),
      memberCode: 'M-${next.toString().padLeft(6, '0')}',
      name: name.trim(),
      phone: phone.trim(),
      monthlyAmount: monthlyAmount,
      collectorName: (collectorName ?? '').trim().isEmpty
          ? 'Unassigned'
          : collectorName!.trim(),
      status: MemberPaymentStatus.unpaid,
      totalPaid: 0,
      outstanding: monthlyAmount,
      advance: 0,
      paidMonths: 0,
      dueMonths: 1,
      advanceMonths: 0,
      referralCode: '${initials.isEmpty ? 'MB' : initials}-$next',
    );
    _members.insert(0, member);
    return member;
  }

  @override
  Future<List<MonthlyDue>> getMemberDues(String memberId) async {
    return MockData.duesFor(memberId);
  }

  @override
  Future<PaymentRecord> createPayment({
    required String memberId,
    required int amount,
    required PaymentMethod method,
    required List<PaymentAllocation> allocations,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final member = _members.firstWhere((m) => m.id == memberId);
    final record = PaymentRecord(
      id: _uuid.v4(),
      receiptNumber: 'P-${10026 + _payments.length}',
      memberId: memberId,
      memberName: member.name,
      amount: amount,
      method: method,
      date: DateTime.now(),
      allocations: allocations,
      collectorName: MockData.admin.name,
    );
    _payments.insert(0, record);
    return record;
  }

  @override
  Future<List<FundraisingEvent>> getEvents({bool activeOnly = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (activeOnly) {
      return _events.where((e) => e.status == EventStatus.active).toList();
    }
    return _events;
  }

  @override
  Future<EventDonation> createEventDonation({
    required String eventId,
    required DonorType donorType,
    required String donorName,
    required String donorPhone,
    required int amount,
    required PaymentMethod method,
    String? referredByMemberId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final event = _events.firstWhere((e) => e.id == eventId);
    String? referredName;
    if (referredByMemberId != null) {
      referredName = _members.firstWhere((m) => m.id == referredByMemberId).name;
    }
    final donation = EventDonation(
      id: _uuid.v4(),
      receiptNumber: 'D-${20012 + _donations.length}',
      eventId: eventId,
      eventTitle: event.title,
      donorType: donorType,
      donorName: donorName,
      donorPhone: donorPhone,
      amount: amount,
      method: method,
      date: DateTime.now(),
      referredByName: referredName,
    );
    _donations.insert(0, donation);
    final idx = _events.indexWhere((e) => e.id == eventId);
    _events[idx] = FundraisingEvent(
      id: event.id,
      title: event.title,
      slug: event.slug,
      goalAmount: event.goalAmount,
      raisedAmount: event.raisedAmount + amount,
      donorCount: event.donorCount + 1,
      status: event.status,
      startsAt: event.startsAt,
      endsAt: event.endsAt,
      description: event.description,
    );
    return donation;
  }

  @override
  Future<ReportSummary> getReport() async => MockData.report;

  @override
  Future<List<PaymentRecord>> getRecentPayments() async => _payments;
}

final repositoryProvider = Provider<AppRepository>((ref) {
  if (AppConstants.useMockData) {
    return MockAppRepository();
  }
  return ApiAppRepository();
});

final authStateProvider = StateNotifierProvider<AuthController, AppUser?>((ref) {
  return AuthController(ref.watch(repositoryProvider));
});

class AuthController extends StateNotifier<AppUser?> {
  AuthController(this._repo) : super(_repo.currentUser);

  final AppRepository _repo;

  Future<bool> login(String phone, String password) async {
    final user = await _repo.login(phone, password);
    state = user;
    return user != null;
  }

  Future<void> logout() async {
    await _repo.logout();
    state = null;
  }
}

List<PaymentAllocation> allocatePayment({
  required List<MonthlyDue> dues,
  required int amount,
  required int monthlyAmount,
}) =>
    suggestAllocations(dues: dues, paymentAmount: amount, monthlyAmount: monthlyAmount);
