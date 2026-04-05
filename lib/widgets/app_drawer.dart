import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/subscription_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _confirmAndUnsubscribe(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsubscribe'),
        content: const Text('আপনি কি সাবস্ক্রিপশন বাতিল করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('হ্যাঁ, বাতিল করুন'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('userPhone') ?? '';
    if (phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('কোনো লগইন করা নম্বর নেই')),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unsubscribing…')));
    }

    try {
      final svc = SubscriptionService();
      final result = await svc.unsubscribe(phone);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? (result.success ? 'বাতিল সফল' : 'বাতিল ব্যর্থ'),
            ),
          ),
        );
      }

      if (result.success) {
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('userPhone');
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ত্রুটি: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1B5E20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Krishi+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text('মেনু', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.red),
              title: const Text(
                'আনসাবস্ক্রাইব করুন',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await _confirmAndUnsubscribe(context);
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text('বন্ধ করুন'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
