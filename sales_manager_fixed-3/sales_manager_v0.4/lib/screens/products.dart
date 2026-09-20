import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/product_service.dart';

class ProductsPage extends StatefulWidget {
  final String? businessId;
  const ProductsPage({super.key, this.businessId});
  @override State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String search = '';
  final demo = const [
    ('iPhone 15','إلكترونيات','39900','25'),
    ('Samsung A55','إلكترونيات','19900','18'),
    ('AirPods Pro','إكسسوارات','9900','12'),
    ('Smart Watch','إكسسوارات','4900','20'),
  ];

  Future<void> addProduct() async {
    final name = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController(text: '0');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('إضافة منتج'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المنتج')),
        const SizedBox(height: 10),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر البيع')),
        const SizedBox(height: 10),
        TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
      ],
    ));
    final n = name.text.trim();
    final p = double.tryParse(price.text) ?? 0;
    final s = double.tryParse(stock.text) ?? 0;
    name.dispose(); price.dispose(); stock.dispose();
    if (ok != true || n.isEmpty || widget.businessId == null) return;
    try {
      await ProductService.upsert(
        businessId: widget.businessId!, name: n, purchasePrice: 0, salePrice: p,
        wholesalePrice: p, stock: s, minimumStock: 0, unit: 'قطعة',
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ المنتج.')),
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
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('المنتجات والمخزون', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            SizedBox(height: 5), Text('إدارة المنتجات والأسعار والكميات', style: TextStyle(color: AppTheme.muted)),
          ])),
          if (cloud) FilledButton.icon(onPressed: addProduct, icon: const Icon(Icons.add), label: const Text('إضافة منتج')),
        ]),
        const SizedBox(height: 20),
        TextField(
          onChanged: (v) => setState(() => search = v.toLowerCase()),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث بالاسم أو الباركود...'),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: cloud
            ? StreamBuilder<List<Map<String,dynamic>>>(
                stream: ProductService.stream(widget.businessId!),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final rows = (snap.data ?? []).where((p) =>
                    (p['name'] ?? '').toString().toLowerCase().contains(search) ||
                    (p['barcode'] ?? '').toString().toLowerCase().contains(search)).toList();
                  if (rows.isEmpty) return const Center(child: Text('لا توجد منتجات بعد.'));
                  return ListView.separated(
                    itemCount: rows.length, separatorBuilder: (_,__) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _row(rows[i]),
                  );
                },
              )
            : ListView.separated(
                itemCount: demo.length, separatorBuilder: (_,__) => const SizedBox(height: 8),
                itemBuilder: (_,i) => _demoRow(demo[i]),
              ),
        ),
      ]),
    );
  }

  Widget _row(Map<String,dynamic> p) => Container(
    padding: const EdgeInsets.all(16),
    decoration: AppTheme.card(radius: 17),
    child: Row(children: [
      _icon(), const SizedBox(width:14),
      Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${p['name']}',style:const TextStyle(fontWeight:FontWeight.w800)),
        Text('${p['unit'] ?? 'قطعة'} • ${p['barcode'] ?? 'بدون باركود'}',style:const TextStyle(color:AppTheme.muted,fontSize:12)),
      ])),
      Text('${p['sale_price']} ج',style:const TextStyle(fontWeight:FontWeight.w800)),
      const SizedBox(width:28),
      Text('المخزون: ${p['stock']}',style:const TextStyle(color:AppTheme.muted)),
      IconButton(onPressed:() async {
        try { await ProductService.delete(p['id'] as String); } catch (_) {}
      }, icon: const Icon(Icons.delete_outline_rounded)),
    ]),
  );

  Widget _demoRow((String,String,String,String) p) => Container(
    padding: const EdgeInsets.all(16),
    decoration: AppTheme.card(radius: 17),
    child: Row(children:[
      _icon(),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(p.$1,style:const TextStyle(fontWeight:FontWeight.w800)),Text(p.$2,style:const TextStyle(color:AppTheme.muted,fontSize:12))
      ])),Text('${p.$3} ج',style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(width:28),
      Text('المخزون: ${p.$4}',style:const TextStyle(color:AppTheme.muted))
    ]),
  );

  Widget _icon()=>Container(width:48,height:48,decoration:BoxDecoration(color:AppTheme.panel2,borderRadius:BorderRadius.circular(13)),child:const Icon(Icons.inventory_2_outlined,color:AppTheme.primary));
}
