import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _referral = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _referral.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Organization')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _submitted
            ? Column(
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.mark_email_read_rounded,
                      size: 72, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Application submitted',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'An admin will review your join request in the app. You will be notified after approval.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  AppButton(label: 'Back to Login', onPressed: () => context.go('/login')),
                ],
              )
            : ListView(
                children: [
                  const Text(
                    'Submit a membership application. Admin approval happens in the mobile app — no web panel.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _referral,
                    decoration: const InputDecoration(
                      labelText: 'Referral code (optional)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Submit Application',
                    onPressed: () {
                      if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name and phone are required')),
                        );
                        return;
                      }
                      setState(() => _submitted = true);
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
