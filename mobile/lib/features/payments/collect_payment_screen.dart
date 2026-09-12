import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

class CollectPaymentScreen extends ConsumerStatefulWidget {
  const CollectPaymentScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends ConsumerState<CollectPaymentScreen> {
  Member? _member;
  List<Member> _members = [];
  List<MonthlyDue> _dues = [];
  final Set<String> _selectedKeys = {};
  PaymentMethod _method = PaymentMethod.cashToCollector;
  Member? _selectedCollector;
  final _walletAccountCtrl = TextEditingController();
  final _txnIdCtrl = TextEditingController();
  bool _loading = false;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _walletAccountCtrl.dispose();
    _txnIdCtrl.dispose();
    super.dispose();
  }

  String _key(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final repo = ref.read(repositoryProvider);
    final member = await repo.getMember(widget.memberId);
    final dues = await repo.getMemberDues(widget.memberId);
    final members = await repo.getMembers();
    if (!mounted) return;

    Member? defaultCollector;
    if (member != null) {
      try {
        defaultCollector = members.firstWhere(
          (m) => m.name.toLowerCase() == member.collectorName.toLowerCase(),
        );
      } catch (_) {
        defaultCollector = null;
      }
    }

    setState(() {
      _member = member;
      _dues = dues;
      _members = members.where((m) => m.id != widget.memberId).toList();
      _selectedCollector = defaultCollector;
      _selectedKeys.clear();
      _busy = false;
    });
  }

  List<({DateTime month, int amount, bool isAdvance, DueStatus? status})> get _selectableMonths {
    final member = _member;
    if (member == null) return [];

    final items = <({DateTime month, int amount, bool isAdvance, DueStatus? status})>[];
    final now = DateTime(DateTime.now().year, DateTime.now().month, 1);

    final unpaid = _dues.where((d) => !d.isFullyPaid).toList()
      ..sort((a, b) => a.billingMonth.compareTo(b.billingMonth));

    for (final due in unpaid) {
      items.add((
        month: due.billingMonth,
        amount: due.remaining,
        isAdvance: due.billingMonth.isAfter(now),
        status: due.status,
      ));
    }

    final chronological = [..._dues]
      ..sort((a, b) => a.billingMonth.compareTo(b.billingMonth));
    var cursor = chronological.isEmpty
        ? DateTime(now.year, now.month, 1)
        : DateTime(
            chronological.last.billingMonth.year,
            chronological.last.billingMonth.month + 1,
            1,
          );
    var added = 0;
    while (added < 4) {
      final exists = _dues.any(
        (d) =>
            d.billingMonth.year == cursor.year &&
            d.billingMonth.month == cursor.month &&
            d.isFullyPaid,
      );
      final alreadyListed = items.any(
        (i) => i.month.year == cursor.year && i.month.month == cursor.month,
      );
      if (!exists && !alreadyListed) {
        items.add((
          month: cursor,
          amount: member.monthlyAmount,
          isAdvance: cursor.isAfter(now),
          status: null,
        ));
        added++;
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return items;
  }

  List<PaymentAllocation> get _allocations {
    return _selectableMonths
        .where((m) => _selectedKeys.contains(_key(m.month)))
        .map((m) => PaymentAllocation(billingMonth: m.month, amount: m.amount))
        .toList();
  }

  int get _allocatedTotal =>
      _allocations.fold<int>(0, (sum, a) => sum + a.amount);

  void _toggleMonth(String key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  Future<void> _pickCollector() async {
    final selected = await showModalBottomSheet<Member>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _members.where((m) {
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return true;
              return m.name.toLowerCase().contains(q) ||
                  m.memberCode.toLowerCase().contains(q) ||
                  m.phone.contains(q);
            }).toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.7,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Collector',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (v) => setModalState(() => query = v),
                        decoration: const InputDecoration(
                          hintText: 'Search members',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const EmptyState(message: 'No members found')
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final m = filtered[index];
                                return ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(color: AppColors.border),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      m.name.trim().isEmpty
                                          ? '?'
                                          : m.name.trim().characters.first.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    m.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text('${m.memberCode} · ${m.phone}'),
                                  onTap: () => Navigator.pop(context, m),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedCollector = selected);
    }
  }

  Future<void> _confirm() async {
    final member = _member;
    if (member == null) return;

    if (_selectedKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one month to pay')),
      );
      return;
    }

    if (_method == PaymentMethod.mobileWallet) {
      if (_walletAccountCtrl.text.trim().isEmpty || _txnIdCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter wallet account number and transaction ID'),
          ),
        );
        return;
      }
    }

