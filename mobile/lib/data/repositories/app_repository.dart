import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/push/push_service.dart';
import '../mock/mock_data.dart';
import '../models/models.dart';
import 'api_app_repository.dart';
import 'payment_allocator.dart';

class PasswordResetChallenge {
  const PasswordResetChallenge({this.debugCode, this.emailHint});

  final String? debugCode;
  final String? emailHint;
}

abstract class AppRepository {
  Future<AppUser?> login(String phone, String password);
  /// Emails a reset code. [debugCode] is only present when the API mailer is log/array.
  Future<PasswordResetChallenge> requestPasswordReset(String phone);
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String password,
    required String passwordConfirmation,
  });
  Future<void> logout();
  Future<AppUser?> restoreSession();
  AppUser? get currentUser;
  Future<void> registerDeviceToken({
    required String token,
    String? platform,
    String? deviceId,
  });
  Future<void> unregisterDeviceToken(String token);
  Future<DashboardStats> getDashboard();
  Future<List<Member>> getMembers({
    String query = '',
    MemberPaymentStatus? status,
    DateTime? billingMonth,
  });
  Future<Member?> getMember(String id);
  Future<Member> createMember({
    required String name,
    required String phone,
    required int monthlyAmount,
    String? collectorName,
    String? email,
    DateTime? joinedAt,
    String? roleId,
  });
  Future<Member> updateMember({
    required String id,
    String? email,
    String? roleId,
    int? monthlyAmount,
  });
  Future<List<MonthlyDue>> getMemberDues(String memberId);
  Future<PaymentRecord> createPayment({
    required String memberId,
    required int amount,
    required PaymentMethod method,
    required List<PaymentAllocation> allocations,
    String? collectorName,
    String? walletAccount,
    String? transactionId,
  });
  Future<List<PaymentRecord>> getPayments({
    PaymentStatus? status,
    String? memberId,
    DateTime? billingMonth,
  });
  Future<PaymentRecord> getPayment(String id);
  Future<PaymentRecord> approvePayment(String id);
  Future<PaymentRecord> rejectPayment(String id, {String? reason});
  Future<void> deletePayment(String id);
  Future<List<FundraisingEvent>> getEvents({bool activeOnly = false});  Future<FundraisingEvent> createFundraisingEvent({
    required String title,
    required int goalAmount,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
  });
  Future<EventDonation> createEventDonation({
    required String eventId,
    required DonorType donorType,
    required String donorName,
    required String donorPhone,
    required int amount,
    required PaymentMethod method,
    String? referredByMemberId,
    String? memberId,
  });
  Future<List<EventDonation>> getEventDonations({String? memberId});
  Future<ReportSummary> getReport({DateTime? month});
  Future<List<PaymentRecord>> getRecentPayments();
  Future<List<Expense>> getExpenses({
    ExpenseRecurrence? recurrence,
    ExpenseHeadKind? kind,
  });
  Future<Expense> createExpense({
    required String title,
    required String expenseHeadId,
    required ExpenseRecurrence recurrence,
    required int amount,
    required DateTime expenseDate,
    PaymentMethod? paymentMethod,
    String? notes,
    DateTime? periodMonth,
  });
  Future<List<SalaryHeadDues>> getSalaryDues({String? expenseHeadId});
  Future<List<ExpenseHead>> getExpenseHeads({
    bool activeOnly = true,
    ExpenseHeadKind? kind,
  });
  Future<ExpenseHead> createExpenseHead({
    required String name,
    required ExpenseHeadKind kind,
    required ExpenseRecurrence defaultRecurrence,
    String? code,
    bool isActive = true,
  });
  Future<ExpenseHead> updateExpenseHead(ExpenseHead head);
  Future<void> deleteExpenseHead(String id);
  Future<List<AccessRole>> getAccessRoles({bool activeOnly = true});
  Future<AccessRole> createAccessRole({
    required String name,
    List<String> permissions = const [],
    bool isActive = true,
  });
  Future<AccessRole> updateAccessRole(AccessRole role);
  Future<void> deleteAccessRole(String id);
  Future<List<JoinRequest>> getJoinRequests({JoinRequestStatus? status});
  Future<JoinRequest> submitJoinRequest({
    required String fullName,
    required String phone,
    String? email,
    String? referralCode,
    int? preferredMonthlyAmount,
  });
  Future<JoinRequest> approveJoinRequest(String id);
  Future<JoinRequest> rejectJoinRequest(String id, {String? reason});
  Future<OrganizationSettings> getOrganizationSettings();
  Future<OrganizationSettings> updateOrganizationSettings(
    OrganizationSettings settings,
  );
  Future<List<CommitteeRole>> getCommitteeRoles({bool activeOnly = true});
  Future<CommitteeRole> createCommitteeRole({
    required String name,
    String? code,
    bool isActive = true,
  });
  Future<CommitteeRole> updateCommitteeRole(CommitteeRole role);
  Future<void> deleteCommitteeRole(String id);
  Future<List<CommitteeMember>> getCommitteeMembers({bool activeOnly = true});
  Future<CommitteeMember> createCommitteeMember({
    required String name,
    required String roleId,
    String? phone,
    String? email,
    String? memberId,
    String? notes,
  });
  Future<CommitteeMember> updateCommitteeMember(CommitteeMember member);
  Future<void> deleteCommitteeMember(String id);
  Future<List<Meeting>> getMeetings({MeetingStatus? status});
  Future<Meeting> getMeeting(String id);
  Future<Meeting> createMeeting({
    required String purpose,
    required DateTime startsAt,
    String? title,
    String? location,
  });
  Future<Meeting> updateMeeting({
    required String id,
    String? title,
    String? purpose,
    DateTime? startsAt,
    String? location,
    MeetingStatus? status,
    String? summary,
    List<String>? presentMemberIds,
  });
}

