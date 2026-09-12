import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';

class MonthlyMembersScreen extends ConsumerWidget {
  const MonthlyMembersScreen({super.key, required this.filter});

  final String filter;

  MemberPaymentStatus? get _status {
    switch (filter) {
      case 'paid':
        return MemberPaymentStatus.paid;
      case 'partial':
        return MemberPaymentStatus.partial;
      case 'unpaid':
        return MemberPaymentStatus.unpaid;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(repositoryProvider).getMembers(status: _status),
      builder: (context, snapshot) {
        final title = filter[0].toUpperCase() + filter.substring(1);
        return Scaffold(
          appBar: IiasAppBar(title: '$title · September 2026'),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final m = snapshot.data![i];
                    return SectionCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(m.memberCode,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('৳ ${m.monthlyAmount}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          if (m.status == MemberPaymentStatus.paid) const StatusBadge.paid(),
                          if (m.status == MemberPaymentStatus.partial) const StatusBadge.partial(),
                          if (m.status == MemberPaymentStatus.unpaid) const StatusBadge.unpaid(),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
