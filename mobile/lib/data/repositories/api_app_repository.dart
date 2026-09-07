import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../models/models.dart';
import 'app_repository.dart';

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
        collectorName: json['collector_name'] as String?,
        allocations: ((json['allocations'] as List?) ?? [])
            .map((a) => PaymentAllocation(
                  billingMonth: DateTime.parse(a['billing_month'] as String),
                  amount: a['amount'] as int,
                ))
            .toList(),
      );

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

  @override
  Future<AppUser?> login(String phone, String password) async {
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
  }) async {
    final res = await _dio.post('/members', data: {
      'name': name,
      'phone': phone,
      'monthly_amount': monthlyAmount,
      if (collectorName != null && collectorName.isNotEmpty) 'collector_name': collectorName,
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
  }) async {
    final res = await _dio.post('/payments', data: {
      'member_id': int.parse(memberId),
      'amount': amount,
      'payment_method': _methodToApi(method),
      'idempotency_key': _uuid.v4(),
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
  Future<List<FundraisingEvent>> getEvents({bool activeOnly = false}) async {
    final res = await _dio.get('/events', queryParameters: {
      if (activeOnly) 'active_only': true,
    });
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(_mapEvent).toList();
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
}
