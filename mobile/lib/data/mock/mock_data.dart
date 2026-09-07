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

  static List<MonthlyDue> duesFor(
    String memberId, {
    Member? member,
    int monthlyAmount = 500,
    MemberPaymentStatus status = MemberPaymentStatus.unpaid,
    int advanceMonths = 0,
  }) {
    final resolved = member ??
        members.cast<Member?>().firstWhere(
              (m) => m?.id == memberId,
              orElse: () => null,
            );
    final amount = resolved?.monthlyAmount ?? monthlyAmount;
    final memberStatus = resolved?.status ?? status;
    final advMonths = resolved?.advanceMonths ?? advanceMonths;

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
        amountPaid: memberStatus == MemberPaymentStatus.paid ? amount : 0,
        status: memberStatus == MemberPaymentStatus.paid
            ? DueStatus.paid
            : DueStatus.unpaid,
      ),
      MonthlyDue(
        id: '$memberId-oct',
        memberId: memberId,
        billingMonth: DateTime(2026, 10, 1),
        amountDue: amount,
        amountPaid: advMonths > 0 ? amount : 0,
        status: advMonths > 0 ? DueStatus.paid : DueStatus.unpaid,
      ),
      MonthlyDue(
        id: '$memberId-nov',
        memberId: memberId,
        billingMonth: DateTime(2026, 11, 1),
        amountDue: amount,
        amountPaid: advMonths > 1 ? amount : 0,
        status: advMonths > 1 ? DueStatus.paid : DueStatus.unpaid,
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
    fundsAvailable: 515500,
    totalInflow: 568000,
    totalExpenses: 52500,
  );

  /// Historical collections + donations baseline (beyond sample payment rows).
  static const totalInflowBaseline = 568000;

  static final expenseHeads = <ExpenseHead>[
    const ExpenseHead(
      id: 'h1',
      name: "Imam's Salary",
      code: 'imam_salary',
      kind: ExpenseHeadKind.salary,
      defaultRecurrence: ExpenseRecurrence.monthly,
      isActive: true,
      sortOrder: 1,
    ),
    const ExpenseHead(
      id: 'h2',
      name: 'Staff Salary',
      code: 'staff_salary',
      kind: ExpenseHeadKind.salary,
      defaultRecurrence: ExpenseRecurrence.monthly,
      isActive: true,
      sortOrder: 2,
    ),
    const ExpenseHead(
      id: 'h3',
      name: 'Festival Bonus (Eid)',
      code: 'festival_bonus_eid',
      kind: ExpenseHeadKind.festivalBonus,
      defaultRecurrence: ExpenseRecurrence.occasional,
      isActive: true,
      sortOrder: 3,
    ),
    const ExpenseHead(
      id: 'h4',
      name: 'Social Curriculum',
      code: 'social_curriculum',
      kind: ExpenseHeadKind.operational,
      defaultRecurrence: ExpenseRecurrence.monthly,
      isActive: true,
      sortOrder: 4,
    ),
    const ExpenseHead(
      id: 'h5',
      name: 'Utilities',
      code: 'utilities',
      kind: ExpenseHeadKind.operational,
      defaultRecurrence: ExpenseRecurrence.monthly,
      isActive: true,
      sortOrder: 5,
    ),
    const ExpenseHead(
      id: 'h6',
      name: 'Maintenance',
      code: 'maintenance',
      kind: ExpenseHeadKind.operational,
      defaultRecurrence: ExpenseRecurrence.occasional,
      isActive: true,
      sortOrder: 6,
    ),
    const ExpenseHead(
      id: 'h7',
      name: 'Charity / Relief',
      code: 'charity',
      kind: ExpenseHeadKind.charity,
      defaultRecurrence: ExpenseRecurrence.occasional,
      isActive: true,
      sortOrder: 7,
    ),
  ];

  static final expenses = <Expense>[
    Expense(
      id: 'x1',
      title: "Imam's Salary — September",
      expenseHeadId: 'h1',
      headName: "Imam's Salary",
      headKind: ExpenseHeadKind.salary,
      recurrence: ExpenseRecurrence.monthly,
      amount: 15000,
      expenseDate: DateTime(2026, 9, 1),
      paymentMethod: PaymentMethod.cashToCollector,
    ),
    Expense(
      id: 'x2',
      title: "Imam's Salary — August",
      expenseHeadId: 'h1',
      headName: "Imam's Salary",
      headKind: ExpenseHeadKind.salary,
      recurrence: ExpenseRecurrence.monthly,
      amount: 15000,
      expenseDate: DateTime(2026, 8, 1),
      paymentMethod: PaymentMethod.cashToCollector,
    ),
    Expense(
      id: 'x7',
      title: 'Eid-ul-Fitr Festival Bonus',
      expenseHeadId: 'h3',
      headName: 'Festival Bonus (Eid)',
      headKind: ExpenseHeadKind.festivalBonus,
      recurrence: ExpenseRecurrence.occasional,
      amount: 10000,
      expenseDate: DateTime(2026, 4, 10),
      notes: 'Imam + helpers',
    ),
    Expense(
      id: 'x3',
      title: 'Weekend Islamic class materials',
      expenseHeadId: 'h4',
      headName: 'Social Curriculum',
      headKind: ExpenseHeadKind.operational,
      recurrence: ExpenseRecurrence.monthly,
      amount: 3500,
      expenseDate: DateTime(2026, 9, 5),
      notes: 'Books and stationery for kids class',
    ),
    Expense(
      id: 'x4',
      title: 'Eid food distribution',
      expenseHeadId: 'h7',
      headName: 'Charity / Relief',
      headKind: ExpenseHeadKind.charity,
      recurrence: ExpenseRecurrence.occasional,
      amount: 12000,
      expenseDate: DateTime(2026, 8, 20),
    ),
    Expense(
      id: 'x5',
      title: 'Mosque cleaning supplies',
      expenseHeadId: 'h6',
      headName: 'Maintenance',
      headKind: ExpenseHeadKind.operational,
      recurrence: ExpenseRecurrence.occasional,
      amount: 2200,
      expenseDate: DateTime(2026, 9, 3),
    ),
    Expense(
      id: 'x6',
      title: 'Electricity bill',
      expenseHeadId: 'h5',
      headName: 'Utilities',
      headKind: ExpenseHeadKind.operational,
      recurrence: ExpenseRecurrence.monthly,
      amount: 4800,
      expenseDate: DateTime(2026, 9, 2),
      paymentMethod: PaymentMethod.mobileWallet,
    ),
  ];

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

  static final joinRequests = <JoinRequest>[
    JoinRequest(
      id: 'j1',
      fullName: 'Imran Hossain',
      phone: '01755556666',
      email: 'imran@example.com',
      referralCode: 'AK-1024',
      preferredMonthlyAmount: 500,
      status: JoinRequestStatus.submitted,
      submittedAt: DateTime(2026, 9, 6, 10, 20),
    ),
    JoinRequest(
      id: 'j2',
      fullName: 'Nusrat Jahan',
      phone: '01877778888',
      preferredMonthlyAmount: 500,
      status: JoinRequestStatus.submitted,
      submittedAt: DateTime(2026, 9, 5, 16, 45),
    ),
    JoinRequest(
      id: 'j3',
      fullName: 'Shahidul Islam',
      phone: '01922223333',
      referralCode: 'RA-1025',
      preferredMonthlyAmount: 1000,
      status: JoinRequestStatus.submitted,
      submittedAt: DateTime(2026, 9, 4, 9, 10),
    ),
    JoinRequest(
      id: 'j4',
      fullName: 'Rasheda Begum',
      phone: '01611112222',
      status: JoinRequestStatus.approved,
      preferredMonthlyAmount: 500,
      submittedAt: DateTime(2026, 9, 1, 11, 0),
    ),
    JoinRequest(
      id: 'j5',
      fullName: 'Kamrul Hasan',
      phone: '01533334444',
      status: JoinRequestStatus.rejected,
      rejectionReason: 'Could not verify phone number',
      submittedAt: DateTime(2026, 8, 28, 14, 30),
    ),
  ];

  static const organizationSettings = OrganizationSettings(
    organizationName: 'IIAS',
    tagline: 'Isapura Islamic United Organization',
    contactPhone: '01911785317',
    address: 'Isapura Molla Bari Jame Masjid, Bakergonj, Barisal',
    defaultMonthlyAmount: 500,
    currencySymbol: '৳',
    referralEnabled: true,
    publicJoinEnabled: true,
  );

  static final committeeRoles = <CommitteeRole>[
    const CommitteeRole(id: 'cr1', name: 'Chairman', code: 'chairman', isActive: true, sortOrder: 1),
    const CommitteeRole(id: 'cr2', name: 'Secretary', code: 'secretary', isActive: true, sortOrder: 2),
    const CommitteeRole(id: 'cr3', name: 'Treasurer', code: 'treasurer', isActive: true, sortOrder: 3),
    const CommitteeRole(id: 'cr4', name: 'Joint Secretary', code: 'joint_secretary', isActive: true, sortOrder: 4),
    const CommitteeRole(id: 'cr5', name: 'Organizing Member', code: 'organizing_member', isActive: true, sortOrder: 5),
  ];

  static final committeeMembers = <CommitteeMember>[
    const CommitteeMember(
      id: 'cm1',
      name: 'Ahmad Rahman',
      roleId: 'cr1',
      roleName: 'Chairman',
      roleCode: 'chairman',
      phone: '01712345678',
      sortOrder: 1,
    ),
    const CommitteeMember(
      id: 'cm2',
      name: 'Rahim Ahmed',
      roleId: 'cr2',
      roleName: 'Secretary',
      roleCode: 'secretary',
      phone: '01933334444',
      memberId: 'm2',
      sortOrder: 2,
    ),
    const CommitteeMember(
      id: 'cm3',
      name: 'Hasan Ali',
      roleId: 'cr3',
      roleName: 'Treasurer',
      roleCode: 'treasurer',
      phone: '01788889999',
      sortOrder: 3,
    ),
  ];
}
