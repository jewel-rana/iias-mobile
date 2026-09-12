enum UserRole { admin, collector, member }

enum MemberPaymentStatus { paid, partial, unpaid }

enum DueStatus { unpaid, partial, paid }

enum PaymentMethod { mobileWallet, cashToCollector, handCash }

enum PaymentStatus { pending, confirmed, rejected }

enum EventStatus { draft, active, paused, closed, archived }

enum DonorType { member, nonMember }

enum ExpenseRecurrence { monthly, occasional }

enum ExpenseHeadKind { salary, festivalBonus, operational, charity, other }

extension ExpenseHeadKindX on ExpenseHeadKind {
  String get label => switch (this) {
        ExpenseHeadKind.salary => 'Salary',
        ExpenseHeadKind.festivalBonus => 'Festival Bonus',
        ExpenseHeadKind.operational => 'Operational',
        ExpenseHeadKind.charity => 'Charity',
        ExpenseHeadKind.other => 'Other',
      };

  String get apiValue => switch (this) {
        ExpenseHeadKind.salary => 'salary',
        ExpenseHeadKind.festivalBonus => 'festival_bonus',
        ExpenseHeadKind.operational => 'operational',
        ExpenseHeadKind.charity => 'charity',
        ExpenseHeadKind.other => 'other',
      };

  static ExpenseHeadKind fromApi(String? value) => switch (value) {
        'salary' => ExpenseHeadKind.salary,
        'festival_bonus' => ExpenseHeadKind.festivalBonus,
        'operational' => ExpenseHeadKind.operational,
        'charity' => ExpenseHeadKind.charity,
        _ => ExpenseHeadKind.other,
      };
}

extension ExpenseRecurrenceX on ExpenseRecurrence {
  String get label => switch (this) {
        ExpenseRecurrence.monthly => 'Monthly',
        ExpenseRecurrence.occasional => 'Occasional',
      };
}

class SalaryPeriod {
  const SalaryPeriod({
    required this.month,
    required this.isPaid,
    this.expenseId,
    this.amount,
  });

  final DateTime month;
  final bool isPaid;
  final String? expenseId;
  final int? amount;
}

class SalaryHeadDues {
  const SalaryHeadDues({
    required this.expenseHeadId,
    required this.headName,
    required this.dueCount,
    required this.periods,
  });

  final String expenseHeadId;
  final String headName;
  final int dueCount;
  final List<SalaryPeriod> periods;
}

class ExpenseHead {
  const ExpenseHead({
    required this.id,
    required this.name,
    required this.code,
    required this.kind,
    required this.defaultRecurrence,
    required this.isActive,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String code;
  final ExpenseHeadKind kind;
  final ExpenseRecurrence defaultRecurrence;
  final bool isActive;
  final int sortOrder;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.memberId,
  });

  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? memberId;
}

class Member {
  const Member({
    required this.id,
    required this.memberCode,
    required this.name,
    required this.phone,
    required this.monthlyAmount,
    required this.collectorName,
    required this.status,
    required this.totalPaid,
    required this.outstanding,
    required this.advance,
    required this.paidMonths,
    required this.dueMonths,
    required this.advanceMonths,
    required this.referralCode,
    this.email,
    this.joinedAt,
  });

  final String id;
  final String memberCode;
  final String name;
  final String phone;
  final int monthlyAmount;
  final String collectorName;
  final MemberPaymentStatus status;
  final int totalPaid;
  final int outstanding;
  final int advance;
  final int paidMonths;
  final int dueMonths;
  final int advanceMonths;
  final String referralCode;
  final String? email;
  final DateTime? joinedAt;
}

class MonthlyDue {
  const MonthlyDue({
    required this.id,
    required this.memberId,
    required this.billingMonth,
    required this.amountDue,
    required this.amountPaid,
    required this.status,
  });

  final String id;
  final String memberId;
  final DateTime billingMonth;
  final int amountDue;
  final int amountPaid;
  final DueStatus status;

  int get remaining => (amountDue - amountPaid).clamp(0, amountDue);
  bool get isFullyPaid => amountPaid >= amountDue;
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.receiptNumber,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.method,
    required this.date,
    required this.allocations,
    this.status = PaymentStatus.confirmed,
    this.collectorName,
    this.walletAccount,
    this.transactionId,
    this.rejectionReason,
  });

  final String id;
  final String receiptNumber;
  final String memberId;
  final String memberName;
  final int amount;
  final PaymentMethod method;
  final DateTime date;
  final List<PaymentAllocation> allocations;
  final PaymentStatus status;
  final String? collectorName;
  final String? walletAccount;
  final String? transactionId;
  final String? rejectionReason;

  bool get isPending => status == PaymentStatus.pending;
  bool get isConfirmed => status == PaymentStatus.confirmed;
}

class PaymentAllocation {
  const PaymentAllocation({
    required this.billingMonth,
    required this.amount,
  });

  final DateTime billingMonth;
  final int amount;
}

