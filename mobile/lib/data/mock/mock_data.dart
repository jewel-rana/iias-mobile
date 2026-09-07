import '../models/models.dart';

class MockData {
  static final now = DateTime(2026, 9, 7);

  static const admin = AppUser(
    id: 'u1',
    name: 'Ahmad Rahman',
    phone: '01712345678',
    role: UserRole.admin,
  );

  static const memberUser = AppUser(
    id: 'u2',
    name: 'Abdul Karim',
    phone: '01811112222',
    role: UserRole.member,
    memberId: 'm1',
  );

  static final members = <Member>[
    const Member(
      id: 'm1',
      memberCode: 'M-001024',
      name: 'Abdul Karim',
      phone: '01811112222',
      monthlyAmount: 500,
      collectorName: 'Rahim Ahmed',
      status: MemberPaymentStatus.unpaid,
      totalPaid: 5000,
      outstanding: 1000,
      advance: 1000,
      paidMonths: 8,
      dueMonths: 2,
      advanceMonths: 2,
      referralCode: 'AK-1024',
    ),
    const Member(
      id: 'm2',
      memberCode: 'M-001025',
      name: 'Rahim Ahmed',
      phone: '01933334444',
      monthlyAmount: 500,
      collectorName: 'Hasan Ali',
      status: MemberPaymentStatus.paid,
      totalPaid: 6000,
      outstanding: 0,
      advance: 1500,
      paidMonths: 10,
      dueMonths: 0,
      advanceMonths: 3,
      referralCode: 'RA-1025',
    ),
    const Member(
      id: 'm3',
      memberCode: 'M-001026',
      name: 'Fatima Begum',
      phone: '01655556666',
      monthlyAmount: 500,
      collectorName: 'Rahim Ahmed',
      status: MemberPaymentStatus.partial,
      totalPaid: 4300,
      outstanding: 700,
      advance: 0,
      paidMonths: 7,
      dueMonths: 2,
      advanceMonths: 0,
      referralCode: 'FB-1026',
    ),
    const Member(
      id: 'm4',
      memberCode: 'M-001027',
      name: 'Nazmul Hossain',
      phone: '01577778888',
      monthlyAmount: 1000,
      collectorName: 'Hasan Ali',
      status: MemberPaymentStatus.unpaid,
      totalPaid: 3000,
      outstanding: 2000,
      advance: 0,
      paidMonths: 3,
      dueMonths: 2,
      advanceMonths: 0,
      referralCode: 'NH-1027',
    ),
    const Member(
      id: 'm5',
      memberCode: 'M-001028',
      name: 'Salma Akter',
      phone: '01399990000',
      monthlyAmount: 500,
      collectorName: 'Rahim Ahmed',
      status: MemberPaymentStatus.paid,
      totalPaid: 5500,
      outstanding: 0,
      advance: 500,
      paidMonths: 11,
      dueMonths: 0,
      advanceMonths: 1,
      referralCode: 'SA-1028',
    ),
  ];

  static List<MonthlyDue> duesFor(String memberId) {
    final member = members.firstWhere((m) => m.id == memberId);
    final amount = member.monthlyAmount;
    return [
      MonthlyDue(
        id: '$memberId-jul',
        memberId: memberId,
        billingMonth: DateTime(2026, 7, 1),
        amountDue: amount,
        amountPaid: amount,
        status: DueStatus.paid,
      ),
      MonthlyDue(
        id: '$memberId-aug',
        memberId: memberId,
        billingMonth: DateTime(2026, 8, 1),
        amountDue: amount,
        amountPaid: memberId == 'm3' ? 300 : amount,
        status: memberId == 'm3' ? DueStatus.partial : DueStatus.paid,
      ),
      MonthlyDue(
        id: '$memberId-sep',
        memberId: memberId,
        billingMonth: DateTime(2026, 9, 1),
        amountDue: amount,
        amountPaid: member.status == MemberPaymentStatus.paid ? amount : 0,
        status: member.status == MemberPaymentStatus.paid
            ? DueStatus.paid
            : DueStatus.unpaid,
      ),
      MonthlyDue(
        id: '$memberId-oct',
        memberId: memberId,
        billingMonth: DateTime(2026, 10, 1),
        amountDue: amount,
        amountPaid: member.advanceMonths > 0 ? amount : 0,
        status: member.advanceMonths > 0 ? DueStatus.paid : DueStatus.unpaid,
      ),
      MonthlyDue(
        id: '$memberId-nov',
        memberId: memberId,
        billingMonth: DateTime(2026, 11, 1),
        amountDue: amount,
        amountPaid: member.advanceMonths > 1 ? amount : 0,
        status: member.advanceMonths > 1 ? DueStatus.paid : DueStatus.unpaid,
      ),
      MonthlyDue(
        id: '$memberId-dec',
        memberId: memberId,
        billingMonth: DateTime(2026, 12, 1),
        amountDue: amount,
        amountPaid: 0,
        status: DueStatus.unpaid,
      ),
    ];
  }

