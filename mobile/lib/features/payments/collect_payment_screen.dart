import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';
import '../members/members_screen.dart';
import 'collection_screen.dart';

class CollectPaymentScreen extends ConsumerStatefulWidget {
  const CollectPaymentScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends ConsumerState<CollectPaymentScreen> {
  static const _lookbackMonths = 36;
  static const _advanceMonths = 4;

  Member? _member;
  List<Member> _members = [];
  List<MonthlyDue> _dues = [];
  final Set<String> _selectedKeys = {};
  PaymentMethod _method = PaymentMethod.cashToCollector;
  Member? _selectedCollector;
  OrganizationWallet? _orgWallet;
  List<OrganizationWallet> _orgWallets = [];
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
    final user = ref.read(authStateProvider);
    final canCollectForOthers = user?.canCollectPayments == true;
    var memberId = widget.memberId;
    if (!canCollectForOthers) {
      final selfId = user?.memberId;
      if (selfId == null || selfId.isEmpty) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      memberId = selfId;
    }

    final repo = ref.read(repositoryProvider);
    final member = await repo.getMember(memberId);
    final dues = await repo.getMemberDues(memberId);
    final members = await repo.getMembers();
    List<OrganizationWallet> wallets = const [];
    try {
      wallets = (await repo.getOrganizationSettings()).wallets;
    } catch (_) {
      wallets = const [];
    }
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
      _members = members.where((m) => m.id != memberId).toList();
      _orgWallets = wallets;
      _orgWallet = wallets.length == 1 ? wallets.first : _orgWallet;
      _walletAccountCtrl.text = member?.phone ?? '';
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
    var cursor = DateTime(now.year, now.month - _lookbackMonths, 1);
    final lastAdvance = DateTime(now.year, now.month + _advanceMonths, 1);

    while (!cursor.isAfter(lastAdvance)) {
      MonthlyDue? due;
      for (final d in _dues) {
        if (d.billingMonth.year == cursor.year && d.billingMonth.month == cursor.month) {
          due = d;
          break;
        }
      }
      if (due == null || !due.isFullyPaid) {
        final amount = due?.remaining ?? member.monthlyAmount;
        if (amount > 0) {
          items.add((
            month: cursor,
            amount: amount,
            isAdvance: cursor.isAfter(now),
            status: due?.status,
          ));
        }
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.l10n.selectCollector,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (v) => setModalState(() => query = v),
                        decoration: InputDecoration(
                          hintText: context.l10n.searchMembersShort,
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? EmptyState(message: context.l10n.noMembersFound)
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
        SnackBar(content: Text(context.l10n.selectAtLeastOneMonth)),
      );
      return;
    }

    if (_method == PaymentMethod.mobileWallet) {
      if (_orgWallet == null ||
          _walletAccountCtrl.text.trim().isEmpty ||
          _txnIdCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _orgWallets.isEmpty ? context.l10n.noOrganizationWallets : context.l10n.enterWalletAndTxn,
            ),
          ),
        );
        return;
      }
    }

    if (_method == PaymentMethod.cashToCollector && _selectedCollector == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectCollectorFromList)),
      );
      return;
    }

    final allocations = _allocations;
    final amount = _allocatedTotal;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noPayableAmount)),
      );
      return;
    }

    final isSelfSubmit = ref.read(authStateProvider)?.canCollectPayments != true;
    if (isSelfSubmit) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.submitPaymentConfirmTitle),
          content: Text(context.l10n.submitPaymentConfirmHint(formatTaka(amount))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.submitForApproval),
            ),
          ],
        ),
      );
      if (ok != true) return;
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
            organizationWalletLabel: _method == PaymentMethod.mobileWallet
                ? _orgWallet?.label
                : null,
            organizationWalletNumber: _method == PaymentMethod.mobileWallet
                ? _orgWallet?.number
                : null,
            transactionId: _method == PaymentMethod.mobileWallet
                ? _txnIdCtrl.text.trim()
                : null,
          );
      if (!mounted) return;
      ref.invalidate(collectionPaymentsProvider);
      ref.invalidate(membersProvider);
      ref.invalidate(dashboardProvider);
      context.go('/payment-success', extra: payment);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.paymentFailed(e))),
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
    final isSelfSubmit = ref.watch(authStateProvider)?.canCollectPayments != true;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

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
                l10n.paymentPendingSelfHint,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
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
                  '${member.memberCode} · ${l10n.monthlySlash('${member.monthlyAmount}')}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w600)),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.mobileWallet,
            groupValue: _method,
            title: Text(l10n.mobileWallet),
            onChanged: (v) => setState(() => _method = v!),
          ),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.cashToCollector,
            groupValue: _method,
            title: Text(l10n.cashToCollector),
            onChanged: (v) => setState(() => _method = v!),
          ),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.handCash,
            groupValue: _method,
            title: Text(l10n.handCash),
            onChanged: (v) => setState(() => _method = v!),
          ),
          if (_method == PaymentMethod.mobileWallet) ...[
            const SizedBox(height: 8),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mobileWalletDetails,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (_orgWallets.isEmpty)
                    Text(
                      l10n.noOrganizationWallets,
                      style: const TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    DropdownButtonFormField<OrganizationWallet>(
                      isExpanded: true,
                      value: _orgWallets.contains(_orgWallet) ? _orgWallet : null,
                      decoration: InputDecoration(
                        labelText: l10n.organizationWalletTo,
                        prefixIcon: const Icon(Icons.account_balance_outlined),
                      ),
                      hint: Text(
                        l10n.selectOrganizationWallet,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      items: _orgWallets
                          .map(
                            (w) => DropdownMenuItem(
                              value: w,
                              child: Text(
                                w.display,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      selectedItemBuilder: (context) => _orgWallets
                          .map(
                            (w) => Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                w.display,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _orgWallet = v),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _walletAccountCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.customerWalletFrom,
                      hintText: '01XXXXXXXXX',
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _txnIdCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.transactionId,
                      hintText: 'e.g. TXN123456789',
                      prefixIcon: const Icon(Icons.tag_rounded),
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
                  Text(
                    l10n.collector,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.selectCollectorHint,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickCollector,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.collectorMember,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(
                        _selectedCollector == null
                            ? l10n.tapToSelectCollector
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
                Text(
                  l10n.selectMonths,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.selectMonthsHint,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (months.isEmpty)
                  Text(
                    l10n.noPayableMonths,
                    style: const TextStyle(color: AppColors.textSecondary),
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
                              DateFormat('MMMM yyyy', locale).format(m.month),
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
                    Text(l10n.selectedMonths),
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
                    Text(l10n.paymentAmount),
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
            label: isSelfSubmit ? l10n.submitForApproval : l10n.confirmPayment,
            loading: _loading,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }
}
