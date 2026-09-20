import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/product_service.dart';
import '../services/customer_service.dart';
import '../services/sales_service.dart';

class CartItem {
  final String productId;
  final String name;
  final double unitPrice;
  final double available;
  double quantity;
  CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.available,
    this.quantity = 1,
  });
  double get total => unitPrice * quantity;
}

class SalesPage extends StatefulWidget {
  final String? businessId;
  const SalesPage({super.key, this.businessId});
  @override State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  List<Map<String,dynamic>> products = [];
  List<Map<String,dynamic>> customers = [];
  List<Map<String,dynamic>> recent = [];
  final List<CartItem> cart = [];
  final search = TextEditingController();
  String query = '';
  String? customerId;
  String payment = 'cash';
  double discount = 0;
  double paid = 0;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (widget.businessId == null) {
      setState(() => loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        ProductService.list(widget.businessId!),
        CustomerService.list(widget.businessId!),
        SalesService.recent(widget.businessId!),
      ]);
      products = List<Map<String,dynamic>>.from(results[0] as List);
      customers = List<Map<String,dynamic>>.from(results[1] as List);
      recent = List<Map<String,dynamic>>.from(results[2] as List);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  double get subtotal => cart.fold(0, (a,b) => a + b.total);
  double get total => (subtotal - discount).clamp(0, double.infinity).toDouble();
  double get due => (total - paid).clamp(0, double.infinity).toDouble();

