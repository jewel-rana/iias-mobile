import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

class NewDonationScreen extends ConsumerStatefulWidget {
  const NewDonationScreen({super.key, this.eventId});

  final String? eventId;

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
    setState(() {
      _events = events;
      _members = members;
      _eventId ??= events.isNotEmpty ? events.first.id : null;
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
        const SnackBar(content: Text('Please fill donor name, event and amount')),
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
        );
    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/donation-success', extra: donation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IiasAppBar(title: context.l10n.newDonation),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Member')),
                    selected: _donorType == DonorType.member,
                    onSelected: (_) => setState(() => _donorType = DonorType.member),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Non-member')),
                    selected: _donorType == DonorType.nonMember,
                    onSelected: (_) => setState(() => _donorType = DonorType.nonMember),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Donor Name')),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _eventId,
            decoration: const InputDecoration(labelText: 'Fundraising Event'),
            items: _events
                .map((e) => DropdownMenuItem(value: e.id, child: Text(e.title)))
                .toList(),
            onChanged: (v) => setState(() => _eventId = v),
          ),
          if (_donorType == DonorType.nonMember) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _referrerId,
              decoration: const InputDecoration(labelText: 'Referring Member (Optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ..._members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))),
              ],
              onChanged: (v) => setState(() => _referrerId = v),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '৳  '),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          AppButton(label: 'Confirm Donation', loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
