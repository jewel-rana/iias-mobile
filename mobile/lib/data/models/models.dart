enum UserRole { admin, collector, member }

enum MemberPaymentStatus { paid, partial, unpaid }

enum DueStatus { unpaid, partial, paid }

enum PaymentMethod { mobileWallet, cashToCollector, handCash }

enum EventStatus { draft, active, paused, closed, archived }

enum DonorType { member, nonMember }

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
    this.collectorName,
  });

  final String id;
  final String receiptNumber;
  final String memberId;
  final String memberName;
  final int amount;
  final PaymentMethod method;
  final DateTime date;
  final List<PaymentAllocation> allocations;
  final String? collectorName;
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

class DashboardStats {
  const DashboardStats({
    required this.expected,
    required this.collected,
    required this.totalMembers,
    required this.paid,
    required this.partial,
    required this.unpaid,
  });

  final int expected;
  final int collected;
  final int totalMembers;
  final int paid;
  final int partial;
  final int unpaid;

  double get rate => expected == 0 ? 0 : collected / expected;
  int get outstanding => (expected - collected).clamp(0, expected);
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
