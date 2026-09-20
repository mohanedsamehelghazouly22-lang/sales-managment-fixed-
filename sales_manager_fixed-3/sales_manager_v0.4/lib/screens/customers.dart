import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/customer_service.dart';

class CustomersPage extends StatefulWidget {
  final String? businessId;
  const CustomersPage({super.key, this.businessId});
  @override State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  Future<void> addCustomer() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('إضافة عميل'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم العميل')),
        const SizedBox(height: 10),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
      ],
    ));
    final n = name.text.trim();
    final p = phone.text.trim();
    name.dispose(); phone.dispose();
    if (ok != true || n.isEmpty || widget.businessId == null) return;
    try {
      await CustomerService.add(businessId: widget.businessId!, name: n, phone: p);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ العميل.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloud = widget.businessId != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('العملاء والحسابات', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
          if (cloud) FilledButton.icon(onPressed: addCustomer, icon: const Icon(Icons.person_add), label: const Text('إضافة عميل')),
        ]),
        const SizedBox(height: 20),
        Expanded(
          child: cloud
            ? StreamBuilder<List<Map<String, dynamic>>>(
                stream: CustomerService.stream(widget.businessId!),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final rows = snap.data ?? [];
                  if (rows.isEmpty) return const Center(child: Text('لا يوجد عملاء بعد.'));
                  return ListView.separated(
                    itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _row(rows[i]),
                  );
                },
              )
            : const Center(child: Text('يجب اختيار نشاط لعرض العملاء.')),
        ),
      ]),
    );
  }

  String _initial(String? name) {
    final n = name?.trim();
    if (n == null || n.isEmpty) return '?';
    return n.substring(0, 1);
  }

  Widget _row(Map<String, dynamic> c) {
    final balance = (c['balance'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card(radius: 17),
      child: Row(children: [
        CircleAvatar(backgroundColor: AppTheme.accent.withOpacity(.18), child: Text(_initial(c['name'] as String?))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${c['name'] ?? 'بدون اسم'}', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('${c['phone'] ?? 'بدون رقم هاتف'}', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        ])),
        Text(
          balance >= 0 ? 'له ${balance.toStringAsFixed(0)} ج' : 'عليه ${(-balance).toStringAsFixed(0)} ج',
          style: TextStyle(color: balance >= 0 ? Colors.green.shade700 : Colors.orangeAccent, fontWeight: FontWeight.w700),
        ),
        IconButton(onPressed: () async {
          try { await CustomerService.delete(c['id'] as String); } catch (_) {}
        }, icon: const Icon(Icons.delete_outline_rounded)),
      ]),
    );
  }
}