class FundraisingEvent {
  const FundraisingEvent({
    required this.id,
    required this.title,
    required this.slug,
    required this.goalAmount,
    required this.raisedAmount,
    required this.donorCount,
    required this.status,
    required this.startsAt,
    this.endsAt,
    this.description,
  });

  final String id;
  final String title;
  final String slug;
  final int goalAmount;
  final int raisedAmount;
  final int donorCount;
  final EventStatus status;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? description;

  double get progress => goalAmount == 0 ? 0 : raisedAmount / goalAmount;
}

class EventDonation {
  const EventDonation({
    required this.id,
    required this.receiptNumber,
    required this.eventId,
    required this.eventTitle,
    required this.donorType,
    required this.donorName,
    required this.donorPhone,
    required this.amount,
    required this.method,
    required this.date,
    this.referredByName,
  });

  final String id;
  final String receiptNumber;
  final String eventId;
  final String eventTitle;
  final DonorType donorType;
  final String donorName;
  final String donorPhone;
  final int amount;
  final PaymentMethod method;
  final DateTime date;
  final String? referredByName;
}

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.expenseHeadId,
    required this.headName,
    required this.headKind,
    required this.recurrence,
    required this.amount,
    required this.expenseDate,
    this.notes,
    this.paymentMethod,
    this.periodMonth,
  });

  final String id;
  final String title;
  final String expenseHeadId;
  final String headName;
  final ExpenseHeadKind headKind;
  final ExpenseRecurrence recurrence;
  final int amount;
  final DateTime expenseDate;
  final String? notes;
  final PaymentMethod? paymentMethod;
  final DateTime? periodMonth;
}

class DashboardStats {
  const DashboardStats({
    required this.expected,
    required this.collected,
    required this.totalMembers,
    required this.paid,
    required this.partial,
    required this.unpaid,
    required this.fundsAvailable,
    this.totalInflow = 0,
    this.totalExpenses = 0,
    this.pendingPayments = 0,
  });

  final int expected;
  final int collected;
  final int totalMembers;
  final int paid;
  final int partial;
  final int unpaid;
  final int fundsAvailable;
  final int totalInflow;
  final int totalExpenses;
  final int pendingPayments;

  double get rate => expected == 0 ? 0 : collected / expected;
  int get outstanding => (expected - collected).clamp(0, expected);
}

enum JoinRequestStatus { submitted, approved, rejected }

class JoinRequest {
  const JoinRequest({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.referralCode,
    this.preferredMonthlyAmount,
    required this.status,
    required this.submittedAt,
    this.rejectionReason,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? referralCode;
  final int? preferredMonthlyAmount;
  final JoinRequestStatus status;
  final DateTime submittedAt;
  final String? rejectionReason;
}

class OrganizationSettings {
  const OrganizationSettings({
    required this.organizationName,
    required this.tagline,
    required this.contactPhone,
    required this.address,
    required this.defaultMonthlyAmount,
    required this.currencySymbol,
    required this.referralEnabled,
    required this.publicJoinEnabled,
  });

  final String organizationName;
  final String tagline;
  final String contactPhone;
  final String address;
  final int defaultMonthlyAmount;
  final String currencySymbol;
  final bool referralEnabled;
  final bool publicJoinEnabled;

  OrganizationSettings copyWith({
    String? organizationName,
    String? tagline,
    String? contactPhone,
    String? address,
    int? defaultMonthlyAmount,
    String? currencySymbol,
    bool? referralEnabled,
    bool? publicJoinEnabled,
  }) {
    return OrganizationSettings(
      organizationName: organizationName ?? this.organizationName,
      tagline: tagline ?? this.tagline,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      defaultMonthlyAmount: defaultMonthlyAmount ?? this.defaultMonthlyAmount,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      referralEnabled: referralEnabled ?? this.referralEnabled,
      publicJoinEnabled: publicJoinEnabled ?? this.publicJoinEnabled,
    );
  }
}

class CommitteeRole {
  const CommitteeRole({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String code;
  final bool isActive;
  final int sortOrder;
}

class CommitteeMember {
  const CommitteeMember({
    required this.id,
    required this.name,
    required this.roleId,
    required this.roleName,
    this.roleCode,
    this.phone,
    this.email,
    this.memberId,
    this.notes,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String roleId;
  final String roleName;
  final String? roleCode;
  final String? phone;
  final String? email;
  final String? memberId;
  final String? notes;
  final bool isActive;
  final int sortOrder;
}

class ReportSummary {
  const ReportSummary({
    required this.monthLabel,
    required this.expected,
    required this.collected,
    required this.outstanding,
    required this.paidMembers,
    required this.partialMembers,
    required this.unpaidMembers,
    required this.advancePaidMembers,
  });

  final String monthLabel;
  final int expected;
  final int collected;
  final int outstanding;
  final int paidMembers;
  final int partialMembers;
  final int unpaidMembers;
  final int advancePaidMembers;

  double get rate => expected == 0 ? 0 : collected / expected;
}