class MockAppRepository implements AppRepository {
  AppUser? _user;
  final _uuid = const Uuid();
  final _payments = [...MockData.payments];
  final _donations = [...MockData.eventDonations];
  final _expenses = [...MockData.expenses];
  final _expenseHeads = [...MockData.expenseHeads];
  final _accessRoles = <AccessRole>[
    const AccessRole(
      id: 'r-admin',
      name: 'Admin',
      code: 'admin',
      isSystem: true,
      isActive: true,
      sortOrder: 1,
      permissions: ['*'],
    ),
    const AccessRole(
      id: 'r-collector',
      name: 'Collector',
      code: 'collector',
      isSystem: true,
      isActive: true,
      sortOrder: 2,
    ),
    const AccessRole(
      id: 'r-member',
      name: 'Member',
      code: 'member',
      isSystem: true,
      isActive: true,
      sortOrder: 3,
    ),
  ];
  final _joinRequests = [...MockData.joinRequests];
  final _committeeRoles = [...MockData.committeeRoles];
  final _committeeMembers = [...MockData.committeeMembers];
  late OrganizationSettings _settings = MockData.organizationSettings;
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
  Future<PasswordResetChallenge> requestPasswordReset(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const PasswordResetChallenge(
      debugCode: '111111',
      emailHint: 't***@example.com',
    );
  }

  @override
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> logout() async {
    _user = null;
  }

  @override
  Future<AppUser?> restoreSession() async => _user;

  @override
  Future<void> registerDeviceToken({
    required String token,
    String? platform,
    String? deviceId,
  }) async {}

  @override
  Future<void> unregisterDeviceToken(String token) async {}