    if (_method == PaymentMethod.cashToCollector && _selectedCollector == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a collector from the members list')),
      );
      return;
    }

    final allocations = _allocations;
    final amount = _allocatedTotal;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected months have no payable amount')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final payment = await ref.read(repositoryProvider).createPayment(
            memberId: member.id,
            amount: amount,
            method: _method,
            allocations: allocations,
            collectorName: _method == PaymentMethod.cashToCollector
                ? _selectedCollector?.name
                : null,
            walletAccount: _method == PaymentMethod.mobileWallet
                ? _walletAccountCtrl.text.trim()
                : null,
            transactionId: _method == PaymentMethod.mobileWallet
                ? _txnIdCtrl.text.trim()
                : null,
          );
      if (!mounted) return;
      context.go('/payment-success', extra: payment);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy || _member == null) {
      return Scaffold(
        appBar: IiasAppBar(title: context.l10n.collectPayment),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final member = _member!;
    final months = _selectableMonths;
    final allocated = _allocatedTotal;
    final isSelfSubmit =
        ref.watch(authStateProvider)?.role == UserRole.member;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(
        title: isSelfSubmit ? context.l10n.submitPayment : context.l10n.collectPayment,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isSelfSubmit) ...[
            SectionCard(
              child: Text(
                'Your payment will stay pending until an admin accepts it. Only accepted payments count toward dues and collections.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                Text(
                  '${member.memberCode} · ৳ ${member.monthlyAmount}/month',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.mobileWallet,
            groupValue: _method,
            title: const Text('Mobile Wallet'),
            onChanged: (v) => setState(() => _method = v!),
          ),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.cashToCollector,
            groupValue: _method,
            title: const Text('Cash to collector'),
            onChanged: (v) => setState(() => _method = v!),
          ),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.handCash,
            groupValue: _method,
            title: const Text('Hand Cash'),
            onChanged: (v) => setState(() => _method = v!),
          ),
          if (_method == PaymentMethod.mobileWallet) ...[
            const SizedBox(height: 8),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mobile Wallet Details',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _walletAccountCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Wallet Account Number',
                      hintText: '01XXXXXXXXX',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _txnIdCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Transaction ID',
                      hintText: 'e.g. TXN123456789',
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_method == PaymentMethod.cashToCollector) ...[
            const SizedBox(height: 8),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collector',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select who received the cash from the members list.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickCollector,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Collector Member',
                        prefixIcon: Icon(Icons.badge_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(
                        _selectedCollector == null
                            ? 'Tap to select collector'
                            : '${_selectedCollector!.name} (${_selectedCollector!.memberCode})',
                        style: TextStyle(
                          color: _selectedCollector == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Months',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose which months to pay. Nothing is selected by default.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (months.isEmpty)
                  const Text(
                    'No payable months available',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  ...months.map((m) {
                    final key = _key(m.month);
                    final selected = _selectedKeys.contains(key);
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: selected,
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('MMMM yyyy').format(m.month),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (m.isAdvance) ...[
                            const StatusBadge.advance(),
                            const SizedBox(width: 8),
                          ] else if (m.status == DueStatus.partial) ...[
                            const StatusBadge.partial(),
                            const SizedBox(width: 8),
                          ] else if (m.status == DueStatus.unpaid) ...[
                            const StatusBadge.unpaid(),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '৳ ${m.amount}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      onChanged: (_) => _toggleMonth(key),
                    );
                  }),
                const Divider(height: 24),
                Row(
                  children: [
                    const Text('Selected months'),
                    const Spacer(),
                    Text(
                      '${_selectedKeys.length}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Payment amount'),
                    const Spacer(),
                    Text(
                      '৳ $allocated',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: allocated > 0 ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: isSelfSubmit ? 'Submit for Approval' : 'Confirm Payment',
            loading: _loading,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }
}
