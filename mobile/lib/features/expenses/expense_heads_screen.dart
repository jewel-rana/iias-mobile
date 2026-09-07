import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';

final allExpenseHeadsProvider = FutureProvider((ref) {
  return ref.watch(repositoryProvider).getExpenseHeads(activeOnly: false);
});

class ExpenseHeadsScreen extends ConsumerWidget {
  const ExpenseHeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allExpenseHeadsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Expense Heads')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Head'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (heads) {
          if (heads.isEmpty) {
            return const EmptyState(message: 'No expense heads yet');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allExpenseHeadsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: heads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final head = heads[index];
                return SectionCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              head.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${head.kind.label} · ${head.defaultRecurrence.label}'
                              '${head.isActive ? '' : ' · Inactive'}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _openEditor(context, ref, head: head),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: head.isActive ? 'Deactivate' : 'Delete',
                        onPressed: () => _delete(context, ref, head),
                        icon: Icon(
                          head.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.delete_outline,
                          color: AppColors.unpaid,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ExpenseHead head,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(head.isActive ? 'Deactivate head?' : 'Delete head?'),
        content: Text(
          head.isActive
              ? 'Heads already used by expenses are deactivated instead of deleted.'
              : 'Remove "${head.name}" if unused.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(head.isActive ? 'Deactivate' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(repositoryProvider).deleteExpenseHead(head.id);
      ref.invalidate(allExpenseHeadsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e')),
        );
      }
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    ExpenseHead? head,
  }) async {
    final nameCtrl = TextEditingController(text: head?.name ?? '');
    var kind = head?.kind ?? ExpenseHeadKind.salary;
    var recurrence = head?.defaultRecurrence ?? ExpenseRecurrence.monthly;
    var isActive = head?.isActive ?? true;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    head == null ? 'New expense head' : 'Edit expense head',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: "e.g. Imam's Salary",
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExpenseHeadKind>(
                    value: kind,
                    decoration: const InputDecoration(labelText: 'Kind'),
                    items: ExpenseHeadKind.values
                        .map(
                          (k) => DropdownMenuItem(
                            value: k,
                            child: Text(k.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => kind = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExpenseRecurrence>(
                    value: recurrence,
                    decoration:
                        const InputDecoration(labelText: 'Default type'),
                    items: ExpenseRecurrence.values
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => recurrence = v);
                    },
                  ),
                  if (head != null) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (v) => setModalState(() => isActive = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    label: head == null ? 'Create Head' : 'Save Changes',
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      try {
                        final repo = ref.read(repositoryProvider);
                        if (head == null) {
                          await repo.createExpenseHead(
                            name: nameCtrl.text.trim(),
                            kind: kind,
                            defaultRecurrence: recurrence,
                          );
                        } else {
                          await repo.updateExpenseHead(
                            ExpenseHead(
                              id: head.id,
                              name: nameCtrl.text.trim(),
                              code: head.code,
                              kind: kind,
                              defaultRecurrence: recurrence,
                              isActive: isActive,
                              sortOrder: head.sortOrder,
                            ),
                          );
                        }
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    nameCtrl.dispose();
    if (saved == true) {
      ref.invalidate(allExpenseHeadsProvider);
    }
  }
}
