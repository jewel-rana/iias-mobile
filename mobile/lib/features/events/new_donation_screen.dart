import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

class NewDonationScreen extends ConsumerStatefulWidget {
  const NewDonationScreen({super.key, this.eventId, this.memberId});

  final String? eventId;
  final String? memberId;

  @override
  ConsumerState<NewDonationScreen> createState() => _NewDonationScreenState();
}

class _NewDonationScreenState extends ConsumerState<NewDonationScreen> {
  DonorType _donorType = DonorType.member;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _amount = TextEditingController(text: '1000');
  PaymentMethod _method = PaymentMethod.mobileWallet;
  String? _eventId;
  String? _referrerId;
  List<FundraisingEvent> _events = [];
  List<Member> _members = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _eventId = widget.eventId;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(repositoryProvider);
    final events = await repo.getEvents(activeOnly: true);
    final members = await repo.getMembers();
    Member? prefill;
    final memberId = widget.memberId;
    if (memberId != null && memberId.isNotEmpty) {
      prefill = members.where((m) => m.id == memberId).firstOrNull;
      if (prefill == null) {
        try {
          prefill = await repo.getMember(memberId);
        } catch (_) {}
      }
    }
    setState(() {
      _events = events;
      _members = members;
      _eventId ??= events.isNotEmpty ? events.first.id : null;
      if (prefill != null) {
        _donorType = DonorType.member;
        _name.text = prefill.name;
        _phone.text = prefill.phone;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amount.text) ?? 0;
    if (_eventId == null || amount <= 0 || _name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.fillDonationFields)),
      );
      return;
    }
    setState(() => _loading = true);
    final donation = await ref.read(repositoryProvider).createEventDonation(
          eventId: _eventId!,
          donorType: _donorType,
          donorName: _name.text.trim(),
          donorPhone: _phone.text.trim(),
          amount: amount,
          method: _method,
          referredByMemberId: _donorType == DonorType.nonMember ? _referrerId : null,
          memberId: _donorType == DonorType.member
              ? (widget.memberId ??
                  _members.where((m) => m.phone == _phone.text.trim()).firstOrNull?.id)
              : null,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/donation-success', extra: donation);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: IiasAppBar(title: l10n.newDonation),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(l10n.member)),
                    selected: _donorType == DonorType.member,
                    onSelected: (_) => setState(() => _donorType = DonorType.member),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(l10n.nonMember)),
                    selected: _donorType == DonorType.nonMember,
                    onSelected: (_) => setState(() => _donorType = DonorType.nonMember),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: InputDecoration(labelText: l10n.donorName)),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.phone),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _eventId,
            decoration: InputDecoration(labelText: l10n.fundraisingEvent),
            items: _events
                .map((e) => DropdownMenuItem(value: e.id, child: Text(e.title)))
                .toList(),
            onChanged: (v) => setState(() => _eventId = v),
          ),
          if (_donorType == DonorType.nonMember) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _referrerId,
              decoration: InputDecoration(labelText: l10n.referringMember),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.none)),
                ..._members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))),
              ],
              onChanged: (v) => setState(() => _referrerId = v),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.amount, prefixText: '৳  '),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          AppButton(label: l10n.confirmDonation, loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