  static final events = <FundraisingEvent>[
    FundraisingEvent(
      id: 'e1',
      title: 'Flood Relief 2026',
      slug: 'flood-relief-2026',
      goalAmount: 100000,
      raisedAmount: 62400,
      donorCount: 86,
      status: EventStatus.active,
      startsAt: DateTime(2026, 8, 1),
      endsAt: DateTime(2026, 10, 31),
      description: 'Emergency support for flood-affected families.',
    ),
    FundraisingEvent(
      id: 'e2',
      title: 'Winter Relief Drive',
      slug: 'winter-relief-2026',
      goalAmount: 80000,
      raisedAmount: 21500,
      donorCount: 34,
      status: EventStatus.active,
      startsAt: DateTime(2026, 9, 1),
      endsAt: DateTime(2026, 12, 15),
      description: 'Warm clothing and blankets for rural communities.',
    ),
    FundraisingEvent(
      id: 'e3',
      title: 'Mosque Renovation',
      slug: 'mosque-renovation',
      goalAmount: 250000,
      raisedAmount: 250000,
      donorCount: 210,
      status: EventStatus.closed,
      startsAt: DateTime(2026, 1, 1),
      endsAt: DateTime(2026, 6, 30),
    ),
  ];

  static const dashboard = DashboardStats(
    expected: 62500,
    collected: 48500,
    totalMembers: 125,
    paid: 92,
    partial: 13,
    unpaid: 20,
  );

  static const report = ReportSummary(
    monthLabel: 'September 2026',
    expected: 62500,
    collected: 50500,
    outstanding: 12000,
    paidMembers: 92,
    partialMembers: 13,
    unpaidMembers: 20,
    advancePaidMembers: 18,
  );

  static final payments = <PaymentRecord>[
    PaymentRecord(
      id: 'p1',
      receiptNumber: 'P-10025',
      memberId: 'm1',
      memberName: 'Abdul Karim',
      amount: 3000,
      method: PaymentMethod.cashToCollector,
      date: DateTime(2026, 9, 7),
      collectorName: 'Rahim Ahmed',
      allocations: [
        PaymentAllocation(billingMonth: DateTime(2026, 9, 1), amount: 500),
        PaymentAllocation(billingMonth: DateTime(2026, 10, 1), amount: 500),
        PaymentAllocation(billingMonth: DateTime(2026, 11, 1), amount: 500),
        PaymentAllocation(billingMonth: DateTime(2026, 12, 1), amount: 500),
        PaymentAllocation(billingMonth: DateTime(2026, 1, 1), amount: 500),
        PaymentAllocation(billingMonth: DateTime(2026, 2, 1), amount: 500),
      ],
    ),
    PaymentRecord(
      id: 'p2',
      receiptNumber: 'P-10018',
      memberId: 'm2',
      memberName: 'Rahim Ahmed',
      amount: 500,
      method: PaymentMethod.mobileWallet,
      date: DateTime(2026, 9, 5),
      allocations: [
        PaymentAllocation(billingMonth: DateTime(2026, 9, 1), amount: 500),
      ],
    ),
  ];

  static final eventDonations = <EventDonation>[
    EventDonation(
      id: 'd1',
      receiptNumber: 'D-20011',
      eventId: 'e1',
      eventTitle: 'Flood Relief 2026',
      donorType: DonorType.nonMember,
      donorName: 'Karim Hossain',
      donorPhone: '01700001111',
      amount: 2000,
      method: PaymentMethod.mobileWallet,
      date: DateTime(2026, 9, 6),
      referredByName: 'Abdul Karim',
    ),
  ];
}
