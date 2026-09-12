import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';
import 'members_screen.dart';

final memberDetailProvider =
    FutureProvider.autoDispose.family<({Member? member, List<MonthlyDue> dues}), String>(
  (ref, memberId) async {
    final repo = ref.watch(repositoryProvider);
    final member = await repo.getMember(memberId);
    final dues = await repo.getMemberDues(memberId);
    return (member: member, dues: dues);
  },
);

class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(memberDetailProvider(memberId));
    final user = ref.watch(authStateProvider);
    final canSetRole = user?.can(AppPermission.membersCreate) ?? false;
    final l10n = context.l10n;

    return async.when(
      loading: () => Scaffold(
        appBar: IiasAppBar(title: l10n.memberDetails),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: IiasAppBar(title: l10n.memberDetails),
        body: EmptyState(message: l10n.unableToLoadMember(e)),
      ),
      data: (data) {
        final member = data.member;
        final dues = data.dues;
        if (member == null) {
          return Scaffold(
            appBar: IiasAppBar(title: l10n.memberDetails),
            body: EmptyState(message: l10n.memberNotFound),
          );
        }

        final initial = member.name.trim().isEmpty
            ? '?'
            : member.name.trim().characters.first.toUpperCase();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: IiasAppBar(
            title: l10n.memberDetails,
            actions: [
              if (canSetRole)
                IconButton(
                  tooltip: l10n.editMember,
                  onPressed: () => _editMember(context, ref, member),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: l10n.collectPayment,
                onPressed: () => context.push('/collect/${member.id}'),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            member.memberCode,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            member.phone,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          if (member.roleName != null && member.roleName!.isNotEmpty)
                            InkWell(
                              onTap: canSetRole ? () => _editMember(context, ref, member) : null,
                              child: Text(
                                member.roleName!,
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          else if (canSetRole)
                            TextButton(
                              onPressed: () => _editMember(context, ref, member),
                              child: Text(l10n.loginRole),
                            ),
                          InkWell(
                            onTap: canSetRole ? () => _editMember(context, ref, member) : null,
                            child: Text(
                              l10n.perMonth('${member.monthlyAmount}'),
                              style: TextStyle(
                                color: canSetRole ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (member.email != null && member.email!.isNotEmpty)
                            InkWell(
                              onTap: canSetRole ? () => _editMember(context, ref, member) : null,
                              child: Text(
                                member.email!,
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          else if (canSetRole)
                            TextButton(
                              onPressed: () => _editMember(context, ref, member),
                              child: Text(l10n.addEmail),
                            ),
                          if (member.joinedAt != null)
                            Text(
                              l10n.joinedOn(DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString()).format(member.joinedAt!)),
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SectionCard(
                      child: Column(
                        children: [
                          Text(
                            l10n.totalPaid,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          MoneyText(member.totalPaid),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SectionCard(
                      child: Column(
                        children: [
                          Text(
                            l10n.outstanding,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          MoneyText(member.outstanding, color: AppColors.unpaid),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SectionCard(
                      child: Column(
                        children: [
                          Text(
                            l10n.advance,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          MoneyText(member.advance, color: AppColors.advance),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentDues,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DueStat(
                          label: l10n.paid,
                          value: '${member.paidMonths}',
                          color: AppColors.paid,
                        ),
                        _DueStat(
                          label: l10n.due,
                          value: '${member.dueMonths}',
                          color: AppColors.unpaid,
                        ),
                        _DueStat(
                          label: l10n.advance,
                          value: '${member.advanceMonths}',
                          color: AppColors.advance,
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    ...dues.map((d) {
                      final label = DateFormat('MMM yyyy', Localizations.localeOf(context).toString()).format(d.billingMonth);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(label)),
                            Text('? ${d.amountPaid}/${d.amountDue}'),
                            const SizedBox(width: 8),
                            if (d.status == DueStatus.paid) const StatusBadge.paid(),
                            if (d.status == DueStatus.partial)
                              const StatusBadge.partial(),
                            if (d.status == DueStatus.unpaid)
                              const StatusBadge.unpaid(),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long),
                      title: Text(l10n.paymentHistory),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/members/${member.id}/payments'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.volunteer_activism),
                      title: Text(l10n.donations),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/members/${member.id}/donations'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.share),
                      title: Text(l10n.referralCodeLabel(member.referralCode)),
                      trailing: const Icon(Icons.copy),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.referralReady(member.referralCode),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _DueStat extends StatelessWidget {
  const _DueStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

Future<void> _editMember(BuildContext context, WidgetRef ref, Member member) async {
  final l10n = context.l10n;
  List<AccessRole> roles;
  try {
    roles = await ref.read(repositoryProvider).getAccessRoles();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst(RegExp(r'^Exception: '), ''))),
    );
    return;
  }
  if (!context.mounted || roles.isEmpty) return;
  var selected = roles.any((r) => r.id == member.roleId)
      ? member.roleId
      : roles.where((r) => r.code == 'member').firstOrNull?.id ?? roles.first.id;
  final nameCtrl = TextEditingController(text: member.name);
  final phoneCtrl = TextEditingController(text: member.phone);
  final emailCtrl = TextEditingController(text: member.email ?? '');
  final amountCtrl = TextEditingController(text: '${member.monthlyAmount}');
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setModal) => AlertDialog(
        title: Text(l10n.editMember),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.fullName),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.phoneNumber),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.email),
              ),
              const SizedBox(height: 14),
              InputDecorator(
                decoration: InputDecoration(labelText: l10n.loginRole),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selected,
                    items: roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModal(() => selected = v),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.monthlyDonation,
                  prefixText: '৳  ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    ),
  );
  final name = nameCtrl.text.trim();
  final phone = phoneCtrl.text.trim();
  final email = emailCtrl.text.trim();
  final amount = int.tryParse(amountCtrl.text.trim());
  nameCtrl.dispose();
  phoneCtrl.dispose();
  emailCtrl.dispose();
  amountCtrl.dispose();
  if (saved != true || !context.mounted) return;
  if (name.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.nameRequired)),
    );
    return;
  }
  if (phone.length < 10) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.enterValidPhone)),
    );
    return;
  }
  if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.enterValidEmail)),
    );
    return;
  }
  if (amount == null || amount < 1) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.enterValidAmount)),
    );
    return;
  }
  try {
    await ref.read(repositoryProvider).updateMember(
          id: member.id,
          name: name,
          phone: phone,
          email: email,
          roleId: selected,
          monthlyAmount: amount,
        );
    ref.invalidate(memberDetailProvider(member.id));
    ref.invalidate(membersProvider);
    ref.invalidate(dashboardProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.memberUpdated)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst(RegExp(r'^Exception: '), ''))),
    );
  }
}
