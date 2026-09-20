import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'dashboard.dart';
import 'products.dart';
import 'sales.dart';
import 'customers.dart';
import 'reports.dart';

class AppShell extends StatefulWidget {
  final String? businessId;
  const AppShell({super.key, this.businessId});
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  void goTo(int i) => setState(() => index = i);

  List<Widget> get pages => [
    DashboardPage(businessId: widget.businessId, onNavigate: goTo),
    ProductsPage(businessId: widget.businessId),
    SalesPage(businessId: widget.businessId),
    CustomersPage(businessId: widget.businessId),
    ReportsPage(businessId: widget.businessId),
  ];

  final labels = ['الرئيسية','المنتجات','المبيعات','العملاء','التقارير'];
  final icons = [
    Icons.grid_view_rounded, Icons.inventory_2_rounded, Icons.receipt_long_rounded,
    Icons.people_alt_rounded, Icons.bar_chart_rounded
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: Row(children: [
        if (wide) _sidebar(),
        Expanded(child: SafeArea(child: pages[index])),
      ]),
      bottomNavigationBar: wide ? null : _pillNav(),
    );
  }

  Widget _pillNav() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.text,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(labels.length, (i) {
          final selected = index == i;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => setState(() => index = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 0, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icons[i], size: 22, color: selected ? AppTheme.text : Colors.white70),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Flexible(child: Text(labels[i],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w800, fontSize: 12))),
                  ],
                ]),
              ),
            ),
          );
        }),
      ),
    ),
  );

  Widget _sidebar() => Container(
    width: 235,
    padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
    decoration: BoxDecoration(
      color: AppTheme.panel.withOpacity(.72),
      border: Border(right: BorderSide(color: Colors.black.withOpacity(.06))),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width:42,height:42,
          decoration:BoxDecoration(borderRadius:BorderRadius.circular(13),
            gradient:const LinearGradient(colors:[AppTheme.primary,AppTheme.accent])),
          child:const Icon(Icons.bar_chart_rounded, color: Colors.white)),
        const SizedBox(width:10),
        const Expanded(child: Text('Sales Manager', style: TextStyle(fontWeight: FontWeight.w800))),
      ]),
      const SizedBox(height: 38),
      ...List.generate(labels.length, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: ListTile(
          selected: index == i,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          selectedTileColor: AppTheme.primary.withOpacity(.12),
          leading: Icon(icons[i], color: index == i ? AppTheme.primary : AppTheme.muted),
          title: Text(labels[i], style: TextStyle(
            color: index == i ? AppTheme.text : AppTheme.muted,
            fontWeight: index == i ? FontWeight.w700 : FontWeight.w400)),
          onTap: () => setState(() => index = i),
        ),
      )),
      const Spacer(),
      const Divider(color: Colors.black12),
      ListTile(
        leading: const Icon(Icons.logout_rounded, color: AppTheme.muted),
        title: const Text('تسجيل الخروج', style: TextStyle(color: AppTheme.muted)),
        onTap: () async => SupabaseService.signOut(),
      ),
    ]),
  );
}
