import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';

final membersFilterProvider = StateProvider<MemberPaymentStatus?>((ref) => null);

/// Loads the full member list once; screens filter locally for search.
final membersProvider = FutureProvider.autoDispose<List<Member>>((ref) async {
  return ref.read(repositoryProvider).getMembers();
});

List<Member> filterMembers(
  List<Member> source, {
  String query = '',
  MemberPaymentStatus? status,
}) {
  final q = query.trim().toLowerCase();
  final qDigits = q.replaceAll(RegExp(r'\D'), '');

  return source.where((m) {
    final matchesStatus = status == null || m.status == status;
    if (!matchesStatus) return false;
    if (q.isEmpty) return true;

    final phoneDigits = m.phone.replaceAll(RegExp(r'\D'), '');
    return m.name.toLowerCase().contains(q) ||
        m.memberCode.toLowerCase().contains(q) ||
        m.phone.toLowerCase().contains(q) ||
        (qDigits.isNotEmpty && phoneDigits.contains(qDigits)) ||
        m.collectorName.toLowerCase().contains(q);
  }).toList();
}

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);
    final filter = ref.watch(membersFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(
        title: 'Members',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Add Member',
            onPressed: () => context.push('/add-member'),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-member'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
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
                hintText: 'Search by name, ID or phone',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
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
                  label: 'All',
                  selected: filter == null,
                  onTap: () => ref.read(membersFilterProvider.notifier).state = null,
                ),
                _FilterPill(
                  label: 'Paid',
                  selected: filter == MemberPaymentStatus.paid,
                  onTap: () => ref.read(membersFilterProvider.notifier).state =
                      MemberPaymentStatus.paid,
                ),
                _FilterPill(
                  label: 'Partial',
                  selected: filter == MemberPaymentStatus.partial,
                  onTap: () => ref.read(membersFilterProvider.notifier).state =
                      MemberPaymentStatus.partial,
                ),
                _FilterPill(
                  label: 'Unpaid',
                  selected: filter == MemberPaymentStatus.unpaid,
                  onTap: () => ref.read(membersFilterProvider.notifier).state =
                      MemberPaymentStatus.unpaid,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Unable to load members.\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Retry',
                        onPressed: () => ref.invalidate(membersProvider),
                      ),
                    ],
                  ),
                ),
              ),
              data: (allMembers) {
                final members = filterMembers(
                  allMembers,
                  query: _query,
                  status: filter,
                );
                if (members.isEmpty) {
                  return EmptyState(
                    message: _query.trim().isEmpty
                        ? 'No members found'
                        : 'No members match "$_query"',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(membersProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: members.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final m = members[index];
                      final initial = m.name.trim().isEmpty
                          ? '?'
                          : m.name.trim().characters.first.toUpperCase();
                      return InkWell(
                        onTap: () => context.push('/members/${m.id}'),
                        borderRadius: BorderRadius.circular(18),
                        child: SectionCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      m.memberCode,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '৳ ${m.monthlyAmount} / month',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Collector: ${m.collectorName}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _badge(m.status),
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

  Widget _badge(MemberPaymentStatus status) {
    switch (status) {
      case MemberPaymentStatus.paid:
        return const StatusBadge.paid();
      case MemberPaymentStatus.partial:
        return const StatusBadge.partial();
      case MemberPaymentStatus.unpaid:
        return const StatusBadge.unpaid();
    }
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