  @override
  Future<DashboardStats> getDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final totalExpenses = _expenses.fold<int>(0, (sum, e) => sum + e.amount);
    final funds = MockData.totalInflowBaseline - totalExpenses;
    final d = MockData.dashboard;
    return DashboardStats(
      expected: d.expected,
      collected: d.collected,
      totalMembers: d.totalMembers,
      paid: d.paid,
      partial: d.partial,
      unpaid: d.unpaid,
      totalInflow: MockData.totalInflowBaseline,
      totalExpenses: totalExpenses,
      fundsAvailable: funds < 0 ? 0 : funds,
      pendingPayments: _payments.where((p) => p.isPending).length,
    );
  }

  @override
  Future<List<Member>> getMembers({
    String query = '',
    MemberPaymentStatus? status,
    DateTime? billingMonth,
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
    String? email,
    DateTime? joinedAt,
    String? roleId,
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
      email: email?.trim().isEmpty == true ? null : email?.trim(),
      joinedAt: joinedAt ?? DateTime.now(),
      roleId: roleId,
      roleName: _accessRoles
          .where((r) => r.id == roleId)
          .map((r) => r.name)
          .cast<String?>()
          .followedBy(const ['Member'])
          .first,
    );
    _members.insert(0, member);
    return member;
  }

  @override
  Future<Member> updateMember({
    required String id,
    String? email,
    String? roleId,
    int? monthlyAmount,
  }) async {
    final idx = _members.indexWhere((m) => m.id == id);
    if (idx < 0) {
      throw Exception('Member not found');
    }
    final current = _members[idx];
    final updated = Member(
      id: current.id,
      memberCode: current.memberCode,
      name: current.name,
      phone: current.phone,
      monthlyAmount: monthlyAmount ?? current.monthlyAmount,
      collectorName: current.collectorName,
      status: current.status,
      totalPaid: current.totalPaid,
      outstanding: current.outstanding,
      advance: current.advance,
      paidMonths: current.paidMonths,
      dueMonths: current.dueMonths,
      advanceMonths: current.advanceMonths,
      referralCode: current.referralCode,
      email: email ?? current.email,
      joinedAt: current.joinedAt,
      roleId: roleId ?? current.roleId,
      roleName: roleId == null
          ? current.roleName
          : _accessRoles
              .where((r) => r.id == roleId)
              .map((r) => r.name)
              .cast<String?>()
              .followedBy([current.roleName])
              .first,
    );
    _members[idx] = updated;
    return updated;
  }

  @override
  Future<List<MonthlyDue>> getMemberDues(String memberId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    Member? member;
    try {
      member = _members.firstWhere((m) => m.id == memberId);
    } catch (_) {
      member = null;
    }
    return MockData.duesFor(
      memberId,
      member: member,
      monthlyAmount: member?.monthlyAmount ?? 500,
      status: member?.status ?? MemberPaymentStatus.unpaid,
      advanceMonths: member?.advanceMonths ?? 0,
    );
  }

  @override
  Future<PaymentRecord> createPayment({
    required String memberId,
    required int amount,
    required PaymentMethod method,
    required List<PaymentAllocation> allocations,
    String? collectorName,
    String? walletAccount,
    String? transactionId,
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
      status: currentUser?.role == UserRole.member
          ? PaymentStatus.pending
          : PaymentStatus.confirmed,
      collectorName: collectorName ??
          (currentUser?.role == UserRole.member ? 'Self' : MockData.admin.name),
      walletAccount: walletAccount,
      transactionId: transactionId,
    );
    _payments.insert(0, record);
    if (record.isConfirmed) {
      // Mock path still applies dues via existing flow elsewhere if any.
    }
    return record;
  }

  @override
  Future<List<PaymentRecord>> getPayments({
    PaymentStatus? status,
    String? memberId,
    DateTime? billingMonth,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _payments.where((p) {
      final matchesStatus = status == null || p.status == status;
      final matchesMember = memberId == null || p.memberId == memberId;
      final matchesMonth = billingMonth == null ||
          p.allocations.any((a) =>
              a.billingMonth.year == billingMonth.year &&
              a.billingMonth.month == billingMonth.month);
      return matchesStatus && matchesMember && matchesMonth;
    }).toList();
  }

  @override
  Future<PaymentRecord> getPayment(String id) async {
    return _payments.firstWhere((p) => p.id == id);
  }

  @override
  Future<PaymentRecord> approvePayment(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final idx = _payments.indexWhere((p) => p.id == id);
    if (idx < 0) throw Exception('Payment not found');
    final old = _payments[idx];
    final updated = PaymentRecord(
      id: old.id,
      receiptNumber: old.receiptNumber,
      memberId: old.memberId,
      memberName: old.memberName,
      amount: old.amount,
      method: old.method,
      date: old.date,
      allocations: old.allocations,
      status: PaymentStatus.confirmed,
      collectorName: old.collectorName,
      walletAccount: old.walletAccount,
      transactionId: old.transactionId,
    );
    _payments[idx] = updated;
    return updated;
  }

  @override
  Future<void> deletePayment(String id) async {
    _payments.removeWhere((p) => p.id == id);
  }

  @override
  Future<PaymentRecord> rejectPayment(String id, {String? reason}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final idx = _payments.indexWhere((p) => p.id == id);
    if (idx < 0) throw Exception('Payment not found');
    final old = _payments[idx];
    final updated = PaymentRecord(
      id: old.id,
      receiptNumber: old.receiptNumber,
      memberId: old.memberId,
      memberName: old.memberName,
      amount: old.amount,
      method: old.method,
      date: old.date,
      allocations: old.allocations,
      status: PaymentStatus.rejected,
      collectorName: old.collectorName,
      walletAccount: old.walletAccount,
      transactionId: old.transactionId,
      rejectionReason: reason,
    );
    _payments[idx] = updated;
    return updated;
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
  Future<FundraisingEvent> createFundraisingEvent({
    required String title,
    required int goalAmount,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final slugBase = title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final event = FundraisingEvent(
      id: _uuid.v4(),
      title: title.trim(),
      slug: '$slugBase-${_events.length + 1}',
      goalAmount: goalAmount,
      raisedAmount: 0,
      donorCount: 0,
      status: EventStatus.active,
      startsAt: startsAt ?? DateTime.now(),
      endsAt: endsAt,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
    );
    _events.insert(0, event);
    return event;
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
    String? memberId,
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
      memberId: donorType == DonorType.member ? memberId : null,
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
  Future<List<EventDonation>> getEventDonations({String? memberId}) async {
    return _donations.where((d) => memberId == null || d.memberId == memberId).toList();
  }

  @override
  Future<ReportSummary> getReport({DateTime? month}) async {
    final m = month ?? DateTime.now();
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return ReportSummary(
      monthLabel: '${names[m.month - 1]} ${m.year}',
      expected: MockData.report.expected,
      collected: MockData.report.collected,
      outstanding: MockData.report.outstanding,
      paidMembers: MockData.report.paidMembers,
      partialMembers: MockData.report.partialMembers,
      unpaidMembers: MockData.report.unpaidMembers,
      advancePaidMembers: MockData.report.advancePaidMembers,
    );
  }

  @override
  Future<List<PaymentRecord>> getRecentPayments() async => _payments;

  @override
  Future<List<Expense>> getExpenses({
    ExpenseRecurrence? recurrence,
    ExpenseHeadKind? kind,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final list = [..._expenses]
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return list.where((e) {
      final matchesRecurrence = recurrence == null || e.recurrence == recurrence;
      final matchesKind = kind == null || e.headKind == kind;
      return matchesRecurrence && matchesKind;
    }).toList();
  }

  @override
  Future<Expense> createExpense({
    required String title,
    required String expenseHeadId,
    required ExpenseRecurrence recurrence,
    required int amount,
    required DateTime expenseDate,
    PaymentMethod? paymentMethod,
    String? notes,
    DateTime? periodMonth,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final head = _expenseHeads.firstWhere((h) => h.id == expenseHeadId);
    final expense = Expense(
      id: _uuid.v4(),
      title: title.trim(),
      expenseHeadId: head.id,
      headName: head.name,
      headKind: head.kind,
      recurrence: recurrence,
      amount: amount,
      expenseDate: expenseDate,
      paymentMethod: paymentMethod,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      periodMonth: periodMonth,
    );
    _expenses.insert(0, expense);
    return expense;
  }

  @override
  Future<List<SalaryHeadDues>> getSalaryDues({String? expenseHeadId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final now = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final heads = _expenseHeads.where((h) {
      if (h.kind != ExpenseHeadKind.salary || !h.isActive) return false;
      if (expenseHeadId != null && h.id != expenseHeadId) return false;
      return true;
    });
    return heads.map((head) {
      final paid = {
        for (final e in _expenses.where((e) => e.expenseHeadId == head.id && e.periodMonth != null))
          DateTime(e.periodMonth!.year, e.periodMonth!.month, 1): e,
      };
      var start = DateTime(now.year, now.month - 11, 1);
      final periods = <SalaryPeriod>[];
      var cursor = start;
      while (!cursor.isAfter(now)) {
        final match = paid[DateTime(cursor.year, cursor.month, 1)];
        periods.add(SalaryPeriod(
          month: DateTime(cursor.year, cursor.month, 1),
          isPaid: match != null,
          expenseId: match?.id,
          amount: match?.amount,
        ));
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }
      return SalaryHeadDues(
        expenseHeadId: head.id,
        headName: head.name,
        dueCount: periods.where((p) => !p.isPaid).length,
        periods: periods,
      );
    }).toList();
  }

  @override
  Future<List<ExpenseHead>> getExpenseHeads({
    bool activeOnly = true,
    ExpenseHeadKind? kind,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _expenseHeads.where((h) {
      if (activeOnly && !h.isActive) return false;
      if (kind != null && h.kind != kind) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<ExpenseHead> createExpenseHead({
    required String name,
    required ExpenseHeadKind kind,
    required ExpenseRecurrence defaultRecurrence,
    String? code,
    bool isActive = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final head = ExpenseHead(
      id: _uuid.v4(),
      name: name.trim(),
      code: (code ?? name).trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
      kind: kind,
      defaultRecurrence: defaultRecurrence,
      isActive: isActive,
      sortOrder: _expenseHeads.length + 1,
    );
    _expenseHeads.add(head);
    return head;
  }

  @override
  Future<ExpenseHead> updateExpenseHead(ExpenseHead head) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final idx = _expenseHeads.indexWhere((h) => h.id == head.id);
    if (idx < 0) throw StateError('Expense head not found');
    _expenseHeads[idx] = head;
    return head;
  }

  @override
  Future<void> deleteExpenseHead(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final idx = _expenseHeads.indexWhere((h) => h.id == id);
    if (idx < 0) return;
    final inUse = _expenses.any((e) => e.expenseHeadId == id);
    if (inUse) {
      final h = _expenseHeads[idx];
      _expenseHeads[idx] = ExpenseHead(
        id: h.id,
        name: h.name,
        code: h.code,
        kind: h.kind,
        defaultRecurrence: h.defaultRecurrence,
        isActive: false,
        sortOrder: h.sortOrder,
      );
      return;
    }
    _expenseHeads.removeAt(idx);
  }

  @override
  Future<List<AccessRole>> getAccessRoles({bool activeOnly = true}) async {
    return _accessRoles.where((r) => !activeOnly || r.isActive).toList();
  }

  @override
  Future<AccessRole> createAccessRole({
    required String name,
    List<String> permissions = const [],
    bool isActive = true,
  }) async {
    final role = AccessRole(
      id: _uuid.v4(),
      name: name.trim(),
      code: name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
      isSystem: false,
      isActive: isActive,
      sortOrder: _accessRoles.length + 1,
      permissions: permissions,
    );
    _accessRoles.add(role);
    return role;
  }

  @override
  Future<AccessRole> updateAccessRole(AccessRole role) async {
    final idx = _accessRoles.indexWhere((r) => r.id == role.id);
    if (idx < 0) throw StateError('Role not found');
    _accessRoles[idx] = role;
    return role;
  }

  @override
  Future<void> deleteAccessRole(String id) async {
    _accessRoles.removeWhere((r) => r.id == id && !r.isSystem);
  }

  @override
  Future<List<JoinRequest>> getJoinRequests({JoinRequestStatus? status}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final list = [..._joinRequests]
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    if (status == null) return list;
    return list.where((j) => j.status == status).toList();
  }

  @override
  Future<JoinRequest> submitJoinRequest({
    required String fullName,
    required String phone,
    String? email,
    String? referralCode,
    int? preferredMonthlyAmount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final request = JoinRequest(
      id: _uuid.v4(),
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email?.trim().isEmpty == true ? null : email?.trim(),
      referralCode:
          referralCode?.trim().isEmpty == true ? null : referralCode?.trim(),
      preferredMonthlyAmount:
          preferredMonthlyAmount ?? _settings.defaultMonthlyAmount,
      status: JoinRequestStatus.submitted,
      submittedAt: DateTime.now(),
    );
    _joinRequests.insert(0, request);
    return request;
  }

  @override
  Future<JoinRequest> approveJoinRequest(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final idx = _joinRequests.indexWhere((j) => j.id == id);
    if (idx < 0) throw StateError('Join request not found');
    final current = _joinRequests[idx];
    if (current.status == JoinRequestStatus.approved) return current;

    await createMember(
      name: current.fullName,
      phone: current.phone,
      monthlyAmount:
          current.preferredMonthlyAmount ?? _settings.defaultMonthlyAmount,
    );

    final updated = JoinRequest(
      id: current.id,
      fullName: current.fullName,
      phone: current.phone,
      email: current.email,
      referralCode: current.referralCode,
      preferredMonthlyAmount: current.preferredMonthlyAmount,
      status: JoinRequestStatus.approved,
      submittedAt: current.submittedAt,
    );
    _joinRequests[idx] = updated;
    return updated;
  }

  @override
  Future<JoinRequest> rejectJoinRequest(String id, {String? reason}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final idx = _joinRequests.indexWhere((j) => j.id == id);
    if (idx < 0) throw StateError('Join request not found');
    final current = _joinRequests[idx];
    final updated = JoinRequest(
      id: current.id,
      fullName: current.fullName,
      phone: current.phone,
      email: current.email,
      referralCode: current.referralCode,
      preferredMonthlyAmount: current.preferredMonthlyAmount,
      status: JoinRequestStatus.rejected,
      submittedAt: current.submittedAt,
      rejectionReason: reason?.trim().isEmpty == true ? null : reason?.trim(),
    );
    _joinRequests[idx] = updated;
    return updated;
  }

  @override
  Future<OrganizationSettings> getOrganizationSettings() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _settings;
  }

  @override
  Future<OrganizationSettings> updateOrganizationSettings(
    OrganizationSettings settings,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _settings = settings;
    return _settings;
  }

  @override
  Future<List<CommitteeRole>> getCommitteeRoles({bool activeOnly = true}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _committeeRoles.where((r) => !activeOnly || r.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<CommitteeRole> createCommitteeRole({
    required String name,
    String? code,
    bool isActive = true,
  }) async {
    final role = CommitteeRole(
      id: _uuid.v4(),
      name: name.trim(),
      code: (code ?? name).trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
      isActive: isActive,
      sortOrder: _committeeRoles.length + 1,
    );
    _committeeRoles.add(role);
    return role;
  }

  @override
  Future<CommitteeRole> updateCommitteeRole(CommitteeRole role) async {
    final idx = _committeeRoles.indexWhere((r) => r.id == role.id);
    if (idx < 0) throw StateError('Role not found');
    _committeeRoles[idx] = role;
    return role;
  }

  @override
  Future<void> deleteCommitteeRole(String id) async {
    final inUse = _committeeMembers.any((m) => m.roleId == id);
    final idx = _committeeRoles.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    if (inUse) {
      final r = _committeeRoles[idx];
      _committeeRoles[idx] = CommitteeRole(
        id: r.id,
        name: r.name,
        code: r.code,
        isActive: false,
        sortOrder: r.sortOrder,
      );
      return;
    }
    _committeeRoles.removeAt(idx);
  }

  @override
  Future<List<CommitteeMember>> getCommitteeMembers({bool activeOnly = true}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _committeeMembers.where((m) => !activeOnly || m.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<CommitteeMember> createCommitteeMember({
    required String name,
    required String roleId,
    String? phone,
    String? email,
    String? memberId,
    String? notes,
  }) async {
    final role = _committeeRoles.firstWhere((r) => r.id == roleId);
    final member = CommitteeMember(
      id: _uuid.v4(),
      name: name.trim(),
      roleId: role.id,
      roleName: role.name,
      roleCode: role.code,
      phone: phone,
      email: email,
      memberId: memberId,
      notes: notes,
      sortOrder: _committeeMembers.length + 1,
    );
    _committeeMembers.add(member);
    return member;
  }

  @override
  Future<CommitteeMember> updateCommitteeMember(CommitteeMember member) async {
    final idx = _committeeMembers.indexWhere((m) => m.id == member.id);
    if (idx < 0) throw StateError('Committee member not found');
    _committeeMembers[idx] = member;
    return member;
  }

  @override
  Future<void> deleteCommitteeMember(String id) async {
    _committeeMembers.removeWhere((m) => m.id == id);
  }

  final _meetings = <Meeting>[];

  @override
  Future<List<Meeting>> getMeetings({MeetingStatus? status}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final list = [..._meetings]..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    if (status == null) return list;
    return list.where((m) => m.status == status).toList();
  }

  @override
  Future<Meeting> getMeeting(String id) async {
    return _meetings.firstWhere((m) => m.id == id);
  }

  @override
  Future<Meeting> createMeeting({
    required String purpose,
    required DateTime startsAt,
    String? title,
    String? location,
  }) async {
    final meeting = Meeting(
      id: _uuid.v4(),
      title: (title ?? '').trim().isEmpty ? 'Organization Meeting' : title!.trim(),
      purpose: purpose.trim(),
      startsAt: startsAt,
      location: location,
      status: MeetingStatus.scheduled,
      announcementEn: purpose,
      announcementBn: purpose,
    );
    _meetings.insert(0, meeting);
    return meeting;
  }

  @override
  Future<Meeting> updateMeeting({
    required String id,
    String? title,
    String? purpose,
    DateTime? startsAt,
    String? location,
    MeetingStatus? status,
    String? summary,
    List<String>? presentMemberIds,
  }) async {
    final idx = _meetings.indexWhere((m) => m.id == id);
    if (idx < 0) throw StateError('Meeting not found');
    final current = _meetings[idx];
    final members = presentMemberIds == null
        ? current.presentMembers
        : _members
            .where((m) => presentMemberIds.contains(m.id))
            .map((m) => MeetingAttendee(id: m.id, name: m.name, memberCode: m.memberCode))
            .toList();
    final updated = Meeting(
      id: current.id,
      title: title ?? current.title,
      purpose: purpose ?? current.purpose,
      startsAt: startsAt ?? current.startsAt,
      location: location ?? current.location,
      status: status ?? current.status,
      summary: summary ?? current.summary,
      announcementEn: current.announcementEn,
      announcementBn: current.announcementBn,
      presentMemberIds: presentMemberIds ?? current.presentMemberIds,
      presentMembers: members,
    );
    _meetings[idx] = updated;
    return updated;
  }
}

final repositoryProvider = Provider<AppRepository>((ref) {
  return ApiAppRepository();
});

final authStateProvider = StateNotifierProvider<AuthController, AppUser?>((ref) {
  return AuthController(ref.watch(repositoryProvider));
});

final authReadyProvider = FutureProvider<void>((ref) async {
  await ref.read(authStateProvider.notifier).restore();
});

class AuthController extends StateNotifier<AppUser?> {
  AuthController(this._repo) : super(_repo.currentUser);

  final AppRepository _repo;
  bool _restored = false;

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    final user = await _repo.restoreSession();
    state = user;
    if (user != null) {
      await _syncPushToken();
    }
  }

  Future<bool> login(String phone, String password) async {
    final user = await _repo.login(phone, password);
    if (user == null) return false;
    state = user;
    await _syncPushToken();
    return true;
  }

  Future<void> logout() async {
    PushService.instance.onTokenRefresh = null;
    final token = PushService.instance.token;
    if (token != null) {
      await _repo.unregisterDeviceToken(token);
    }
    await _repo.logout();
    state = null;
  }

  Future<void> _syncPushToken() async {
    final push = PushService.instance;
    push.onTokenRefresh = (token) {
      _repo.registerDeviceToken(token: token, platform: push.platform);
    };
    final token = push.token;
    if (token == null || token.isEmpty) return;
    try {
      await _repo.registerDeviceToken(token: token, platform: push.platform);
    } catch (e) {
      debugPrint('Device token register failed: $e');
    }
  }
}

List<PaymentAllocation> allocatePayment({
  required List<MonthlyDue> dues,
  required int amount,
  required int monthlyAmount,
}) =>
    suggestAllocations(dues: dues, paymentAmount: amount, monthlyAmount: monthlyAmount);