  void addProduct(Map<String,dynamic> p) {
    final stock = (p['stock'] as num?)?.toDouble() ?? 0;
    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المنتج غير متوفر في المخزون.')),
      );
      return;
    }
    final id = p['id'] as String;
    final existing = cart.where((e) => e.productId == id);
    if (existing.isNotEmpty) {
      final item = existing.first;
      if (item.quantity < item.available) {
        setState(() => item.quantity += 1);
      }
      return;
    }
    setState(() => cart.add(CartItem(
      productId: id,
      name: '${p['name']}',
      unitPrice: (p['sale_price'] as num?)?.toDouble() ?? 0,
      available: stock,
    )));
  }

  Future<void> checkout() async {
    if (widget.businessId == null || cart.isEmpty || saving) return;
    if (payment == 'credit' && customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر عميلًا عند البيع الآجل.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final result = await SalesService.createSale(
        businessId: widget.businessId!,
        customerId: customerId,
        items: cart.map((e) => {
          'product_id': e.productId,
          'quantity': e.quantity,
          'unit_price': e.unitPrice,
        }).toList(),
        discount: discount,
        paid: payment == 'credit' ? 0 : paid,
        paymentMethod: payment,
      );
      if (!mounted) return;
      final invoice = result['invoice_number'];
      setState(() {
        cart.clear();
        customerId = null;
        discount = 0;
        paid = 0;
      });
      await load();
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('تمت عملية البيع ✓'),
            content: Text('رقم الفاتورة: #$invoice\nالإجمالي: ${result['total']} ج'),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تم')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حفظ الفاتورة: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.businessId == null) {
      return const Center(child: Text('قم بإعداد النشاط والاتصال بالسحابة أولًا.'));
    }
    if (loading) return const Center(child: CircularProgressIndicator());

    final filtered = products.where((p) {
      final q = query.toLowerCase();
      return '${p['name']}'.toLowerCase().contains(q) ||
          '${p['barcode'] ?? ''}'.toLowerCase().contains(q);
    }).toList();

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 980;
      return Padding(
        padding: const EdgeInsets.all(24),
        child: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(flex: 7, child: _products(filtered)),
              const SizedBox(width: 18),
              SizedBox(width: 390, child: _cart()),
            ])
          : Column(children: [
              Expanded(child: _products(filtered)),
              const SizedBox(height: 14),
              SizedBox(height: 420, child: _cart()),
            ]),
      );
    });
  }

  Widget _products(List<Map<String,dynamic>> list) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('نقطة البيع', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        SizedBox(height: 5),
        Text('ابحث عن المنتج وأضفه للفاتورة', style: TextStyle(color: AppTheme.muted)),
      ])),
      FilledButton.icon(onPressed: () => setState(() => cart.clear()),
        icon: const Icon(Icons.delete_sweep_outlined), label: const Text('تفريغ السلة')),
    ]),
    const SizedBox(height: 16),
    TextField(
      controller: search,
      onChanged: (v) => setState(() => query = v),
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.qr_code_scanner_rounded),
        hintText: 'اسم المنتج أو الباركود...',
      ),
    ),
    const SizedBox(height: 14),
    Expanded(
      child: list.isEmpty
        ? const Center(child: Text('لا توجد منتجات مطابقة.'))
        : LayoutBuilder(builder: (_, gc) => GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gc.maxWidth >= 700 ? 3 : 2,
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 1.65,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final p = list[i];
              final stock = (p['stock'] as num?)?.toDouble() ?? 0;
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => addProduct(p),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: AppTheme.card(radius: 18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.inventory_2_outlined, color: AppTheme.primary),
                    const Spacer(),
                    Text('${p['name']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('${p['sale_price']} ج', style: const TextStyle(fontWeight: FontWeight.w900)),
                      const Spacer(),
                      Text('متاح: $stock', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                    ]),
                  ]),
                ),
              );
            },
          )),
    ),
  ]);

  Widget _cart() => Container(
    padding: const EdgeInsets.all(18),
    decoration: AppTheme.card(radius: 24),
    child: SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('الفاتورة الحالية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
          Text('${cart.length} أصناف', style: const TextStyle(color: AppTheme.muted)),
        ]),
        const SizedBox(height: 12),
        cart.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('السلة فارغة', style: TextStyle(color: AppTheme.muted))),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cart.length,
                separatorBuilder: (_,__) => const Divider(color: Colors.black12),
                itemBuilder: (_, i) {
                  final item = cart[i];
                  return Row(children: [
                    Expanded(child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
                    IconButton(onPressed: () => setState(() {
                      item.quantity = (item.quantity - 1).clamp(1, item.available);
                    }), icon: const Icon(Icons.remove_circle_outline, size: 20)),
                    Text('${item.quantity.toStringAsFixed(0)}'),
                    IconButton(onPressed: () => setState(() {
                      if (item.quantity < item.available) item.quantity += 1;
                    }), icon: const Icon(Icons.add_circle_outline, size: 20)),
                    SizedBox(width: 70, child: Text('${item.total.toStringAsFixed(2)} ج', textAlign: TextAlign.end)),
                  ]);
                },
              ),
            ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: customerId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'العميل (اختياري)'),
          items: [
            const DropdownMenuItem(value: null, child: Text('عميل نقدي')),
            ...customers.map((c) => DropdownMenuItem(
              value: c['id'] as String, child: Text('${c['name']}'))),
          ],
          onChanged: (v) => setState(() => customerId = v),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text('الإجمالي قبل الخصم', style: const TextStyle(color: AppTheme.muted))),
          Text('${subtotal.toStringAsFixed(2)} ج', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('الخصم', style: const TextStyle(color: AppTheme.muted))),
          SizedBox(width: 100, child: TextField(
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => discount = double.tryParse(v) ?? 0),
            decoration: const InputDecoration(hintText: '0', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
          )),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Expanded(child: Text('طريقة الدفع', style: TextStyle(color: AppTheme.muted))),
          DropdownButton<String>(
            value: payment,
            items: const [
              DropdownMenuItem(value:'cash', child: Text('نقدي')),
              DropdownMenuItem(value:'card', child: Text('بطاقة')),
              DropdownMenuItem(value:'transfer', child: Text('تحويل')),
              DropdownMenuItem(value:'credit', child: Text('آجل')),
            ],
            onChanged: (v) => setState(() {
              payment = v ?? 'cash';
              if (payment == 'credit') paid = 0;
            }),
          ),
        ]),
        if (payment != 'credit') ...[
          const SizedBox(height: 6),
          Row(children: [
            const Expanded(child: Text('المدفوع', style: TextStyle(color: AppTheme.muted))),
            SizedBox(width: 120, child: TextField(
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() => paid = double.tryParse(v) ?? 0),
              decoration: const InputDecoration(hintText: '0', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            )),
          ]),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
          ),
          child: Row(children: [
            const Expanded(child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w800))),
            Text('${total.toStringAsFixed(2)} ج', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ]),
        ),
        if (due > 0 && payment != 'credit')
          Padding(padding: const EdgeInsets.only(top: 6), child: Text('متبقي: ${due.toStringAsFixed(2)} ج', style: const TextStyle(color: Colors.orangeAccent))),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(
          onPressed: cart.isEmpty || saving ? null : checkout,
          icon: saving ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.check_circle_outline),
          label: Text(saving ? 'جارٍ حفظ الفاتورة...' : 'تأكيد البيع'),
        )),
      ]),
    ),
  );
}
