import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

final accessRolesProvider = FutureProvider((ref) {
  return ref.watch(repositoryProvider).getAccessRoles(activeOnly: false);
});

class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(accessRolesProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(title: l10n.accessRoles),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-access-roles',
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.newAccessRole),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (roles) {
          if (roles.isEmpty) {
            return EmptyState(message: l10n.noAccessRolesYet);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(accessRolesProvider),
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
                            const SizedBox(height: 4),
                            Text(
                              [
                                role.code,
                                if (role.isSystem) l10n.systemRole,
                                if (!role.isActive) l10n.inactive,
                                l10n.permissionCount(role.permissions.contains('*')
                                    ? AppPermission.groups.values.fold<int>(0, (n, g) => n + g.length)
                                    : role.permissions.length),
                              ].join(' · '),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.edit,
                        onPressed: () => _openEditor(context, ref, role: role),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      if (!role.isSystem)
                        IconButton(
                          tooltip: l10n.delete,
                          onPressed: () => _delete(context, ref, role),
                          icon: const Icon(Icons.delete_outline, color: AppColors.unpaid),
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

  Future<void> _delete(BuildContext context, WidgetRef ref, AccessRole role) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteRoleHint(role.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(repositoryProvider).deleteAccessRole(role.id);
      ref.invalidate(accessRolesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotUpdate(e))),
        );
      }
    }
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {AccessRole? role}) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController(text: role?.name ?? '');
    var isActive = role?.isActive ?? true;
    final selected = {...?role?.permissions};
    if (role?.code == 'admin') {
      selected.add('*');
    }

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
              final adminLocked = role?.code == 'admin';
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      role == null ? l10n.newAccessRole : l10n.editAccessRole,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(labelText: l10n.roleName),
                    ),
                    if (role != null && !role.isSystem) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.active),
                        value: isActive,
                        onChanged: (v) => setModal(() => isActive = v),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(l10n.permissions, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (adminLocked)
                      Text(l10n.adminHasAllPermissions, style: const TextStyle(color: AppColors.textSecondary))
                    else
                      ...AppPermission.groups.entries.map((group) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: Text(
                                l10n.permissionGroup(group.key),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            ...group.value.map((key) {
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                value: selected.contains(key),
                                title: Text(l10n.permissionLabel(key)),
                                onChanged: (v) => setModal(() {
                                  if (v == true) {
                                    selected.add(key);
                                  } else {
                                    selected.remove(key);
                                  }
                                }),
                              );
                            }),
                          ],
                        );
                      }),
                    const SizedBox(height: 16),
                    AppButton(
                      label: role == null ? l10n.createRole : l10n.save,
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        try {
                          if (role == null) {
                            await ref.read(repositoryProvider).createAccessRole(
                                  name: name,
                                  permissions: selected.toList(),
                                  isActive: isActive,
                                );
                          } else {
                            await ref.read(repositoryProvider).updateAccessRole(
                                  AccessRole(
                                    id: role.id,
                                    name: name,
                                    code: role.code,
                                    isSystem: role.isSystem,
                                    isActive: isActive,
                                    sortOrder: role.sortOrder,
                                    permissions: adminLocked ? const ['*'] : selected.toList(),
                                  ),
                                );
                          }
                          if (context.mounted) Navigator.pop(context, true);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.couldNotUpdate(e))),
                            );
                          }
                        }
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
    if (saved == true) {
      ref.invalidate(accessRolesProvider);
    }
  }
}
