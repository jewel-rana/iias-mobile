import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import '../members/members_screen.dart';

final collectionFilterProvider = StateProvider<PaymentStatus?>((ref) => null);

final collectionPaymentsProvider = FutureProvider((ref) {
  final status = ref.watch(collectionFilterProvider);
  return ref.watch(repositoryProvider).getPayments(status: status);
});

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PaymentRecord> _filter(List<PaymentRecord> payments) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return payments;
    final qDigits = q.replaceAll(RegExp(r'\D'), '');
    return payments.where((p) {
      return p.memberName.toLowerCase().contains(q) ||
          p.receiptNumber.toLowerCase().contains(q) ||
          p.amount.toString().contains(q) ||
          (qDigits.isNotEmpty && p.amount.toString().contains(qDigits));
    }).toList();
  }

  Widget _badge(PaymentStatus status) => switch (status) {
        PaymentStatus.pending => const StatusBadge.pending(),
        PaymentStatus.rejected => const StatusBadge.rejected(),
        PaymentStatus.confirmed => const StatusBadge.confirmed(),
      };

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(collectionFilterProvider);
    final async = ref.watch(collectionPaymentsProvider);
    final l10n = context.l10n;
    final dateFmt = DateFormat(
      'dd MMM yyyy · hh:mm a',
      Localizations.localeOf(context).toString(),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(
        title: l10n.collection,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: l10n.addPayment,
            onPressed: () => _addPayment(context),
            icon: const Icon(Icons.add_card_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-collection',
        onPressed: () => _addPayment(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.addPayment),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.searchPayments,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.clear,
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterPill(
                  label: l10n.all,
                  selected: filter == null,
                  onTap: () => ref.read(collectionFilterProvider.notifier).state = null,
                ),
                _FilterPill(
                  label: l10n.confirmed,
                  selected: filter == PaymentStatus.confirmed,
                  onTap: () => ref.read(collectionFilterProvider.notifier).state =
                      PaymentStatus.confirmed,
                ),
                _FilterPill(
                  label: l10n.pending,
                  selected: filter == PaymentStatus.pending,
                  onTap: () => ref.read(collectionFilterProvider.notifier).state =
                      PaymentStatus.pending,
                ),
                _FilterPill(
                  label: l10n.rejected,
                  selected: filter == PaymentStatus.rejected,
                  onTap: () => ref.read(collectionFilterProvider.notifier).state =
                      PaymentStatus.rejected,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: l10n.retry,
                        onPressed: () => ref.invalidate(collectionPaymentsProvider),
                      ),
                    ],
                  ),
                ),
              ),
              data: (allPayments) {
                final payments = _filter(allPayments);
                if (payments.isEmpty) {
                  return EmptyState(
                    message: _query.trim().isEmpty
                        ? (allPayments.isEmpty ? l10n.noPaymentsYet : l10n.noPaymentsFilter)
                        : l10n.noPaymentsFilter,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(collectionPaymentsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = payments[index];
                      return SectionCard(
                        padding: const EdgeInsets.all(14),
                        child: InkWell(
                          onTap: () => context.push(
                            '/payment-details/${p.id}',
                            extra: p,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.memberName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  _badge(p.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${p.receiptNumber} · ${l10n.paymentMethodName(p.method)}',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFmt.format(p.date),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              MoneyText(p.amount),
                              if (p.allocations.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ...p.allocations.map(
                                  (a) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      '${DateFormat('MMM yyyy').format(a.billingMonth)} · ৳ ${a.amount}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPayment(BuildContext context) async {
    List<Member> members;
    try {
      members = await ref.read(membersProvider.future);
    } catch (_) {
      members = const [];
    }
    if (!context.mounted) return;
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
            final l10n = context.l10n;
            final filtered = filterMembers(members, query: query);
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
                          l10n.selectMemberForPayment,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (v) => setModalState(() => query = v),
                        decoration: InputDecoration(
                          hintText: l10n.searchMembersShort,
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? EmptyState(message: l10n.noMembersFound)
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final m = filtered[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
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
                                  subtitle: Text(
                                    '${m.memberCode} · ${l10n.perMonth('${m.monthlyAmount}')}',
                                  ),
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
    if (selected == null || !context.mounted) return;
    context.push('/collect/${selected.id}');
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
