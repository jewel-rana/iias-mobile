import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../models/models.dart';
import 'app_repository.dart';

String _prettyJson(Object? data) {
  if (data == null) return '(empty)';
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data.toString();
  }
}

void _logApi(String message) {
  debugPrint(message, wrapWidth: 2048);
}

class ApiAppRepository implements AppRepository {
  ApiAppRepository({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: {'Accept': 'application/json'},
              ),
            ),
        _storage = storage ?? const FlutterSecureStorage() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            _logApi('→ ${options.method} ${options.uri}');
            if (options.queryParameters.isNotEmpty) {
              _logApi('  query: ${_prettyJson(options.queryParameters)}');
            }
            if (options.data != null) {
              _logApi('  payload: ${_prettyJson(options.data)}');
            }
            handler.next(options);
          },
          onResponse: (response, handler) {
            _logApi(
              '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
            );
            _logApi('  response: ${_prettyJson(response.data)}');
            handler.next(response);
          },
          onError: (error, handler) {
            _logApi(
              '← ${error.response?.statusCode ?? 'ERR'} ${error.requestOptions.method} ${error.requestOptions.uri}',
            );
            if (error.requestOptions.data != null) {
              _logApi('  payload: ${_prettyJson(error.requestOptions.data)}');
            }
            _logApi('  response: ${_prettyJson(error.response?.data)}');
            handler.next(error);
          },
        ),
      );
    }
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final _uuid = const Uuid();
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  UserRole _role(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'collector':
        return UserRole.collector;
      default:
        return UserRole.member;
    }
  }

  MemberPaymentStatus _memberStatus(String? value) {
    switch (value) {
      case 'paid':
        return MemberPaymentStatus.paid;
      case 'partial':
        return MemberPaymentStatus.partial;
      default:
        return MemberPaymentStatus.unpaid;
    }
  }

  DueStatus _dueStatus(String? value) {
    switch (value) {
      case 'paid':
        return DueStatus.paid;
      case 'partial':
        return DueStatus.partial;
      default:
        return DueStatus.unpaid;
    }
  }

  PaymentMethod _methodFromApi(String? value) {
    switch (value) {
      case 'mobile_wallet':
        return PaymentMethod.mobileWallet;
      case 'hand_cash':
        return PaymentMethod.handCash;
      default:
        return PaymentMethod.cashToCollector;
    }
  }

  String _methodToApi(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mobileWallet:
        return 'mobile_wallet';
      case PaymentMethod.cashToCollector:
        return 'cash_to_collector';
      case PaymentMethod.handCash:
        return 'hand_cash';
    }
  }

  EventStatus _eventStatus(String? value) {
    switch (value) {
      case 'active':
        return EventStatus.active;
      case 'paused':
        return EventStatus.paused;
      case 'closed':
        return EventStatus.closed;
      case 'archived':
        return EventStatus.archived;
      default:
        return EventStatus.draft;
    }
  }

  Member _mapMember(Map<String, dynamic> json) => Member(
        id: json['id'].toString(),
        memberCode: json['member_code'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        monthlyAmount: json['monthly_amount'] as int,
        collectorName: (json['collector_name'] as String?) ?? '',
        status: _memberStatus(json['status'] as String?),
        totalPaid: json['total_paid'] as int,
        outstanding: json['outstanding'] as int,
        advance: json['advance'] as int,
        paidMonths: json['paid_months'] as int,
        dueMonths: json['due_months'] as int,
        advanceMonths: json['advance_months'] as int,
        referralCode: json['referral_code'] as String,
        email: json['email'] as String?,
        joinedAt: json['joined_at'] != null
            ? DateTime.tryParse(json['joined_at'] as String)
            : null,
      );

  FundraisingEvent _mapEvent(Map<String, dynamic> json) => FundraisingEvent(
        id: json['id'].toString(),
        title: json['title'] as String,
        slug: json['slug'] as String,
        goalAmount: json['goal_amount'] as int,
        raisedAmount: json['raised_amount'] as int,
        donorCount: json['donor_count'] as int,
        status: _eventStatus(json['status'] as String?),
        startsAt: DateTime.parse(json['starts_at'] as String),
        endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at'] as String) : null,
        description: json['description'] as String?,
      );

  PaymentRecord _mapPayment(Map<String, dynamic> json) => PaymentRecord(
        id: json['id'].toString(),
        receiptNumber: json['receipt_number'] as String,
        memberId: json['member_id'].toString(),
        memberName: (json['member_name'] as String?) ?? '',
        amount: json['amount'] as int,
        method: _methodFromApi(json['payment_method'] as String?),
        date: DateTime.parse(json['payment_date'] as String),
        status: _paymentStatus(json['status'] as String?),
        collectorName: json['collector_name'] as String?,
        walletAccount: json['wallet_account'] as String?,
        transactionId: (json['transaction_reference'] as String?) ??
            (json['transaction_id'] as String?),
        rejectionReason: json['rejection_reason'] as String?,
        allocations: ((json['allocations'] as List?) ?? [])
            .map((a) => PaymentAllocation(
                  billingMonth: DateTime.parse(a['billing_month'] as String),
                  amount: a['amount'] as int,
                ))
            .toList(),
      );

  PaymentStatus _paymentStatus(String? value) => switch (value) {
        'pending' => PaymentStatus.pending,
        'rejected' => PaymentStatus.rejected,
        'completed' => PaymentStatus.confirmed,
        _ => PaymentStatus.confirmed,
      };

  EventDonation _mapDonation(Map<String, dynamic> json) => EventDonation(
        id: json['id'].toString(),
        receiptNumber: json['receipt_number'] as String,
        eventId: json['event_id'].toString(),
        eventTitle: (json['event_title'] as String?) ?? '',
        donorType: json['donor_type'] == 'member' ? DonorType.member : DonorType.nonMember,
        donorName: json['donor_name'] as String,
        donorPhone: (json['donor_phone'] as String?) ?? '',
        amount: json['amount'] as int,
        method: _methodFromApi(json['payment_method'] as String?),
        date: DateTime.parse(json['payment_date'] as String),
        referredByName: json['referred_by_name'] as String?,
      );

  String _messageFromDio(DioException e, {String fallback = 'Request failed'}) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first is String && first.isNotEmpty) return first;
      }
    }
    return e.message?.trim().isNotEmpty == true ? e.message! : fallback;
  }

  @override
  Future<AppUser?> login(String phone, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });
      final token = res.data['token'] as String;
      await _storage.write(key: 'auth_token', value: token);
      final u = res.data['user'] as Map<String, dynamic>;
      _user = AppUser(
        id: u['id'].toString(),
        name: u['name'] as String,
        phone: u['phone'] as String,
        role: _role(u['role'] as String?),
        memberId: u['member_id']?.toString(),
      );
      return _user;
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, fallback: 'Unable to login. Try again.'));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _storage.delete(key: 'auth_token');
    _user = null;
  }

  @override
  Future<AppUser?> restoreSession() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      _user = null;
      return null;
    }
    try {
      final res = await _dio.get('/me');
      final u = res.data as Map<String, dynamic>;
      _user = AppUser(
        id: u['id'].toString(),
        name: u['name'] as String,
        phone: u['phone'] as String,
        role: _role(u['role'] as String?),
        memberId: u['member_id']?.toString(),
      );
      return _user;
    } catch (_) {
      await _storage.delete(key: 'auth_token');
      _user = null;
      return null;
    }
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    String? platform,
    String? deviceId,
  }) async {
    await _dio.post('/device-tokens', data: {
      'token': token,
      'platform': ?platform,
      'device_id': ?deviceId,
    });
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    try {
      await _dio.delete('/device-tokens', queryParameters: {'token': token});
    } catch (_) {}
  }

  @override
  Future<DashboardStats> getDashboard() async {
    final res = await _dio.get('/dashboard');
    final d = res.data as Map<String, dynamic>;
    return DashboardStats(
      expected: d['expected'] as int,
      collected: d['collected'] as int,
      totalMembers: d['total_members'] as int,
      paid: d['paid'] as int,
      partial: d['partial'] as int,
      unpaid: d['unpaid'] as int,
      totalInflow: (d['total_inflow'] as int?) ?? 0,
      totalExpenses: (d['total_expenses'] as int?) ?? 0,
      fundsAvailable: (d['funds_available'] as int?) ?? 0,
      pendingPayments: (d['pending_payments'] as int?) ?? 0,
    );
  }

  @override
  Future<List<Member>> getMembers({
    String query = '',
    MemberPaymentStatus? status,
  }) async {
    final res = await _dio.get('/members', queryParameters: {
      if (query.isNotEmpty) 'query': query,
      if (status != null) 'status': status.name,
    });
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(_mapMember).toList();
  }

  @override
  Future<Member?> getMember(String id) async {
    final res = await _dio.get('/members/$id');
    return _mapMember(res.data as Map<String, dynamic>);
  }

  @override
  Future<Member> createMember({
    required String name,
    required String phone,
    required int monthlyAmount,
    String? collectorName,
    String? email,
    DateTime? joinedAt,
  }) async {
    final joined = joinedAt ?? DateTime.now();
    final res = await _dio.post('/members', data: {
      'name': name,
      'phone': phone,
      'monthly_amount': monthlyAmount,
      'joined_at':
          '${joined.year.toString().padLeft(4, '0')}-${joined.month.toString().padLeft(2, '0')}-${joined.day.toString().padLeft(2, '0')}',
      if (collectorName != null && collectorName.isNotEmpty) 'collector_name': collectorName,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    return _mapMember(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<MonthlyDue>> getMemberDues(String memberId) async {
    final res = await _dio.get('/members/$memberId/dues');
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list
        .map(
          (d) => MonthlyDue(
            id: d['id'].toString(),
            memberId: d['member_id'].toString(),
            billingMonth: DateTime.parse(d['billing_month'] as String),
            amountDue: d['amount_due'] as int,
            amountPaid: d['amount_paid'] as int,
            status: _dueStatus(d['status'] as String?),
          ),
        )
        .toList();
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
    final res = await _dio.post('/payments', data: {
      'member_id': int.parse(memberId),
      'amount': amount,
      'payment_method': _methodToApi(method),
      'idempotency_key': _uuid.v4(),
      if (collectorName != null && collectorName.isNotEmpty) 'collector_name': collectorName,
      if (walletAccount != null && walletAccount.isNotEmpty) 'wallet_account': walletAccount,
      if (transactionId != null && transactionId.isNotEmpty) 'transaction_reference': transactionId,
      'allocations': allocations
          .map((a) => {
                'billing_month':
                    '${a.billingMonth.year.toString().padLeft(4, '0')}-${a.billingMonth.month.toString().padLeft(2, '0')}-01',
                'amount': a.amount,
              })
          .toList(),
    });
    return _mapPayment(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<PaymentRecord>> getPayments({PaymentStatus? status}) async {
    final res = await _dio.get('/payments', queryParameters: {
      if (status != null) 'status': status.name,
    });
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(_mapPayment).toList();
  }

  @override
  Future<PaymentRecord> approvePayment(String id) async {
    final res = await _dio.post('/payments/$id/approve');
    return _mapPayment(res.data as Map<String, dynamic>);
  }

  @override
  Future<PaymentRecord> rejectPayment(String id, {String? reason}) async {
    final res = await _dio.post('/payments/$id/reject', data: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return _mapPayment(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<FundraisingEvent>> getEvents({bool activeOnly = false}) async {
    final res = await _dio.get('/events', queryParameters: {
      if (activeOnly) 'active_only': true,
    });
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(_mapEvent).toList();
  }

  @override
  Future<FundraisingEvent> createFundraisingEvent({
    required String title,
    required int goalAmount,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final res = await _dio.post('/events', data: {
      'title': title,
      'goal_amount': goalAmount,
      if (description != null && description.isNotEmpty) 'description': description,
      if (startsAt != null) 'starts_at': startsAt.toIso8601String(),
      if (endsAt != null) 'ends_at': endsAt.toIso8601String(),
    });
    return _mapEvent(res.data as Map<String, dynamic>);
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
    final res = await _dio.post('/events/$eventId/donations', data: {
      'donor_type': donorType == DonorType.member ? 'member' : 'non_member',
      'donor_name': donorName,
      'donor_phone': donorPhone,
      'amount': amount,
      'payment_method': _methodToApi(method),
      if (referredByMemberId != null) 'referred_by_member_id': int.parse(referredByMemberId),
      'idempotency_key': _uuid.v4(),
    });
    return _mapDonation(res.data as Map<String, dynamic>);
  }

  @override
  Future<ReportSummary> getReport() async {
    final res = await _dio.get('/reports/monthly-collection');
    final d = res.data as Map<String, dynamic>;
    return ReportSummary(
      monthLabel: d['month_label'] as String,
      expected: d['expected'] as int,
      collected: d['collected'] as int,
      outstanding: d['outstanding'] as int,
      paidMembers: d['paid_members'] as int,
      partialMembers: d['partial_members'] as int,
      unpaidMembers: d['unpaid_members'] as int,
      advancePaidMembers: d['advance_paid_members'] as int,
    );
  }

  @override
  Future<List<PaymentRecord>> getRecentPayments() async {
    final res = await _dio.get('/payments');
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(_mapPayment).toList();
  }

  @override
  Future<List<Expense>> getExpenses({
    ExpenseRecurrence? recurrence,
    ExpenseHeadKind? kind,
  }) async {
    final res = await _dio.get('/expenses', queryParameters: {
      if (recurrence != null) 'recurrence': recurrence.name,
      if (kind != null) 'kind': kind.apiValue,
    });
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(_mapExpense).toList();
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
    final res = await _dio.post('/expenses', data: {
      'title': title,
      'expense_head_id': int.parse(expenseHeadId),
      'recurrence': recurrence.name,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T').first,
      if (periodMonth != null)
        'period_month':
            '${periodMonth.year.toString().padLeft(4, '0')}-${periodMonth.month.toString().padLeft(2, '0')}-01',
      if (paymentMethod != null) 'payment_method': _methodToApi(paymentMethod),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return _mapExpense(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<SalaryHeadDues>> getSalaryDues({String? expenseHeadId}) async {
    final res = await _dio.get('/expenses/salary-dues', queryParameters: {
      if (expenseHeadId != null) 'expense_head_id': int.parse(expenseHeadId),
    });
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(_mapSalaryHeadDues).toList();
  }

  @override
  Future<List<ExpenseHead>> getExpenseHeads({
    bool activeOnly = true,
    ExpenseHeadKind? kind,
  }) async {
    final res = await _dio.get('/expense-heads', queryParameters: {
      if (activeOnly) 'active_only': true,
      if (kind != null) 'kind': kind.apiValue,
    });
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(_mapExpenseHead).toList();
  }

  @override
  Future<ExpenseHead> createExpenseHead({
    required String name,
    required ExpenseHeadKind kind,
    required ExpenseRecurrence defaultRecurrence,
    String? code,
    bool isActive = true,
  }) async {
    final res = await _dio.post('/expense-heads', data: {
      'name': name,
      if (code != null && code.isNotEmpty) 'code': code,
      'kind': kind.apiValue,
      'default_recurrence': defaultRecurrence.name,
      'is_active': isActive,
    });
    return _mapExpenseHead(res.data as Map<String, dynamic>);
  }

  @override
  Future<ExpenseHead> updateExpenseHead(ExpenseHead head) async {
    final res = await _dio.put('/expense-heads/${head.id}', data: {
      'name': head.name,
      'code': head.code,
      'kind': head.kind.apiValue,
      'default_recurrence': head.defaultRecurrence.name,
      'is_active': head.isActive,
      'sort_order': head.sortOrder,
    });
    return _mapExpenseHead(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteExpenseHead(String id) async {
    await _dio.delete('/expense-heads/$id');
  }

  @override
  Future<List<JoinRequest>> getJoinRequests({JoinRequestStatus? status}) async {
    final res = await _dio.get('/join-requests', queryParameters: {
      if (status != null) 'status': status.name,
    });
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(_mapJoinRequest).toList();
  }

  @override
  Future<JoinRequest> submitJoinRequest({
    required String fullName,
    required String phone,
    String? email,
    String? referralCode,
    int? preferredMonthlyAmount,
  }) async {
    final res = await _dio.post('/join-requests', data: {
      'full_name': fullName,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (referralCode != null && referralCode.isNotEmpty)
        'referral_code': referralCode,
      if (preferredMonthlyAmount != null)
        'preferred_monthly_amount': preferredMonthlyAmount,
    });
    final d = res.data as Map<String, dynamic>;
    return JoinRequest(
      id: d['id'].toString(),
      fullName: fullName,
      phone: phone,
      email: email,
      referralCode: referralCode,
      preferredMonthlyAmount: preferredMonthlyAmount,
      status: JoinRequestStatus.submitted,
      submittedAt: DateTime.now(),
    );
  }

  @override
  Future<JoinRequest> approveJoinRequest(String id) async {
    await _dio.post('/join-requests/$id/approve');
    final list = await getJoinRequests();
    return list.firstWhere((j) => j.id == id);
  }

  @override
  Future<JoinRequest> rejectJoinRequest(String id, {String? reason}) async {
    await _dio.post('/join-requests/$id/reject', data: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    final list = await getJoinRequests();
    return list.firstWhere((j) => j.id == id);
  }

  @override
  Future<OrganizationSettings> getOrganizationSettings() async {
    final res = await _dio.get('/organization-settings');
    return _mapSettings(res.data as Map<String, dynamic>);
  }

  @override
  Future<OrganizationSettings> updateOrganizationSettings(
    OrganizationSettings settings,
  ) async {
    final res = await _dio.put('/organization-settings', data: {
      'organization_name': settings.organizationName,
      'tagline': settings.tagline,
      'contact_phone': settings.contactPhone,
      'address': settings.address,
      'default_monthly_amount': settings.defaultMonthlyAmount,
      'currency_symbol': settings.currencySymbol,
      'referral_enabled': settings.referralEnabled,
      'public_join_enabled': settings.publicJoinEnabled,
    });
    return _mapSettings(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<CommitteeRole>> getCommitteeRoles({bool activeOnly = true}) async {
    final res = await _dio.get('/committee-roles', queryParameters: {
      if (activeOnly) 'active_only': true,
    });
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(_mapCommitteeRole).toList();
  }

  @override
  Future<CommitteeRole> createCommitteeRole({
    required String name,
    String? code,
    bool isActive = true,
  }) async {
    final res = await _dio.post('/committee-roles', data: {
      'name': name,
      if (code != null && code.isNotEmpty) 'code': code,
      'is_active': isActive,
    });
    return _mapCommitteeRole(res.data as Map<String, dynamic>);
  }

  @override
  Future<CommitteeRole> updateCommitteeRole(CommitteeRole role) async {
    final res = await _dio.put('/committee-roles/${role.id}', data: {
      'name': role.name,
      'code': role.code,
      'is_active': role.isActive,
      'sort_order': role.sortOrder,
    });
    return _mapCommitteeRole(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCommitteeRole(String id) async {
    await _dio.delete('/committee-roles/$id');
  }

  @override
  Future<List<CommitteeMember>> getCommitteeMembers({bool activeOnly = true}) async {
    final res = await _dio.get('/committee-members', queryParameters: {
      'active_only': activeOnly,
    });
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(_mapCommitteeMember).toList();
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
    final res = await _dio.post('/committee-members', data: {
      'name': name,
      'committee_role_id': int.parse(roleId),
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (memberId != null && memberId.isNotEmpty) 'member_id': int.parse(memberId),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return _mapCommitteeMember(res.data as Map<String, dynamic>);
  }

  @override
  Future<CommitteeMember> updateCommitteeMember(CommitteeMember member) async {
    final res = await _dio.put('/committee-members/${member.id}', data: {
      'name': member.name,
      'committee_role_id': int.parse(member.roleId),
      'phone': member.phone,
      'email': member.email,
      if (member.memberId != null) 'member_id': int.parse(member.memberId!),
      'notes': member.notes,
      'is_active': member.isActive,
      'sort_order': member.sortOrder,
    });
    return _mapCommitteeMember(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCommitteeMember(String id) async {
    await _dio.delete('/committee-members/$id');
  }

  CommitteeRole _mapCommitteeRole(Map<String, dynamic> json) {
    return CommitteeRole(
      id: json['id'].toString(),
      name: json['name'] as String,
      code: json['code'] as String,
      isActive: json['is_active'] != false,
      sortOrder: (json['sort_order'] as int?) ?? 0,
    );
  }

  CommitteeMember _mapCommitteeMember(Map<String, dynamic> json) {
    return CommitteeMember(
      id: json['id'].toString(),
      name: json['name'] as String,
      roleId: json['committee_role_id'].toString(),
      roleName: (json['role_name'] as String?) ?? '',
      roleCode: json['role_code'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      memberId: json['member_id']?.toString(),
      notes: json['notes'] as String?,
      isActive: json['is_active'] != false,
      sortOrder: (json['sort_order'] as int?) ?? 0,
    );
  }

  JoinRequest _mapJoinRequest(Map<String, dynamic> json) {
    final status = switch (json['status'] as String?) {
      'approved' => JoinRequestStatus.approved,
      'rejected' => JoinRequestStatus.rejected,
      _ => JoinRequestStatus.submitted,
    };
    return JoinRequest(
      id: json['id'].toString(),
      fullName: (json['full_name'] ?? json['fullName']) as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      referralCode: json['referral_code'] as String?,
      preferredMonthlyAmount: json['preferred_monthly_amount'] as int?,
      status: status,
      submittedAt: DateTime.tryParse(
            (json['created_at'] ?? json['submitted_at'] ?? '') as String,
          ) ??
          DateTime.now(),
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  Expense _mapExpense(Map<String, dynamic> json) {
    return Expense(
      id: json['id'].toString(),
      title: json['title'] as String,
      expenseHeadId: (json['expense_head_id'] ?? '').toString(),
      headName: (json['head_name'] as String?) ??
          (json['category'] as String?) ??
          'Expense',
      headKind: ExpenseHeadKindX.fromApi(json['head_kind'] as String?),
      recurrence: (json['recurrence'] as String) == 'monthly'
          ? ExpenseRecurrence.monthly
          : ExpenseRecurrence.occasional,
      amount: json['amount'] as int,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      notes: json['notes'] as String?,
      paymentMethod: json['payment_method'] == null
          ? null
          : _methodFromApi(json['payment_method'] as String),
      periodMonth: json['period_month'] != null
          ? DateTime.tryParse(json['period_month'] as String)
          : null,
    );
  }

  SalaryHeadDues _mapSalaryHeadDues(Map<String, dynamic> json) {
    final periods = ((json['periods'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(
          (p) => SalaryPeriod(
            month: DateTime.parse(p['month'] as String),
            isPaid: p['status'] == 'paid',
            expenseId: p['expense_id']?.toString(),
            amount: p['amount'] as int?,
          ),
        )
        .toList();
    return SalaryHeadDues(
      expenseHeadId: json['expense_head_id'].toString(),
      headName: json['head_name'] as String,
      dueCount: (json['due_count'] as int?) ??
          periods.where((p) => !p.isPaid).length,
      periods: periods,
    );
  }

  ExpenseHead _mapExpenseHead(Map<String, dynamic> json) {
    return ExpenseHead(
      id: json['id'].toString(),
      name: json['name'] as String,
      code: json['code'] as String,
      kind: ExpenseHeadKindX.fromApi(json['kind'] as String?),
      defaultRecurrence: (json['default_recurrence'] as String?) == 'occasional'
          ? ExpenseRecurrence.occasional
          : ExpenseRecurrence.monthly,
      isActive: json['is_active'] != false,
      sortOrder: (json['sort_order'] as int?) ?? 0,
    );
  }

  OrganizationSettings _mapSettings(Map<String, dynamic> json) {
    return OrganizationSettings(
      organizationName: json['organization_name'] as String,
      tagline: (json['tagline'] as String?) ?? '',
      contactPhone: (json['contact_phone'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      defaultMonthlyAmount: json['default_monthly_amount'] as int,
      currencySymbol: (json['currency_symbol'] as String?) ?? '৳',
      referralEnabled: json['referral_enabled'] == true,
      publicJoinEnabled: json['public_join_enabled'] != false,
    );
  }
}
