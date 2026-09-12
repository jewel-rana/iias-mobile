import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';

final committeeMembersProvider = FutureProvider((ref) {
  return ref.watch(repositoryProvider).getCommitteeMembers(activeOnly: false);
});

final committeeRolesProvider = FutureProvider((ref) {
  return ref.watch(repositoryProvider).getCommitteeRoles(activeOnly: false);
});

class CommitteeScreen extends ConsumerStatefulWidget {
  const CommitteeScreen({super.key});

  @override
  ConsumerState<CommitteeScreen> createState() => _CommitteeScreenState();
}

class _CommitteeScreenState extends ConsumerState<CommitteeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(
        title: 'Organizing Committee',
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Roles'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabs.index == 0) {
            _editMember(context, ref);
          } else {
            _editRole(context, ref);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabs.index == 0 ? 'Add Member' : 'Add Role'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MembersTab(onEdit: (m) => _editMember(context, ref, member: m)),
          _RolesTab(onEdit: (r) => _editRole(context, ref, role: r)),
        ],
      ),
    );
  }

  Future<void> _editRole(
    BuildContext context,
    WidgetRef ref, {
    CommitteeRole? role,
  }) async {
    final nameCtrl = TextEditingController(text: role?.name ?? '');
    var isActive = role?.isActive ?? true;
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
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role == null ? 'New role' : 'Edit role',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Role name',
                      hintText: 'e.g. Chairman, Secretary',
                    ),
                  ),
                  if (role != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (v) => setModal(() => isActive = v),
                    ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: role == null ? 'Create Role' : 'Save',
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final repo = ref.read(repositoryProvider);
                      if (role == null) {
                        await repo.createCommitteeRole(name: nameCtrl.text.trim());
                      } else {
                        await repo.updateCommitteeRole(
                          CommitteeRole(
                            id: role.id,
                            name: nameCtrl.text.trim(),
                            code: role.code,
                            isActive: isActive,
                            sortOrder: role.sortOrder,
                          ),
                        );
                      }
                      if (context.mounted) Navigator.pop(context, true);
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
    if (saved == true) ref.invalidate(committeeRolesProvider);
  }

  Future<void> _editMember(
    BuildContext context,
    WidgetRef ref, {
    CommitteeMember? member,
  }) async {
    final roles = await ref.read(repositoryProvider).getCommitteeRoles();
    if (!context.mounted) return;
    if (roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a committee role first')),
      );
      _tabs.animateTo(1);
      return;
    }

    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final phoneCtrl = TextEditingController(text: member?.phone ?? '');
    final emailCtrl = TextEditingController(text: member?.email ?? '');
    final notesCtrl = TextEditingController(text: member?.notes ?? '');
    var roleId = member?.roleId ?? roles.first.id;
    var isActive = member?.isActive ?? true;

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
            builder: (context, setModal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member == null ? 'Add committee member' : 'Edit member',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: roleId,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: roles
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModal(() => roleId = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                    ),
                    if (member != null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        value: isActive,
                        onChanged: (v) => setModal(() => isActive = v),
                      ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: member == null ? 'Add to Committee' : 'Save',
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final repo = ref.read(repositoryProvider);
                        final role = roles.firstWhere((r) => r.id == roleId);
                        if (member == null) {
                          await repo.createCommitteeMember(
                            name: nameCtrl.text.trim(),
                            roleId: roleId,
                            phone: phoneCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            notes: notesCtrl.text.trim(),
                          );
                        } else {
                          await repo.updateCommitteeMember(
                            CommitteeMember(
                              id: member.id,
                              name: nameCtrl.text.trim(),
                              roleId: roleId,
                              roleName: role.name,
                              roleCode: role.code,
                              phone: phoneCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              memberId: member.memberId,
                              notes: notesCtrl.text.trim(),
                              isActive: isActive,
                              sortOrder: member.sortOrder,
                            ),
                          );
                        }
                        if (context.mounted) Navigator.pop(context, true);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    notesCtrl.dispose();
    if (saved == true) ref.invalidate(committeeMembersProvider);
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.onEdit});
  final void Function(CommitteeMember member) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(committeeMembersProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (members) {
        if (members.isEmpty) {
          return const EmptyState(message: 'No committee members yet');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(committeeMembersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final m = members[index];
              return SectionCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
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
                            m.roleName + (m.isActive ? '' : ' · Inactive'),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if (m.phone != null && m.phone!.isNotEmpty)
                            Text(
                              m.phone!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onEdit(m),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () async {
                        await ref
                            .read(repositoryProvider)
                            .deleteCommitteeMember(m.id);
                        ref.invalidate(committeeMembersProvider);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
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
    );
  }
}

class _RolesTab extends ConsumerWidget {
  const _RolesTab({required this.onEdit});
  final void Function(CommitteeRole role) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(committeeRolesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (roles) {
        if (roles.isEmpty) {
          return const EmptyState(message: 'No roles yet');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(committeeRolesProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: roles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final role = roles[index];
              return SectionCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            role.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onEdit(role),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () async {
                        await ref
                            .read(repositoryProvider)
                            .deleteCommitteeRole(role.id);
                        ref.invalidate(committeeRolesProvider);
                      },
                      icon: const Icon(
                        Icons.visibility_off_outlined,
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
    );
  }
}
